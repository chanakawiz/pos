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

