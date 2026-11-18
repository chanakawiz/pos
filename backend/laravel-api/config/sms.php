<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default SMS Driver
    |--------------------------------------------------------------------------
    |
    | Supported: "log", "mock", "notify_lk", "twilio", "dialog_esms"
    |
    */

    'default' => env('SMS_DRIVER', 'log'),

    /*
    |--------------------------------------------------------------------------
    | Default Brand Sender ID & Country Code
    |--------------------------------------------------------------------------
    */

    'default_sender_id' => env('SMS_SENDER_ID', 'OMNILUXE'),
    'default_country' => env('SMS_DEFAULT_COUNTRY', 'LK'),

    /*
    |--------------------------------------------------------------------------
    | Automated Dispatch Triggers
    |--------------------------------------------------------------------------
    */

    'auto_dispatch' => [
        'pos_receipt' => env('SMS_AUTO_DISPATCH_POS', true),
        'web_order' => env('SMS_AUTO_DISPATCH_WEB', true),
        'order_dispatched' => env('SMS_AUTO_DISPATCH_COURIER', true),
        'vip_upgrade' => env('SMS_AUTO_DISPATCH_VIP', true),
    ],

    /*
    |--------------------------------------------------------------------------
    | SMS Gateway Driver Configurations
    |--------------------------------------------------------------------------
    */

    'drivers' => [

        'log' => [
            'channel' => env('SMS_LOG_CHANNEL', null),
        ],

        'mock' => [],

        'notify_lk' => [
            'api_url' => env('NOTIFY_LK_API_URL', 'https://app.notify.lk/api/v1/send'),
            'user_id' => env('NOTIFY_LK_USER_ID', ''),
            'api_key' => env('NOTIFY_LK_API_KEY', ''),
            'sender_id' => env('NOTIFY_LK_SENDER_ID', 'NotifyDEMO'),
        ],

        'twilio' => [
            'sid' => env('TWILIO_SID', ''),
            'token' => env('TWILIO_AUTH_TOKEN', ''),
            'from' => env('TWILIO_FROM_NUMBER', ''),
        ],

        'dialog_esms' => [
            'endpoint' => env('DIALOG_ESMS_ENDPOINT', 'https://e-sms.dialog.lk/api/v1/message/via/json'),
            'username' => env('DIALOG_ESMS_USERNAME', ''),
            'password' => env('DIALOG_ESMS_PASSWORD', ''),
            'source_address' => env('DIALOG_ESMS_SOURCE_ADDRESS', 'OMNILUXE'),
        ],

    ],

];
