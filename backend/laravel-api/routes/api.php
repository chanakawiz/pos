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
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/devices/register', [DeviceController::class, 'register']);
    Route::post('/customer/device-token', [\App\Http\Controllers\Api\v1\DeviceTokenController::class, 'store']);
    Route::get('/customer/notifications', [\App\Http\Controllers\Api\v1\NotificationController::class, 'index']);
    Route::post('/customer/notifications/{uuid}/read', [\App\Http\Controllers\Api\v1\NotificationController::class, 'markAsRead']);
    Route::post('/customer/notifications/read-all', [\App\Http\Controllers\Api\v1\NotificationController::class, 'markAllAsRead']);
    Route::get('/sync/status', [SyncController::class, 'status']);

    // Payment Gateway APIs & Webhooks
    Route::post('/payments/initiate', [\App\Http\Controllers\PaymentController::class, 'apiInitiate']);
    Route::post('/payments/webhook/{gateway}', [\App\Http\Controllers\PaymentController::class, 'webhook']);

    // Authenticated POS & Management routes
    Route::middleware('auth:sanctum')->group(function () {
        // Real-Time Reverb WebSocket Channel Auth for Mobile / POS
        Route::post('/broadcasting/auth', [\Illuminate\Broadcasting\BroadcastController::class, 'authenticate']);

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

        // Held Bills (Persistent Multi-Lane)
        Route::get('/held-bills', [\App\Http\Controllers\Api\v1\HeldBillController::class, 'index']);
        Route::post('/held-bills', [\App\Http\Controllers\Api\v1\HeldBillController::class, 'store']);
        Route::delete('/held-bills/{uuid}', [\App\Http\Controllers\Api\v1\HeldBillController::class, 'destroy']);

        // Cash Register Sessions
        Route::post('/cash-sessions/open', [CashSessionController::class, 'open']);
        Route::get('/cash-sessions/current', [CashSessionController::class, 'current']);
        Route::get('/cash-sessions/x-report', [CashSessionController::class, 'xReport']);
        Route::post('/cash-sessions/close', [CashSessionController::class, 'close']);

        // Supply Chain — Suppliers
        Route::get('/suppliers', [\App\Http\Controllers\Api\v1\PurchaseController::class, 'suppliers']);
        Route::post('/suppliers', [\App\Http\Controllers\Api\v1\PurchaseController::class, 'storeSupplier']);

        // Supply Chain — Purchase Orders
        Route::get('/purchases', [\App\Http\Controllers\Api\v1\PurchaseController::class, 'index']);
        Route::post('/purchases', [\App\Http\Controllers\Api\v1\PurchaseController::class, 'store']);
        Route::get('/purchases/{uuid}', [\App\Http\Controllers\Api\v1\PurchaseController::class, 'show']);
        Route::post('/purchases/{uuid}/receive', [\App\Http\Controllers\Api\v1\PurchaseController::class, 'receive']);

        // Analytics & Reporting
        Route::get('/reports/sales-summary', [\App\Http\Controllers\Api\v1\ReportController::class, 'salesSummary']);
        Route::get('/reports/top-products', [\App\Http\Controllers\Api\v1\ReportController::class, 'topProducts']);
        Route::get('/reports/low-stock', [\App\Http\Controllers\Api\v1\ReportController::class, 'lowStock']);

        // Offline Synchronization Engine
        Route::post('/sync/push', [SyncController::class, 'push']);
        Route::get('/sync/pull', [SyncController::class, 'pull']);
    });
});
