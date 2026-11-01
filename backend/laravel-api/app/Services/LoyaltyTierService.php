<?php

namespace App\Services;

use App\Models\Customer;
use App\Models\Sale;
use Illuminate\Support\Facades\DB;

class LoyaltyTierService
{
    public function __construct(
        protected CustomerNotifier $customerNotifier
    ) {}

    /**
     * Determine VIP loyalty tier based on cumulative spend and point accumulation.
     */
    public function determineTier(float $totalSpend, int $loyaltyPoints): string
    {
        if ($totalSpend >= 250000.00 || $loyaltyPoints >= 2500) {
            return 'black';
        }

        if ($totalSpend >= 100000.00 || $loyaltyPoints >= 1000) {
            return 'gold';
        }

        return 'silver';
    }

    /**
     * Process customer spend upon sale completion, calculate points with tier multiplier,
     * and automatically advance VIP loyalty tier if qualification thresholds are met.
     */
    public function processSaleSpend(Customer $customer, float $saleAmount, ?Sale $sale = null): array
    {
        return DB::transaction(function () use ($customer, $saleAmount, $sale) {
            $lockedCustomer = Customer::where('id', $customer->id)->lockForUpdate()->first();

            $oldTier = $lockedCustomer->vip_tier;
            $multiplier = $lockedCustomer->points_multiplier;

            // 1 point per Rs. 100 spent, scaled by VIP tier multiplier
            $pointsEarned = max(0, (int) floor(($saleAmount / 100.0) * $multiplier));

            $newSpend = round((float) $lockedCustomer->total_spend + $saleAmount, 2);
            $newPoints = $lockedCustomer->loyalty_points + $pointsEarned;

            $newTier = $this->determineTier($newSpend, $newPoints);
            $tierUpgraded = false;

            // Upward progression check
            $tierRanks = ['silver' => 1, 'gold' => 2, 'black' => 3];
            if (($tierRanks[$newTier] ?? 1) > ($tierRanks[$oldTier] ?? 1)) {
                $tierUpgraded = true;
                $lockedCustomer->vip_tier = $newTier;
                $lockedCustomer->tier_updated_at = now();

                // Notify customer via persistent inbox, Reverb WS, and FCM push
                $newTitle = match ($newTier) {
                    'black' => 'Black Diamond',
                    'gold' => 'Gold Elite',
                    default => 'Silver Privilege',
                };
                $discountPercent = match ($newTier) {
                    'black' => '10%',
                    'gold' => '5%',
                    default => '0%',
                };

                $this->customerNotifier->notify(
                    $lockedCustomer,
                    'vip',
                    "VIP Privilege Upgrade: Welcome to {$newTitle}!",
                    "Congratulations! Your shopping has unlocked {$newTitle} tier status with {$discountPercent} automatic boutique discount & {$multiplier}x points multiplier.",
                    [
                        'old_tier' => $oldTier,
                        'new_tier' => $newTier,
                        'tier_title' => $newTitle,
                        'total_spend' => $newSpend,
                        'invoice_number' => $sale?->invoice_number,
                    ]
                );
            }

            $lockedCustomer->total_spend = $newSpend;
            $lockedCustomer->loyalty_points = $newPoints;
            $lockedCustomer->save();

            return [
                'points_earned' => $pointsEarned,
                'points_multiplier' => $multiplier,
                'new_points_total' => $newPoints,
                'old_tier' => $oldTier,
                'new_tier' => $newTier,
                'tier_upgraded' => $tierUpgraded,
                'total_spend' => $newSpend,
            ];
        });
    }

    /**
     * Get tier benefits and privileges metadata.
     */
    public function getTierPerks(string $tier): array
    {
        return match ($tier) {
            'black' => [
                'code' => 'black',
                'title' => 'Black Diamond',
                'min_spend' => 250000.00,
                'discount_percent' => 10.0,
                'points_multiplier' => 2.0,
                'color' => '#181A18',
                'accent' => '#C29B38',
                'perks' => [
                    '10% automatic boutique privilege discount on all catalog lines',
                    '2x accelerated loyalty point accumulation (2 pts / Rs. 100)',
                    'Complimentary express courier delivery nationwide',
                    'Dedicated 24/7 VIP Concierge & personal shopper service',
                    'First-access allocations to luxury seasonal collections',
                ],
            ],
            'gold' => [
                'code' => 'gold',
                'title' => 'Gold Elite',
                'min_spend' => 100000.00,
                'discount_percent' => 5.0,
                'points_multiplier' => 1.5,
                'color' => '#2A362E',
                'accent' => '#D4AF37',
                'perks' => [
                    '5% automatic boutique privilege discount',
                    '1.5x accelerated loyalty points (1.5 pts / Rs. 100)',
                    'Priority courier packaging and fulfillment',
                    'Complimentary returns & concierge exchange approval',
                    'Birthday double points month',
                ],
            ],
            default => [
                'code' => 'silver',
                'title' => 'Silver Privilege',
                'min_spend' => 0.00,
                'discount_percent' => 0.0,
                'points_multiplier' => 1.0,
                'color' => '#F4F2EB',
                'accent' => '#7B846D',
                'perks' => [
                    'Standard loyalty point accumulation (1 pt / Rs. 100)',
                    'Digital SMS & WhatsApp e-receipt archiving',
                    '100 Welcome loyalty points upon enrollment',
                    'Standard 14-day boutique exchange guarantee',
                ],
            ],
        };
    }
}
