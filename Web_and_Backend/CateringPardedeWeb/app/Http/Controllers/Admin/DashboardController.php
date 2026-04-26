<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Models\Order;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $totalMenus = Menu::count();
        $ordersReceived = Order::count();
        $activeMenus = Menu::where('available', 1)->count();

        return view('admin.dashboard', compact('totalMenus', 'ordersReceived', 'activeMenus'));
    }
}
