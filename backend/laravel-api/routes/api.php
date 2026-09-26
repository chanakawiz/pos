<?php

use App\Http\Controllers\Api\v1\AuthController;
use App\Http\Controllers\Api\v1\CashSessionController;
use App\Http\Controllers\Api\v1\DeviceController;
use App\Http\Controllers\Api\v1\ProductController;
use App\Http\Controllers\Api\v1\SaleController;
use App\Http\Controllers\Api\v1\SyncController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public routes
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/devices/register', [DeviceController::class, 'register']);
    Route::get('/sync/status', [SyncController::class, 'status']);

    // Authenticated POS & Management routes
    Route::middleware('auth:sanctum')->group(function () {
        // Auth
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Catalog & Products
        Route::get('/products', [ProductController::class, 'index']);
        Route::get('/products/barcode/{barcode}', [ProductController::class, 'byBarcode']);
        Route::get('/categories', [ProductController::class, 'categories']);
        Route::get('/brands', [ProductController::class, 'brands']);

        // Billing & Sales
        Route::post('/sales', [SaleController::class, 'store']);
        Route::get('/sales', [SaleController::class, 'index']);
        Route::get('/sales/{uuid}', [SaleController::class, 'show']);
        Route::post('/sales/{uuid}/refund', [\App\Http\Controllers\Api\v1\RefundController::class, 'store']);
        Route::get('/refunds', [\App\Http\Controllers\Api\v1\RefundController::class, 'index']);
        Route::get('/refunds/{uuid}', [\App\Http\Controllers\Api\v1\RefundController::class, 'show']);

        // Customers & Loyalty
        Route::get('/customers', [\App\Http\Controllers\Api\v1\CustomerController::class, 'index']);
        Route::post('/customers', [\App\Http\Controllers\Api\v1\CustomerController::class, 'store']);
        Route::get('/customers/{uuid}', [\App\Http\Controllers\Api\v1\CustomerController::class, 'show']);
        Route::post('/customers/{uuid}/redeem-loyalty', [\App\Http\Controllers\Api\v1\CustomerController::class, 'redeemLoyalty']);

        // Cash Register Sessions
        Route::post('/cash-sessions/open', [CashSessionController::class, 'open']);
        Route::get('/cash-sessions/current', [CashSessionController::class, 'current']);
        Route::get('/cash-sessions/x-report', [CashSessionController::class, 'xReport']);
        Route::post('/cash-sessions/close', [CashSessionController::class, 'close']);

        // Offline Synchronization Engine
        Route::post('/sync/push', [SyncController::class, 'push']);
        Route::get('/sync/pull', [SyncController::class, 'pull']);
    });
});
