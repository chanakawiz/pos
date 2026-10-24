<?php

namespace App\Models;

use App\Traits\HasUuid;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable implements FilamentUser
{
    use HasApiTokens, HasFactory, HasRoles, HasUuid, Notifiable, SoftDeletes;

    protected $fillable = [
        'uuid',
        'store_id',
        'name',
        'email',
        'pin_code_hash',
        'password',
        'role',
        'is_active',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'pin_code_hash',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class, 'cashier_id');
    }

    public function cashSessions(): HasMany
    {
        return $this->hasMany(CashSession::class, 'cashier_id');
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return in_array($this->role, ['super_admin', 'admin', 'manager']) && $this->is_active;
    }

    public function customerProfile(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(Customer::class);
    }

    public function isCustomer(): bool
    {
        return $this->role === 'customer';
    }

    /**
     * Staff = anyone allowed to operate store systems (POS counters, ERP).
     */
    public function isStaff(): bool
    {
        return $this->is_active && in_array($this->role, ['super_admin', 'admin', 'manager', 'cashier'], true);
    }

    public function isHeadOffice(): bool
    {
        return $this->is_active && in_array($this->role, ['super_admin', 'admin'], true);
    }
}
