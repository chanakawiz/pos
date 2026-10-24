<?php

use App\Models\Customer;
use App\Models\Store;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Laravel Reverb private channels for OmniLuxe Store.
| Strict persona and role-based authorization to prevent data leaks.
|
*/

// Private channel for a specific customer: private-customer.{uuid}
// Delivered to web store session or mobile app when customer is authenticated.
Broadcast::channel('customer.{uuid}', function ($user, string $uuid) {
    if (! $user) {
        return false;
    }

    // Super admin / manager can inspect
    if (method_exists($user, 'isHeadOffice') && $user->isHeadOffice()) {
        return true;
    }

    // If user has a linked customer profile
    if (isset($user->customerProfile) && $user->customerProfile?->uuid === $uuid) {
        return true;
    }

    // Check direct email match on Customer record
    $customer = Customer::where('uuid', $uuid)->first();
    if ($customer && $customer->user_id === $user->id) {
        return true;
    }

    if ($customer && $customer->email && strtolower($customer->email) === strtolower($user->email)) {
        return true;
    }

    return false;
});

// Internal Operations channel: private-store.{uuid}.operations
// STRICTLY restricted to active staff and store managers. Out-of-bounds for consumers.
Broadcast::channel('store.{uuid}.operations', function ($user, string $uuid) {
    if (! $user) {
        return false;
    }

    if (method_exists($user, 'isStaff') && ! $user->isStaff()) {
        return false;
    }

    // Head office can observe any store
    if (method_exists($user, 'isHeadOffice') && $user->isHeadOffice()) {
        return true;
    }

    // Staff must belong to this specific store
    $store = Store::where('uuid', $uuid)->first();
    return $store && $user->store_id === $store->id;
});
