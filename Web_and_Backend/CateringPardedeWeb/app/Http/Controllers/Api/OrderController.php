<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderMessage;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::with(['status', 'driver', 'items.menu'])
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->when((int)$request->user()->role_id !== 1, function($query) use ($request) {
                return $query->where('user_id', $request->user()->user_id);
            })
            ->when($request->filter === 'pending_proposal', function($query) {
                return $query->where('final_price', 0)->where('status_id', '!=', 5);
            })
            ->when($request->filter === 'unread_chat', function($query) {
                return $query->whereHas('messages', function($q) {
                    $q->where('is_read', false)->where('sender_id', '!=', auth()->id());
                });
            })
            ->orderBy('order_date', 'desc')
            ->get();

        return response()->json($orders);
    }

    public function inbox(Request $request)
    {
        // Fetch all unique order IDs that have messages
        $orderIds = OrderMessage::distinct()->pluck('order_id');

        // Fetch those orders bypassing ALL filters and scopes
        $inbox = Order::withoutGlobalScopes()
            ->whereIn('order_id', $orderIds)
            ->with(['user', 'latestMessage'])
            ->withCount(['messages as unread_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->get()
            ->sortByDesc(function ($order) {
                return $order->latestMessage?->created_at ?? $order->updated_at;
            })
            ->values();

        return response()->json($inbox);
    }

    public function store(Request $request)
    {
        // Security: Prevent Admins from placing orders
        if ((int)$request->user()->role_id === 1) {
            return response()->json(['message' => 'Admin tidak diizinkan untuk membuat pesanan.'], 403);
        }

        Log::info('Order Submission:', $request->all());
        $validator = Validator::make($request->all(), [
            'event_address' => 'required|string',
            'event_latitude' => 'required|numeric',
            'event_longitude' => 'required|numeric',
            'event_date' => 'required|date|after_or_equal:today',
            'people' => 'required|integer|min:20|max:1000',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.menu_id' => 'required|exists:menus,menu_id',
            'items.*.quantity' => 'nullable|integer|min:1',
        ], [
            'people.required' => 'Jumlah orang wajib diisi.',
            'people.integer' => 'Jumlah orang harus berupa angka.',
            'people.min' => 'Jumlah orang minimum adalah 20 pax.',
            'people.max' => 'Jumlah orang maksimum adalah 1000 pax.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal: ' . implode(', ', $validator->errors()->all()),
                'errors' => $validator->errors()
            ], 422);
        }

        // Check availability
        $menuIds = collect($request->items)->pluck('menu_id')->toArray();
        $unavailableMenus = \App\Models\Menu::whereIn('menu_id', $menuIds)
            ->where('available', false)
            ->pluck('name');

        if ($unavailableMenus->isNotEmpty()) {
            return response()->json([
                'message' => 'Beberapa menu sedang tidak tersedia: ' . $unavailableMenus->implode(', ')
            ], 422);
        }

        $order = Order::create([
            'user_id' => $request->user()->user_id,
            'event_address' => $request->event_address,
            'event_latitude' => $request->event_latitude,
            'event_longitude' => $request->event_longitude,
            'location_notes' => $request->location_notes,
            'event_date' => $request->event_date,
            'status_id' => 1, // Pending
            'final_price' => null,
            'people' => $request->people,
            'notes' => $request->notes,
        ]);

        // Create Order Items
        foreach ($request->items as $item) {
            OrderItem::create([
                'order_id' => $order->order_id,
                'menu_id' => $item['menu_id'],
                'final_price' => null,
            ]);
        }

        // Notify Admin
        \App\Models\Notification::create([
            'user_id' => 1, // Admin
            'type' => 'new_order',
            'title' => 'Pesanan Baru #' . $order->order_id,
            'message' => $request->user()->name . ' baru saja memesan katering.',
            'related_id' => $order->order_id,
        ]);

        return response()->json([
            'message' => 'Order created successfully',
            'order' => $order->load(['status', 'items.menu'])
        ], 201);
    }

    public function show($id, Request $request)
    {
        $order = Order::with(['status', 'driver', 'items.menu', 'review'])
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->when((int)$request->user()->role_id !== 1, function($query) use ($request) {
                return $query->where(function($q) use ($request) {
                    $q->where('user_id', $request->user()->user_id)
                      ->orWhere('driver_id', $request->user()->user_id);
                });
            })
            ->findOrFail($id);

        return response()->json($order);
    }

    public function cancel($id, Request $request)
    {
        $user = $request->user();
        
        // Find order
        $query = Order::query();
        if ((int)$user->role_id !== 1) { // If not admin, must be owner
            $query->where('user_id', $user->user_id);
        }
        
        $order = $query->findOrFail($id);

        // Universal Rule: Only allow direct cancellation if status is Pending (1)
        if ($order->status_id != 1) {
            return response()->json([
                'message' => 'Pesanan tidak dapat dibatalkan langsung karena sudah diproses. Silakan ajukan permintaan pembatalan.'
            ], 400);
        }

        $oldStatusName = $order->status->status_name ?? 'Pending';

        $order->update([
            'status_id' => 9 // Cancelled
        ]);

        // LOG ACTIVITY
        \App\Models\OrderActivity::create([
            'order_id' => $order->order_id,
            'user_id' => $user->user_id,
            'type' => 'status_change',
            'description' => "Pesanan dibatalkan oleh " . ((int)$user->role_id === 1 ? 'Admin' : 'Customer'),
            'old_value' => $oldStatusName,
            'new_value' => 'Cancelled',
        ]);

        // Notify Admin if Customer cancelled
        if ((int)$user->role_id !== 1) {
            \App\Models\Notification::create([
                'user_id' => 1, // Admin
                'type' => 'system',
                'title' => 'Pesanan Dibatalkan #' . $order->order_id,
                'message' => $user->name . ' membatalkan pesanannya.',
                'related_id' => $order->order_id,
            ]);
        }

        return response()->json([
            'message' => 'Pesanan berhasil dibatalkan',
            'order' => $order->load(['status', 'items.menu'])
        ]);
    }

    public function requestCancel($id, Request $request)
    {
        $request->validate([
            'reason' => 'required|string|min:5'
        ]);

        $user = $request->user();
        $order = Order::where('user_id', $user->user_id)->findOrFail($id);

        // Security Check: Status must be 2 (Confirmed) or 3 (Preparing)
        if (!in_array($order->status_id, [2, 3])) {
            return response()->json([
                'message' => 'Permintaan pembatalan tidak diizinkan pada tahap ini.'
            ], 400);
        }

        // Security Check: Must not be paid
        if ($order->total_paid > 0) {
            return response()->json([
                'message' => 'Pesanan yang sudah dibayar tidak dapat dibatalkan lewat aplikasi.'
            ], 400);
        }

        $order->update([
            'is_cancelling' => true,
            'cancel_reason' => $request->reason
        ]);

        // Notify Admin
        \App\Models\Notification::create([
            'user_id' => 1, // Admin
            'type' => 'system',
            'title' => 'Permintaan Pembatalan #' . $order->order_id,
            'message' => $user->name . ' mengajukan pembatalan: "' . $request->reason . '"',
            'related_id' => $order->order_id,
        ]);

        return response()->json([
            'message' => 'Permintaan pembatalan telah dikirim ke admin',
            'order' => $order->load(['status', 'items.menu'])
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        Log::info('Update Status from Payment Service', $request->all());

        $request->validate([
            'status_id' => 'required|integer',
            'amount' => 'nullable|numeric',
            'external_id' => 'nullable|string'
        ]);

        $order = Order::findOrFail($id);

        // Cek Idempotensi: Mencegah penghitungan ganda untuk transaksi yang sama
        if ($request->external_id && \App\Models\ProcessedPayment::where('external_id', $request->external_id)->exists()) {
            Log::info("Duplicate payment signal received for External ID: {$request->external_id}. Ignoring.");
            return response()->json([
                'message' => 'Payment already processed',
                'order' => $order
            ]);
        }

        // Tambahkan jumlah pembayaran jika nominal dikirimkan dan statusnya Lunas (5)
        if ($request->status_id == 5 && $request->amount > 0) {
            $order->total_paid = (float)$order->total_paid + (float)$request->amount;
            
            // Catat ID transaksi ini
            if ($request->external_id) {
                \App\Models\ProcessedPayment::create([
                    'order_id' => $id,
                    'external_id' => $request->external_id,
                    'amount' => $request->amount
                ]);
            }
            
            Log::info("Payment of {$request->amount} accumulated for Order #{$id}. Total now: {$order->total_paid}");
        }

        if ($request->status_id == 5) {
            // Notifikasi pembayaran dari microservice
            // Status pesanan hanya diubah ke Lunas (5) jika:
            // 1. Pesanan saat ini sudah Dikirim (4) DAN sisa tagihan <= 0
            // 2. Atau jika pesanan memang sudah Lunas (5)
            if (((int)$order->status_id === 4 && $order->remaining_balance <= 0) || (int)$order->status_id === 5) {
                $order->status_id = 5;
                Log::info("Order #{$id} status set/kept to PAID.");
            } else {
                Log::info("Order #{$id} received payment, but status remains {$order->status_id} (not Delivered yet, or not fully paid).");
            }
        } else {
            // Untuk perubahan status lainnya
            $order->status_id = $request->status_id;
        }

        $order->save();

        return response()->json([
            'message' => 'Status updated successfully',
            'order' => $order
        ]);
    }

    public function getBillingDetails($id)
    {
        $order = Order::findOrFail($id);
        return response()->json([
            'order_id' => $order->order_id,
            'user_id' => $order->user_id,
            'remaining_balance' => (float)$order->remaining_balance,
        ]);
    }

    public function receivePaymentNotification(Request $request, $id)
    {
        Log::info("Payment notification received for Order #{$id}", $request->all());

        $request->validate([
            'payment_status' => 'required|string',
            'amount' => 'required|numeric',
            'external_id' => 'required|string'
        ]);

        $order = Order::findOrFail($id);

        // Cek Idempotensi: Mencegah pemrosesan ganda
        if (\App\Models\ProcessedPayment::where('external_id', $request->external_id)->exists()) {
            Log::info("Duplicate payment signal received for External ID: {$request->external_id}. Ignoring.");
            return response()->json([
                'message' => 'Pembayaran sudah diproses sebelumnya.',
                'order' => $order
            ]);
        }

        if ($request->payment_status === 'settled') {
            // Tambahkan nominal pembayaran ke total yang dibayarkan
            $order->total_paid = (float)$order->total_paid + (float)$request->amount;
            
            // Catat transaksi ke log pembayaran terproses
            \App\Models\ProcessedPayment::create([
                'order_id' => $id,
                'external_id' => $request->external_id,
                'amount' => $request->amount
            ]);
            
            Log::info("Payment of {$request->amount} recorded for Order #{$id}. Total paid now: {$order->total_paid}");

            // Tentukan status pesanan secara mandiri:
            // Jika pesanan sudah Dikirim (4) dan sisa tagihan sudah lunas (<= 0), ubah ke Lunas (5)
            if ((int)$order->status_id === 4 && $order->remaining_balance <= 0) {
                $order->status_id = 5;
                Log::info("Order #{$id} status set to PAID.");
            }
            
            $order->save();
        }

        return response()->json([
            'message' => 'Notifikasi pembayaran berhasil diproses.',
            'order' => $order
        ]);
    }
}
