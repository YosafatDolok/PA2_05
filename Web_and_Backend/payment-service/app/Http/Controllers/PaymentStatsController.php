<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class PaymentStatsController extends Controller
{
    public function getSummary()
    {
        // 1. Total Pendapatan (Sepanjang Masa)
        $totalRevenue = Payment::where('status', 'paid')->sum('amount');

        // 2. Pertumbuhan Pendapatan (Bulan Ini vs Bulan Lalu)
        $thisMonth = Carbon::now()->startOfMonth();
        $lastMonth = Carbon::now()->subMonth()->startOfMonth();

        $thisMonthRevenue = Payment::where('status', 'paid')
            ->where('created_at', '>=', $thisMonth)
            ->sum('amount');

        $lastMonthRevenue = Payment::where('status', 'paid')
            ->where('created_at', '>=', $lastMonth)
            ->where('created_at', '<', $thisMonth)
            ->sum('amount');

        $growth = 0;
        if ($lastMonthRevenue > 0) {
            $growth = (($thisMonthRevenue - $lastMonthRevenue) / $lastMonthRevenue) * 100;
        } elseif ($thisMonthRevenue > 0) {
            $growth = 100;
        }

        // 3. Data Bulanan (12 Bulan Terakhir)
        $monthlyData = Payment::select(
            DB::raw('SUM(amount) as total'),
            DB::raw("strftime('%m', created_at) as month_num")
        )
            ->where('status', 'paid')
            ->where('created_at', '>=', Carbon::now()->subMonths(11)->startOfMonth())
            ->groupBy('month_num')
            ->orderBy('month_num')
            ->get()
            ->map(function($item) {
                // Ubah angka bulan menjadi nama bulan
                $monthName = Carbon::create()->month((int)$item->month_num)->format('F');
                return [
                    'month' => $monthName,
                    'total' => (float)$item->total
                ];
            });

        return response()->json([
            'total_revenue' => $totalRevenue,
            'growth_percent' => round($growth, 1),
            'monthly_chart' => $monthlyData
        ]);
    }
}
