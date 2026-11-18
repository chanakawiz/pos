<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Automated Nightly End-of-Day (EOD) Reconciliation & Manager SMS Digest
Schedule::command('pos:eod-closeout --force --notify')
    ->dailyAt('23:59')
    ->name('omniluxe-nightly-eod-closeout')
    ->withoutOverlapping();
