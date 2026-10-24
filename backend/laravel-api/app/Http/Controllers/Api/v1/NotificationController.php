<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\CustomerNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get paginated customer notification inbox with unread count.
     */
    public function index(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);

        if (! $customer) {
            return response()->json([
                'status' => 'success',
                'unread_count' => 0,
                'data' => [],
            ]);
        }

        $type = $request->query('type'); // order, loyalty, promo, system
        $query = $customer->notifications()->latest();

        if (! empty($type) && $type !== 'all') {
            $query->where('type', $type);
        }

        $unreadCount = $customer->notifications()->unread()->count();
        $notifications = $query->take(50)->get();

        return response()->json([
            'status' => 'success',
            'unread_count' => $unreadCount,
            'channel' => 'private-customer.' . $customer->uuid,
            'data' => $notifications->map(fn (CustomerNotification $n) => $n->toClientArray()),
        ]);
    }

    /**
     * Mark a specific notification as read.
     */
    public function markAsRead(Request $request, string $uuid): JsonResponse
    {
        $customer = $this->resolveCustomer($request);

        if (! $customer) {
            return response()->json(['status' => 'error', 'message' => 'Unauthorized'], 401);
        }

        $notification = $customer->notifications()->where('uuid', $uuid)->first();

        if ($notification) {
            $notification->update(['read_at' => now()]);
        }

        $unreadCount = $customer->notifications()->unread()->count();

        return response()->json([
            'status' => 'success',
            'unread_count' => $unreadCount,
        ]);
    }

    /**
     * Mark all notifications as read for this customer.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $customer = $this->resolveCustomer($request);

        if (! $customer) {
            return response()->json(['status' => 'error', 'message' => 'Unauthorized'], 401);
        }

        $customer->notifications()->unread()->update(['read_at' => now()]);

        return response()->json([
            'status' => 'success',
            'unread_count' => 0,
        ]);
    }

    private function resolveCustomer(Request $request): ?Customer
    {
        $user = auth('sanctum')->user();

        if ($user) {
            return $user->customerProfile ?? Customer::where('user_id', $user->id)
                ->orWhere('email', $user->email)
                ->first();
        }

        $customerUuid = $request->header('X-Customer-Uuid') ?? $request->query('customer_uuid');
        if ($customerUuid) {
            return Customer::where('uuid', $customerUuid)->first();
        }

        return null;
    }
}
