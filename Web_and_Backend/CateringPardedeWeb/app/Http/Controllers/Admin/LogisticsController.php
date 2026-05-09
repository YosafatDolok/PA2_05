<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Models\DriverLocation;
use Illuminate\Http\Request;

class LogisticsController extends Controller
{
    public function index()
    {
        // 🏰 Pardede Base (The Shop)
        $baseLocation = [
            'lat' => 2.437190,
            'lng' => 99.157618,
            'name' => 'Catering Pardede Base'
        ];

        // 1. Get all active drivers
        $drivers = User::where('role_id', 3)->get();

        // 2. Get active orders (Out for delivery or Preparing)
        $activeOrders = Order::whereIn('status_id', [2, 3])
            ->with(['user', 'driver', 'status'])
            ->get();

        return view('admin.logistics.index', compact('drivers', 'activeOrders', 'baseLocation'));
    }

    /**
     * API endpoint for AJAX polling (optional if using Reverb, but good for stability)
     */
    public function getLiveUpdates()
    {
        $locations = DriverLocation::with('user:user_id,name')->get();
        return response()->json($locations);
    }
}
