<?php

namespace App\Filament\Resources\ReturnRequestResource\Pages;

use App\Filament\Resources\ReturnRequestResource;
use Filament\Resources\Pages\ListRecords;

class ListReturnRequests extends ListRecords
{
    protected static string $resource = ReturnRequestResource::class;

    protected function getHeaderActions(): array
    {
        return [
            // Return requests originate from self-service customer portal or in-store cashier
        ];
    }
}
