<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatus;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index()
    {
        $totalMenus = Menu::count();
        $ordersReceived = Order::count();
        $activeMenus = Menu::where('available', 1)->count();
        $averageRating = \App\Models\Review::avg('rating') ?: 0;
        $totalReviews = \App\Models\Review::count();

        // --- Chart Data & Real Stats from Payment Service ---
        $paymentUrl = env('PAYMENT_SERVICE_URL', 'http://localhost:8001') . '/api/stats/summary';
        $paymentResponse = Http::withHeaders([
            'X-Internal-Secret' => config('services.internal_key')
        ])->get($paymentUrl);

        $stats = $paymentResponse->successful() ? $paymentResponse->json() : [
            'total_revenue' => 0,
            'growth_percent' => 0,
            'monthly_chart' => []
        ];

        $revenueData = collect($stats['monthly_chart']);
        $revenueGrowth = $stats['growth_percent'];

        // 2. Order Status Distribution
        $statusDistribution = Order::select('status_id', DB::raw('count(*) as count'))
            ->groupBy('status_id')
            ->with('status')
            ->get()
            ->map(function($item) {
                return [
                    'label' => $item->status->status_name ?? 'Unknown',
                    'count' => $item->count
                ];
            });

        // 3. Top Selling Menus
        $topMenus = OrderItem::select('menu_id', DB::raw('count(*) as count'))
            ->groupBy('menu_id')
            ->orderBy('count', 'desc')
            ->take(5)
            ->with('menu')
            ->get()
            ->map(function($item) {
                return [
                    'name' => $item->menu->name ?? 'Deleted Menu',
                    'count' => $item->count
                ];
            });

        return view('admin.dashboard', compact(
            'totalMenus', 
            'ordersReceived', 
            'activeMenus', 
            'averageRating', 
            'totalReviews',
            'revenueData',
            'revenueGrowth',
            'statusDistribution',
            'topMenus'
        ));
    }

    public function globalSearch(Request $request)
    {
        $query = $request->get('query');
        if (empty($query)) return response()->json([]);

        // Clean query for Order ID search (Remove ORD- and leading zeros)
        $cleanId = preg_replace('/[^0-9]/', '', ltrim(str_replace('ORD-', '', strtoupper($query)), '0'));

        $menus = Menu::whereRaw('LOWER(name) LIKE ?', ["%".strtolower($query)."%"])
            ->take(5)
            ->get()
            ->map(function($menu) {
                return [
                    'type' => 'MENU',
                    'title' => $menu->name,
                    'url' => route('menus.edit', $menu->menu_id),
                    'icon' => 'fas fa-utensils',
                    'image' => $menu->image ? asset('storage/' . $menu->image) : 'https://ui-avatars.com/api/?name=' . urlencode($menu->name) . '&background=EB4D4B&color=fff'
                ];
            });

        $orders = Order::with(['user', 'status'])
            ->where(function($q) use ($query, $cleanId) {
                $lowQuery = strtolower($query);
                
                // 1. Search by exact or partial ID if cleanId exists
                if (!empty($cleanId)) {
                    $q->where('order_id', $cleanId)
                      ->orWhere('order_id', 'LIKE', "%$cleanId%");
                }

                // 2. Search by User Name
                $q->orWhereHas('user', function($sq) use ($lowQuery) {
                    $sq->whereRaw('LOWER(name) LIKE ?', ["%$lowQuery%"]);
                });

                // 3. Search by Address
                $q->orWhereRaw('LOWER(event_address) LIKE ?', ["%$lowQuery%"]);

                // 4. Search by Status Name
                $q->orWhereHas('status', function($sq) use ($lowQuery) {
                    $sq->whereRaw('LOWER(status_name) LIKE ?', ["%$lowQuery%"]);
                });
            })
            ->take(5)
            ->get()
            ->map(function($order) {
                $userName = $order->user ? $order->user->name : 'Customer';
                $status = $order->status ? $order->status->status_name : 'Unknown';
                return [
                    'type' => 'ORDER',
                    'title' => 'ORD-' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT) . ' (' . $userName . ')',
                    'subtitle' => $status . ' - ' . \Illuminate\Support\Str::limit($order->event_address, 30),
                    'url' => route('orders.show', $order->order_id),
                    'icon' => 'fas fa-box-open'
                ];
            });

        $reviews = \App\Models\Review::with('user')
            ->whereRaw('LOWER(comment) LIKE ?', ["%$lowQuery%"])
            ->take(5)
            ->get()
            ->map(function($review) {
                return [
                    'type' => 'REVIEW',
                    'title' => 'Review by ' . ($review->user ? $review->user->name : 'Customer'),
                    'subtitle' => $review->rating . ' Stars: ' . \Illuminate\Support\Str::limit($review->comment, 40),
                    'url' => route('admin.reviews.index'),
                    'icon' => 'fas fa-star'
                ];
            });

        return response()->json($menus->merge($orders)->merge($reviews));
    }
}
