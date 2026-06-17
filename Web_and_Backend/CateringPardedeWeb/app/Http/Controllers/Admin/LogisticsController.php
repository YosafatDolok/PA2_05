<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;

class LogisticsController extends Controller
{
    public function index()
    {
        //Lokasi Catering Pardede
        $baseLocation = [
            'lat' => 2.437190,
            'lng' => 99.157618,
            'name' => 'Catering Pardede Base'
        ];

        // 1. lihat driver aktif
        $drivers = User::where('role_id', 3)->get();

        // 2. lihat order aktif yang akan dikirim
        $activeOrders = Order::whereIn('status_id', [2, 3])
            ->with(['user', 'driver', 'status'])
            ->get();

        return view('admin.logistics.index', compact('drivers', 'activeOrders', 'baseLocation'));
    }

}
