<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class PaymentStatsController extends Controller
{
    public function getSummary(Request $request)
    {
        $filter = $request->query('filter', 'monthly');

        // 1. Total Pendapatan (Sepanjang Masa)
        $totalRevenue = Payment::where('status', 'paid')->sum('amount');

        // 2. Pertumbuhan Pendapatan & Data Grafik
        $growth = 0;
        $chartData = [];

        if ($filter === 'weekly') {
            // Growth: 7 Hari Terakhir vs 7 Hari Sebelumnya
            $thisWeekStart = Carbon::now()->subDays(6)->startOfDay();
            $lastWeekStart = Carbon::now()->subDays(13)->startOfDay();

            $thisWeekRevenue = Payment::where('status', 'paid')
                ->where('created_at', '>=', $thisWeekStart)
                ->sum('amount');

            $lastWeekRevenue = Payment::where('status', 'paid')
                ->where('created_at', '>=', $lastWeekStart)
                ->where('created_at', '<', $thisWeekStart)
                ->sum('amount');

            if ($lastWeekRevenue > 0) {
                $growth = (($thisWeekRevenue - $lastWeekRevenue) / $lastWeekRevenue) * 100;
            } elseif ($thisWeekRevenue > 0) {
                $growth = 100;
            }

            // Grafik: 7 Hari Terakhir (Harian)
            $payments = Payment::where('status', 'paid')
                ->where('created_at', '>=', $thisWeekStart)
                ->get();

            for ($i = 6; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                $formattedDate = $date->format('Y-m-d');
                $dayLabel = $date->format('D'); // e.g. Mon, Tue

                $total = $payments->filter(function($p) use ($formattedDate) {
                    return $p->created_at->format('Y-m-d') === $formattedDate;
                })->sum('amount');

                $chartData[] = [
                    'month' => $dayLabel, // Menggunakan key 'month' untuk kompatibilitas template
                    'total' => (float)$total
                ];
            }

        } elseif ($filter === 'yearly') {
            // Growth: Tahun Ini vs Tahun Lalu
            $thisYearStart = Carbon::now()->startOfYear();
            $lastYearStart = Carbon::now()->subYear()->startOfYear();

            $thisYearRevenue = Payment::where('status', 'paid')
                ->where('created_at', '>=', $thisYearStart)
                ->sum('amount');

            $lastYearRevenue = Payment::where('status', 'paid')
                ->where('created_at', '>=', $lastYearStart)
                ->where('created_at', '<', $thisYearStart)
                ->sum('amount');

            if ($lastYearRevenue > 0) {
                $growth = (($thisYearRevenue - $lastYearRevenue) / $lastYearRevenue) * 100;
            } elseif ($thisYearRevenue > 0) {
                $growth = 100;
            }

            // Grafik: 5 Tahun Terakhir (Tahunan)
            $fiveYearsAgo = Carbon::now()->subYears(4)->startOfYear();
            $payments = Payment::where('status', 'paid')
                ->where('created_at', '>=', $fiveYearsAgo)
                ->get();

            for ($i = 4; $i >= 0; $i--) {
                $date = Carbon::now()->subYears($i);
                $year = $date->format('Y');

                $total = $payments->filter(function($p) use ($year) {
                    return $p->created_at->format('Y') === $year;
                })->sum('amount');

                $chartData[] = [
                    'month' => $year, // Menggunakan key 'month' untuk kompatibilitas template
                    'total' => (float)$total
                ];
            }

        } else {
            // Default: Monthly
            // Growth: Bulan Ini vs Bulan Lalu
            $thisMonth = Carbon::now()->startOfMonth();
            $lastMonth = Carbon::now()->subMonth()->startOfMonth();

            $thisMonthRevenue = Payment::where('status', 'paid')
                ->where('created_at', '>=', $thisMonth)
                ->sum('amount');

            $lastMonthRevenue = Payment::where('status', 'paid')
                ->where('created_at', '>=', $lastMonth)
                ->where('created_at', '<', $thisMonth)
                ->sum('amount');

            if ($lastMonthRevenue > 0) {
                $growth = (($thisMonthRevenue - $lastMonthRevenue) / $lastMonthRevenue) * 100;
            } elseif ($thisMonthRevenue > 0) {
                $growth = 100;
            }

            // Grafik: 12 Bulan Terakhir (Bulanan)
            $twelveMonthsAgo = Carbon::now()->subMonths(11)->startOfMonth();
            $payments = Payment::where('status', 'paid')
                ->where('created_at', '>=', $twelveMonthsAgo)
                ->get();

            for ($i = 11; $i >= 0; $i--) {
                $date = Carbon::now()->subMonths($i);
                $yearMonth = $date->format('Y-m');
                $monthLabel = $date->format('F'); // Full month name, e.g. June

                $total = $payments->filter(function($p) use ($yearMonth) {
                    return $p->created_at->format('Y-m') === $yearMonth;
                })->sum('amount');

                $chartData[] = [
                    'month' => $monthLabel,
                    'total' => (float)$total
                ];
            }
        }

        return response()->json([
            'total_revenue' => $totalRevenue,
            'growth_percent' => round($growth, 1),
            'monthly_chart' => $chartData
        ]);
    }
}
