<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatus;
use App\Models\Notification;
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
        $order = Order::with([
            'user', 
            'driver', 
            'status', 
            'items.menu',
            'additions.items.menu',
            'additions.status'
        ])->findOrFail($id);
        
        $statuses = OrderStatus::all()->unique('status_name');
        return view('admin.orders.show', compact('order', 'statuses'));
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status_id' => 'required|exists:order_statuses,status_id',
            'final_price' => 'nullable|numeric|min:0',
        ], [
            'status_id.required' => 'Status pesanan wajib dipilih.',
            'final_price.numeric' => 'Harga final harus berupa angka.',
            'final_price.min' => 'Harga final tidak boleh negatif.',
        ]);

        $order = Order::findOrFail($id);
        $order->status_id = $request->status_id;
        if ($request->has('final_price')) {
            $order->final_price = $request->final_price;
        }
        $order->save();

        // Create Notification for User
        $statusName = $order->status->name;
        Notification::create([
            'user_id' => $order->user_id,
            'type' => 'order_status',
            'title' => 'Update Pesanan #' . $order->order_id,
            'message' => 'Pesanan Anda sekarang: ' . $statusName,
            'related_id' => $order->order_id,
        ]);

        return redirect()->back()->with('success', 'Detail pesanan berhasil diperbarui');
    }

    public function updateStatusApi(Request $request, $id)
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

    // Notification
    $statusName = $order->status->status_name;
    Notification::create([
        'user_id' => $order->user_id,
        'type' => 'order_status',
        'title' => 'Update Pesanan #' . $order->order_id,
        'message' => 'Pesanan Anda sekarang: ' . $statusName,
        'related_id' => $order->order_id,
    ]);

    return response()->json([
        'message' => 'Status updated',
        'order' => $order
    ]);
}


}
