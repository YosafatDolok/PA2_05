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
    public function index(Request $request)
    {
        $totalMenus = Menu::count();
        $ordersReceived = Order::count();
        $activeMenus = Menu::where('available', 1)->count();
        $averageRating = \App\Models\Review::avg('rating') ?: 0;
        $totalReviews = \App\Models\Review::count();

        //Data Grafik & Statistik Asli dari Layanan Pembayaran
        $stats = [
            'total_revenue' => 0,
            'growth_percent' => 0,
            'monthly_chart' => []
        ];

        $filter = $request->query('filter', 'monthly');

        try {
            $paymentUrl = env('PAYMENT_SERVICE_URL', 'http://localhost:8001') . '/api/stats/summary?filter=' . $filter;
            $paymentResponse = Http::withHeaders([
                'X-Internal-Secret' => config('services.internal_key')
            ])->timeout(2)->connectTimeout(1)->get($paymentUrl);

            if ($paymentResponse->successful()) {
                $stats = $paymentResponse->json();
            }
        } catch (\Exception $e) {
            // Catat log kesalahan tetapi jangan biarkan aplikasi terhenti
            \Illuminate\Support\Facades\Log::warning("Payment Microservice unavailable: " . $e->getMessage());
        }

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
}
