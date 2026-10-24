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
