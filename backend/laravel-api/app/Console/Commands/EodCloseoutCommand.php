<?php

namespace App\Console\Commands;

use App\Models\Store;
use App\Services\EodCloseoutService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class EodCloseoutCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'pos:eod-closeout 
                            {--store= : Store ID or Store Code to close out}
                            {--force : Force close open registers without confirmation}
                            {--dry-run : Calculate metrics without closing registers}
                            {--notify : Send executive SMS summary to store manager}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Automate End-of-Day (EOD) register closeout, generate consolidated Z-Reports, and dispatch manager SMS digests.';

    public function handle(EodCloseoutService $eodService): int
    {
        $this->info('╔══════════════════════════════════════════════════════════════════╗');
        $this->info('║  OmniLuxe Store — Automated End-of-Day (EOD) Closeout Engine     ║');
        $this->info('╚══════════════════════════════════════════════════════════════════╝');

        $storeIdentifier = $this->option('store');
        $isDryRun = (bool) $this->option('dry-run');
        $force = (bool) $this->option('force');
        $notify = (bool) $this->option('notify');

        $storesQuery = Store::where('is_active', true);
        if ($storeIdentifier) {
            $storesQuery->where(function ($q) use ($storeIdentifier) {
                $q->where('id', $storeIdentifier)->orWhere('code', $storeIdentifier);
            });
        }

        $stores = $storesQuery->get();

        if ($stores->isEmpty()) {
            $this->error('No active stores found matching the criteria.');
            return self::FAILURE;
        }

        foreach ($stores as $store) {
            $this->newLine();
            $this->info("── Auditing Store: [{$store->code}] {$store->name} ──");

            $status = $eodService->getRegisterStatus($store->id);
            $this->line("• Open Registers: <comment>{$status['open_sessions_count']}</comment>");
            $this->line("• Total Cash At Risk: <comment>LKR " . number_format($status['cash_at_risk'], 2) . "</comment>");

            $summary = $eodService->calculateDailySummary($store);

            $this->table(
                ['Metric', 'Value'],
                [
                    ['Total Transactions', $summary['transaction_count']],
                    ['Gross Sales', 'LKR ' . number_format($summary['gross_sales'], 2)],
                    ['Discounts Given', 'LKR ' . number_format($summary['total_discounts'], 2)],
                    ['Cash Tendered', 'LKR ' . number_format($summary['cash_sales'], 2)],
                    ['Card Tendered', 'LKR ' . number_format($summary['card_sales'], 2)],
                    ['Gift Card Tendered', 'LKR ' . number_format($summary['gift_card_sales'], 2)],
                    ['Refunds Processed', 'LKR ' . number_format($summary['total_refunds'], 2)],
                    ['Opening Floats', 'LKR ' . number_format($summary['total_opening_float'], 2)],
                    ['Expected Drawer Cash', 'LKR ' . number_format($summary['expected_cash'], 2)],
                    ['Discrepancy (Variance)', 'LKR ' . number_format($summary['net_discrepancy'], 2)],
                ]
            );

            if ($isDryRun) {
                $this->warn("DRY RUN: No registers were closed and no reports were persisted.");
                continue;
            }

            if ($status['open_sessions_count'] > 0 && !$force && !$this->confirm("Close all {$status['open_sessions_count']} open registers for {$store->name}?", true)) {
                $this->warn("Skipping closeout for {$store->name}.");
                continue;
            }

            $report = $eodService->performCloseout($store, [
                'force' => $force,
                'is_automated' => true,
                'notify_sms' => $notify,
                'notes' => 'Automated nightly EOD closeout generated via pos:eod-closeout command',
            ]);

            $this->info("✔ Successfully reconciled EOD Z-Report #{$report->uuid}");
            $this->info("  Registers Closed: {$report->closed_sessions_count}");
            $this->info("  Report Date: {$report->report_date->toDateString()}");
            if ($notify) {
                $this->info("  Executive SMS alert queued to store manager.");
            }
        }

        $this->newLine();
        $this->info('OmniLuxe EOD Closeout Routine Completed.');
        return self::SUCCESS;
    }
}
