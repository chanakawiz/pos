<?php

use App\Http\Controllers\WebStoreController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Store & E-Commerce Customer Front Routes
|--------------------------------------------------------------------------
| Seamlessly integrated with POS inventory, products, and SMS e-receipts.
*/

Route::get('/', [WebStoreController::class, 'index'])->name('store.index');
Route::get('/shop', [WebStoreController::class, 'index'])->name('store.shop');
Route::get('/product/{id}', [WebStoreController::class, 'show'])->name('store.product');
Route::post('/checkout', [WebStoreController::class, 'checkout'])->name('store.checkout');
Route::get('/receipt/{invoice}', [WebStoreController::class, 'receipt'])->name('store.receipt');

// Customer Sign In / Sign Up & Loyalty Membership
Route::get('/login', [WebStoreController::class, 'showLogin'])->name('store.login');
Route::post('/login', [WebStoreController::class, 'login'])->name('store.login.submit');
Route::get('/register', [WebStoreController::class, 'showRegister'])->name('store.register');
Route::post('/register', [WebStoreController::class, 'register'])->name('store.register.submit');
Route::post('/logout', [WebStoreController::class, 'logout'])->name('store.logout');
Route::get('/account', [WebStoreController::class, 'account'])->name('store.account');

// Hosted Online Payment Gateway & Callbacks
Route::get('/checkout/payment/{uuid}', [\App\Http\Controllers\PaymentController::class, 'showCheckout'])->name('store.payment');
Route::post('/checkout/payment/{uuid}/process', [\App\Http\Controllers\PaymentController::class, 'processCard'])->name('store.payment.process');
Route::get('/checkout/payment/{uuid}/success', [\App\Http\Controllers\PaymentController::class, 'success'])->name('store.payment.success');
Route::get('/checkout/payment/{uuid}/cancel', [\App\Http\Controllers\PaymentController::class, 'cancel'])->name('store.payment.cancel');

// Order Tracking & Self-Service Returns Portal
Route::get('/track', [\App\Http\Controllers\OrderTrackingController::class, 'show'])->name('store.track');
Route::get('/track/{invoice}', [\App\Http\Controllers\OrderTrackingController::class, 'show'])->name('store.track.invoice');
Route::post('/track/{invoice}/return', [\App\Http\Controllers\OrderTrackingController::class, 'submitReturn'])->name('store.track.return');

// Production Health Checks & Liveness Probes
Route::get('/health/live', [\App\Http\Controllers\HealthController::class, 'live'])->name('health.live');
Route::get('/health/ready', [\App\Http\Controllers\HealthController::class, 'ready'])->name('health.ready');


