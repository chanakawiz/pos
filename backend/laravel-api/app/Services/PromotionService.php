<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Promotion;
use App\Models\PromotionRedemption;
use App\Models\Sale;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class PromotionService
{
    protected const TIER_RANK = [
        'silver' => 1,
        'gold' => 2,
        'black' => 3,
    ];

    /**
     * Validate a promo code and compute exact discount for a basket.
     */
    public function validateAndCalculate(string $code, float $subtotal, array $options = []): array
    {
        $cleanCode = strtoupper(trim($code));
        if ($cleanCode === '') {
            return $this->invalid('Promotion code is required.');
        }

        $promotion = Promotion::where('code', $cleanCode)->first();
        if (! $promotion) {
            return $this->invalid("Promotion code '{$cleanCode}' was not found.");
        }

        $now = Carbon::now();
        if (! $promotion->is_active) {
            return $this->invalid("Promotion '{$promotion->code}' is currently paused.");
        }

        if ($promotion->starts_at && $now->lt($promotion->starts_at)) {
            return $this->invalid("Promotion '{$promotion->code}' is not active yet.");
        }

        if ($promotion->ends_at && $now->gt($promotion->ends_at)) {
            return $this->invalid("Promotion '{$promotion->code}' has expired.");
        }

        if ($promotion->max_uses !== null && $promotion->uses_count >= $promotion->max_uses) {
            return $this->invalid("Promotion '{$promotion->code}' has reached its maximum redemptions.");
        }

        // Channel eligibility
        $channel = strtolower((string) ($options['channel'] ?? 'web'));
        $allowed = $promotion->allowed_channels;
        if (is_array($allowed) && ! empty($allowed) && ! in_array('all', $allowed, true) && ! in_array($channel, $allowed, true)) {
            return $this->invalid("Promotion '{$promotion->code}' is not valid on the {$channel} channel.");
        }

        // VIP tier gating
        /** @var Customer|null $customer */
        $customer = $options['customer'] ?? null;
        $customerTier = strtolower((string) ($options['vip_tier'] ?? $customer?->vip_tier ?? 'silver'));
        if (! empty($promotion->vip_tier_required)) {
            $requiredTier = strtolower($promotion->vip_tier_required);
            $requiredRank = self::TIER_RANK[$requiredTier] ?? 1;
            $actualRank = self::TIER_RANK[$customerTier] ?? 1;
            if ($actualRank < $requiredRank) {
                return $this->invalid("Promotion '{$promotion->code}' requires " . ucfirst($requiredTier) . ' VIP tier or higher.');
            }
        }

        // Per-customer redemption limit
        if ($customer && $promotion->max_uses_per_customer !== null) {
            $usedByCustomer = $promotion->redemptions()
                ->where('customer_id', $customer->id)
                ->count();
            if ($usedByCustomer >= $promotion->max_uses_per_customer) {
                return $this->invalid("You have already reached the usage limit for '{$promotion->code}'.");
            }
        }

        // Minimum order threshold
        $minOrder = (float) $promotion->min_order_amount;
        if ($subtotal < $minOrder) {
            return $this->invalid(
                'Minimum order of LKR ' . number_format($minOrder, 2) . " required for '{$promotion->code}'."
            );
        }

        // Compute discount based on campaign type
        $items = $options['items'] ?? [];
        $discountAmount = $this->calculateDiscount($promotion, $subtotal, $items);

        if ($discountAmount <= 0) {
            return $this->invalid("Your cart does not meet the item criteria for '{$promotion->code}'.");
        }

        $finalTotal = round(max(0.00, $subtotal - $discountAmount), 2);

        return [
            'valid' => true,
            'message' => "Applied '{$promotion->name}' ({$promotion->discount_label})",
            'promotion' => $promotion,
            'code' => $promotion->code,
            'name' => $promotion->name,
            'type' => $promotion->type,
            'discount_label' => $promotion->discount_label,
            'discount_amount' => $discountAmount,
            'subtotal' => round($subtotal, 2),
            'final_total' => $finalTotal,
        ];
    }

    /**
     * Atomically record promotion redemption with row-level locking.
     */
    public function redeem(
        string $code,
        float $subtotal,
        ?Sale $sale = null,
        ?Customer $customer = null,
        string $channel = 'web',
        array $items = []
    ): array {
        return DB::transaction(function () use ($code, $subtotal, $sale, $customer, $channel, $items) {
            $cleanCode = strtoupper(trim($code));
            $promotion = Promotion::where('code', $cleanCode)->lockForUpdate()->first();

            if (! $promotion) {
                throw new InvalidArgumentException("Promotion '{$cleanCode}' not found.");
            }

            $check = $this->validateAndCalculate($cleanCode, $subtotal, [
                'channel' => $channel,
                'customer' => $customer,
                'items' => $items,
            ]);

            if (! $check['valid']) {
                throw new InvalidArgumentException($check['message']);
            }

            $promotion->increment('uses_count');

            $redemption = PromotionRedemption::create([
                'promotion_id' => $promotion->id,
                'sale_id' => $sale?->id,
                'customer_id' => $customer?->id,
                'channel' => $channel,
                'code_used' => $promotion->code,
                'discount_amount' => $check['discount_amount'],
                'redeemed_at' => Carbon::now(),
            ]);

            return [
                ...$check,
                'redemption' => $redemption,
            ];
        });
    }

    /**
     * List currently active promotions, optionally filtered by channel.
     */
    public function getActiveCampaigns(?string $channel = null): Collection
    {
        $campaigns = Promotion::live()->orderByDesc('is_auto_apply')->latest()->get();

        if (! $channel) {
            return $campaigns;
        }

        $target = strtolower($channel);

        return $campaigns->filter(function (Promotion $promo) use ($target) {
            $allowed = $promo->allowed_channels;
            if (! is_array($allowed) || empty($allowed)) {
                return true;
            }

            return in_array('all', $allowed, true) || in_array($target, $allowed, true);
        })->values();
    }

    protected function calculateDiscount(Promotion $promotion, float $subtotal, array $items): float
    {
        $eligibleSubtotal = $subtotal;

        // If category scoped and items include category_id, compute category subtotal
        if ($promotion->applicable_category_id && ! empty($items)) {
            $matching = collect($items)->filter(
                fn ($i) => isset($i['category_id']) && (int) $i['category_id'] === (int) $promotion->applicable_category_id
            );
            if ($matching->isNotEmpty()) {
                $eligibleSubtotal = (float) $matching->sum(
                    fn ($i) => ((float) ($i['quantity'] ?? 1)) * ((float) ($i['unit_price'] ?? $i['price'] ?? 0))
                );
            }
        }

        if ($promotion->type === 'percentage') {
            $raw = round($eligibleSubtotal * ((float) $promotion->value / 100.0), 2);
            if ($promotion->max_discount_amount !== null) {
                $raw = min($raw, (float) $promotion->max_discount_amount);
            }

            return round(min($subtotal, $raw), 2);
        }

        if ($promotion->type === 'fixed_amount') {
            return round(min($eligibleSubtotal, (float) $promotion->value), 2);
        }

        if ($promotion->type === 'buy_x_get_y') {
            $buyQty = max(1, (int) ($promotion->buy_quantity ?? 2));
            $getQty = max(1, (int) ($promotion->get_quantity ?? 1));
            $bundleSize = $buyQty + $getQty;

            if (empty($items)) {
                return 0.00;
            }

            $unitPrices = [];
            foreach ($items as $item) {
                if ($promotion->applicable_category_id && isset($item['category_id'])
                    && (int) $item['category_id'] !== (int) $promotion->applicable_category_id) {
                    continue;
                }
                $qty = max(0, (int) floor((float) ($item['quantity'] ?? 1)));
                $price = (float) ($item['unit_price'] ?? $item['price'] ?? 0);
                for ($i = 0; $i < $qty; $i++) {
                    $unitPrices[] = $price;
                }
            }

            if (count($unitPrices) < $bundleSize) {
                return 0.00;
            }

            sort($unitPrices);
            $freeUnits = (int) floor(count($unitPrices) / $bundleSize) * $getQty;
            $discount = array_sum(array_slice($unitPrices, 0, $freeUnits));

            if ($promotion->max_discount_amount !== null) {
                $discount = min($discount, (float) $promotion->max_discount_amount);
            }

            return round(min($subtotal, $discount), 2);
        }

        return 0.00;
    }

    protected function invalid(string $message): array
    {
        return [
            'valid' => false,
            'message' => $message,
            'discount_amount' => 0.00,
        ];
    }
}
