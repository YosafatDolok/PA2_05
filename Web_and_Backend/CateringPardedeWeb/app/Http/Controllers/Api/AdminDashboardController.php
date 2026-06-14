<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderMessage;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AdminDashboardController extends Controller
{
    public function getStats()
    {


        // 2. Total unread messages not sent by the current admin
        $unreadMessages = OrderMessage::where('is_read', false)
            ->where('sender_id', '!=', auth()->id())
            ->count();

        // 3. Orders scheduled for today
        $todayOrders = Order::whereDate('event_date', Carbon::today())
            ->where('status_id', '!=', 9) // 9 is Cancelled
            ->count();

        // 4. Recent Activity (Last 5 notifications)
        $recentActivity = Notification::where('user_id', auth()->id())
            ->latest()
            ->take(5)
            ->get(['title', 'message', 'created_at']);

        return response()->json([
            'unread_messages' => $unreadMessages,
            'today_orders' => $todayOrders,
            'recent_activity' => $recentActivity,
        ]);
    }
}
