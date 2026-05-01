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
        $orders = Order::with(['user', 'status', 'items.menu'])
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->orderBy('order_date', 'desc')
            ->get();
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

    public function chat($id)
    {
        $order = Order::with(['user', 'status', 'items.menu'])->findOrFail($id);
        return view('admin.orders.chat', compact('order'));
    }

    public function messages()
    {
        $orders = Order::with(['user', 'status'])
            ->has('messages')
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->with(['messages' => function ($query) {
                $query->latest()->limit(1);
            }])
            ->get()
            ->sortByDesc(function ($order) {
                return $order->messages->first()?->created_at;
            });

        return view('admin.messages.index', compact('orders'));
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
}
