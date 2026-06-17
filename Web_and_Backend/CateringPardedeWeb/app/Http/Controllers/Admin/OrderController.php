<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatus;
use App\Models\Notification;
use App\Models\OrderActivity;
use App\Models\User;
use App\Services\FirebaseService;
use App\Exports\OrdersExport;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Http\Request;
use Barryvdh\DomPDF\Facade\Pdf;

class OrderController extends Controller
{
    public function index(\Illuminate\Http\Request $request)
    {
        $statusId = $request->get('status');
        
        $query = Order::with(['user', 'status', 'items.menu'])
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }]);

        if ($statusId === 'unpaid_delivery') {
            $query->where('status_id', 4)->where('remaining_balance', '>', 0);
        } elseif ($statusId) {
            $query->where('status_id', $statusId);
        }

        $orders = $query->orderBy('order_date', 'desc')->get();
        $statuses = \App\Models\OrderStatus::all()->unique('status_name');

        return view('admin.orders.index', compact('orders', 'statuses'));
    }

    public function show($id)
    {
        $order = Order::with([
            'user', 
            'driver', 
            'status', 
            'items.menu',
            'additions.items.menu',
            'additions.status',
            'activities.user'
        ])->findOrFail($id);
        
        $statuses = OrderStatus::all()->unique('status_name');
        $drivers = User::where('role_id', 3)
            ->withCount(['assignedOrders as active_deliveries' => function ($query) {
                $query->where('status_id', 3); // Out for Delivery
            }])
            ->get()
            ->sortBy(function ($driver) {
                // berdasarkan prioritas:
                // 1. Available (0 pengiriman)
                // 2. Busy (1-2 pengiriman)
                // 3. Full Capacity (>3 pengiriman)
                if ($driver->active_deliveries == 0) return 1;
                if ($driver->active_deliveries < 3) return 2;
                return 3;
            });

        //mark as read
        \App\Models\OrderMessage::where('order_id', $id)
            ->where('sender_id', '!=', auth()->id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

        //mark as read(notifikasi)
        \App\Models\Notification::where('related_id', $id)
            ->where('user_id', auth()->id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return view('admin.orders.show', compact('order', 'statuses', 'drivers'));
    }

    public function exportInvoice($id)
    {
        $order = Order::with([
            'user',
            'driver',
            'status',
            'items.menu',
            'additions.items.menu',
            'additions.status'
        ])->findOrFail($id);

        $pdf = Pdf::loadView('admin.orders.invoice', compact('order'));
        return $pdf->download('Invoice_ORD_' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT) . '.pdf');
    }

    public function chat($id)
    {
        $order = Order::with(['user', 'status', 'items.menu'])->findOrFail($id);

        //mark as read ketika admin membuka chat
        \App\Models\OrderMessage::where('order_id', $id)
            ->where('sender_id', '!=', auth()->id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

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

    public function export(\Illuminate\Http\Request $request)
    {
        $statusId = $request->get('status');
        $fileName = 'Catering_Pardede_Orders_' . date('Y-m-d_His') . '.xlsx';
        return Excel::download(new OrdersExport($statusId), $fileName);
    }

    public function handleCancelRequest(Request $request, $id)
    {
        $request->validate([
            'action' => 'required|in:approve,reject'
        ]);

        $order = Order::findOrFail($id);
        
        if (!$order->is_cancelling) {
            return redirect()->back()->with('error', 'Tidak ada permintaan pembatalan untuk pesanan ini.');
        }

        if ($request->action === 'approve') {
            $forfeited = (float)$order->total_paid;
            
            $order->update([
                'status_id' => 9, // Cancelled
                'is_cancelling' => false,
                'forfeited_amount' => $order->forfeited_amount + $forfeited,
                'total_paid' => 0, //total_paid menjadi 0
            ]);

            $desc = "Permintaan pembatalan DISETUJUI oleh Admin.";
            if ($forfeited > 0) {
                $desc .= " Uang sejumlah Rp " . number_format($forfeited, 0, ',', '.') . " hangus.";
            }

            OrderActivity::create([
                'order_id' => $order->order_id,
                'user_id' => auth()->id(),
                'type' => 'status_change',
                'description' => $desc,
                'old_value' => 'Requested',
                'new_value' => 'Cancelled',
            ]);

            $notification = Notification::create([
                'user_id' => $order->user_id,
                'type' => 'order_status',
                'title' => 'Pembatalan Disetujui #' . $order->order_id,
                'message' => 'Permintaan pembatalan Anda telah disetujui oleh Admin.',
                'related_id' => $order->order_id,
            ]);
            $this->sendPush($order->user, $notification, $order->order_id);

            return redirect()->back()->with('success', 'Pesanan berhasil dibatalkan.');
        } else {
            $order->update([
                'is_cancelling' => false
            ]);

            OrderActivity::create([
                'order_id' => $order->order_id,
                'user_id' => auth()->id(),
                'type' => 'status_change',
                'description' => "Permintaan pembatalan DITOLAK oleh Admin.",
                'old_value' => 'Requested',
                'new_value' => 'Active',
            ]);

            $notification = Notification::create([
                'user_id' => $order->user_id,
                'type' => 'order_status',
                'title' => 'Pembatalan Ditolak #' . $order->order_id,
                'message' => 'Maaf, permintaan pembatalan Anda ditolak oleh Admin. Pesanan akan tetap diproses.',
                'related_id' => $order->order_id,
            ]);
            $this->sendPush($order->user, $notification, $order->order_id);

            return redirect()->back()->with('info', 'Permintaan pembatalan ditolak.');
        }
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
        
        //Aturan Keamanan: Hanya izinkan pembatalan (9) jika pesanan masih berstatus Menunggu (1)
        if ($request->status_id == 9 && $order->status_id != 1) {
            return redirect()->back()->with('error', 'Hanya pesanan berstatus Pending yang dapat dibatalkan.');
        }

        $oldPrice = $order->final_price;
        $oldStatusId = $order->status_id;
        $order->status_id = $request->status_id;

        //Transisi Pembayaran Otomatis: Periksa apakah pesanan telah dibayar lunas saat ditandai sebagai Terkirim (4)
        if ($order->status_id == 4 && $order->remaining_balance <= 0) {
            $order->status_id = 5; // Paid
        }

        $order->save();

        //log activities
        
        // 1.Status Change Activity
        if ($oldStatusId != $order->status_id) {
            $oldStatusName = OrderStatus::find($oldStatusId)->status_name ?? 'N/A';
            $newStatusName = $order->status->status_name;
            
            OrderActivity::create([
                'order_id' => $order->order_id,
                'user_id' => auth()->id(),
                'type' => 'status_change',
                'description' => "Status pesanan diubah dari $oldStatusName ke $newStatusName",
                'old_value' => $oldStatusName,
                'new_value' => $newStatusName,
            ]);

            //notifikasi user
            $notification = Notification::create([
                'user_id' => $order->user_id,
                'type' => 'order_status',
                'title' => 'Update Status Pesanan #' . $order->order_id,
                'message' => 'Pesanan Anda sekarang: ' . $newStatusName,
                'related_id' => $order->order_id,
            ]);
            $this->sendPush($order->user, $notification, $order->order_id);
        }



        return redirect()->back()->with('success', 'Detail pesanan berhasil diperbarui');
    }

    public function updateItemPrices(Request $request, $id)
    {
        $request->validate([
            'prices' => 'required|array',
            'prices.*' => 'nullable|numeric|min:0',
        ]);

        $order = Order::with(['items', 'additions.items'])->findOrFail($id);

        if ($order->status_id > 1) {
            return redirect()->back()->with('error', 'Harga tidak dapat diubah karena pesanan sudah diproses.');
        }

        $oldPrice = $order->final_price;
        $sum = 0;

        //Perbarui harga setiap item
        foreach ($order->items as $item) {
            if (isset($request->prices[$item->order_item_id])) {
                $item->final_price = $request->prices[$item->order_item_id];
                $item->save();
            }
            $sum += $item->final_price;
        }

        //Tambahkan tambahan yang telah disetujui ke dalam total pembayaran
        foreach ($order->additions->where('status_id', 2) as $addition) {
            $sum += $addition->items->sum('final_price');
        }

        $order->final_price = $sum;
        $order->save();

        if ($oldPrice != $order->final_price) {
            OrderActivity::create([
                'order_id' => $order->order_id,
                'user_id' => auth()->id(),
                'type' => 'price_set',
                'description' => "Harga per-menu diatur, total harga diperbarui menjadi Rp " . number_format($order->final_price, 0, ',', '.'),
                'old_value' => $oldPrice,
                'new_value' => $order->final_price,
            ]);

            //notifikasi user
            $notification = \App\Models\Notification::create([
                'user_id' => $order->user_id,
                'type' => 'order_price',
                'title' => 'Update Harga Pesanan #' . $order->order_id,
                'message' => 'Admin telah menetapkan harga pesanan Anda: Rp ' . number_format($order->final_price, 0, ',', '.'),
                'related_id' => $order->order_id,
            ]);
            $this->sendPush($order->user, $notification, $order->order_id);
        }

        return redirect()->back()->with('success', 'Harga menu berhasil disimpan dan total harga telah diperbarui.');
    }

    public function assignDriver(Request $request, $id)
    {
        $request->validate([
            'driver_id' => [
                'nullable',
                'exists:users,user_id',
                function ($attribute, $value, $fail) {
                    if ($value) {
                        $user = User::find($value);
                        if ($user && $user->role_id != 3) {
                            $fail('The selected user must have the Driver role.');
                        }
                    }
                },
            ],
        ]);

        $order = Order::findOrFail($id);

        // Jika meng-assign driver baru (bukan menghapus / unassign)
        if ($request->driver_id) {
            $driver = User::find($request->driver_id);
            // Cek limit kapasitas driver
            $activeDeliveries = Order::where('driver_id', $driver->user_id)
                ->where('status_id', 4) // Asumsi 4 = Out for Delivery / Active
                ->count();

            if ($activeDeliveries >= 3) {
                return redirect()->back()->with('error', 'Gagal menugaskan: Driver ' . $driver->name . ' sedang mencapai kapasitas maksimal (3 pesanan aktif).');
            }
        }

        $order->driver_id = $request->driver_id;

        if ($order->isDirty('driver_id')) {
            $order->save();

            $driverName = $order->driver->name ?? 'N/A';
            OrderActivity::create([
                'order_id' => $order->order_id,
                'user_id' => auth()->id(),
                'type' => 'driver_assigned',
                'description' => $order->driver_id ? "Driver $driverName ditugaskan" : "Penugasan driver dibatalkan",
                'new_value' => $driverName,
            ]);

            if ($order->driver_id) {
                $driverNotification = Notification::create([
                    'user_id' => $order->driver_id,
                    'type' => 'driver_assignment',
                    'title' => 'Tugas Baru: Pesanan #' . $order->order_id,
                    'message' => 'Anda telah ditugaskan untuk mengantar pesanan ini.',
                    'related_id' => $order->order_id,
                ]);
                $this->sendPush($order->driver, $driverNotification, $order->order_id);
            }
            
            return redirect()->back()->with('success', 'Driver berhasil ' . ($request->driver_id ? 'ditugaskan.' : 'dibatalkan.'));
        }

        return redirect()->back()->with('info', 'Tidak ada perubahan pada penugasan driver.');
    }

    /**
     * Helper untuk mengirim notifikasi push secara aman kepada pengguna tertentu
     */
    private function sendPush($recipient, $notification, $orderId)
    {
        \Log::info('Attempting Push Notification', [
            'order_id' => $orderId,
            'recipient_id' => $recipient->user_id,
            'fcm_token' => $recipient->fcm_token ? 'Exists' : 'Missing'
        ]);

        if ($recipient->fcm_token) {
            try {
                $firebase = new FirebaseService();
                $result = $firebase->sendNotification(
                    $recipient->fcm_token,
                    $notification->title,
                    $notification->message,
                    [
                        'type' => (string) $notification->type,
                        'order_id' => (string) $orderId,
                    ]
                );
                
                \Log::info('Push Notification Result', ['success' => $result]);
            } catch (\Exception $e) {
                \Log::error('Firebase Push Failed: ' . $e->getMessage());
            }
        } else {
            \Log::warning('Push skipped: No FCM token for user ' . $recipient->user_id);
        }
    }
}
