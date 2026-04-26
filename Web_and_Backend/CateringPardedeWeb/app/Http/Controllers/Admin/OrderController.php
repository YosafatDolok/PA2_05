<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatus;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['user', 'status', 'items.menu'])->orderBy('order_date', 'desc')->get();
        return view('admin.orders.index', compact('orders'));
    }

    public function show($id)
    {
        $order = Order::with(['user', 'driver', 'status', 'items.menu'])->findOrFail($id);
        $statuses = OrderStatus::all();
        return view('admin.orders.show', compact('order', 'statuses'));
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status_id' => 'required|exists:order_statuses,status_id',
            'final_price' => 'nullable|numeric|min:0',
        ]);

        $order = Order::findOrFail($id);
        $order->status_id = $request->status_id;
        if ($request->has('final_price')) {
            $order->final_price = $request->final_price;
        }
        $order->save();

        return redirect()->back()->with('success', 'Detail pesanan berhasil diperbarui');
    }
}
