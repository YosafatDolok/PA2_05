<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatus;
use App\Models\Notification;
use App\Services\FirebaseService;
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
        $drivers = \App\Models\User::where('role_id', 3)->get();
        return view('admin.orders.show', compact('order', 'statuses', 'drivers'));
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

    public function export()
    {
        $fileName = 'Catering_Pardede_Orders_' . date('Y-m-d_His') . '.csv';
        $orders = Order::with(['user', 'status', 'items.menu'])->orderBy('order_date', 'desc')->get();

        $headers = [
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$fileName",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        ];

        $columns = ['Order ID', 'Customer', 'Email', 'Menus', 'Event Date', 'People', 'Price', 'Status', 'Order Created'];

        $callback = function() use($orders, $columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);

            foreach ($orders as $order) {
                $row['Order ID']      = 'ORD-' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT);
                $row['Customer']      = $order->user->name;
                $row['Email']         = $order->user->email;
                $row['Menus']         = $order->items->pluck('menu.name')->implode(', ');
                $row['Event Date']    = $order->event_date->format('d M Y');
                $row['People']        = $order->people;
                $row['Price']         = $order->final_price ? 'Rp ' . number_format($order->final_price, 0, ',', '.') : 'TBD';
                $row['Status']        = $order->status->status_name;
                $row['Order Created'] = $order->created_at->format('d M Y H:i');

                fputcsv($file, array_values($row));
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status_id' => 'required|exists:order_statuses,status_id',
            'final_price' => 'nullable|numeric|min:0',
            'driver_id' => [
                'nullable',
                'exists:users,user_id',
                function ($attribute, $value, $fail) {
                    $user = \App\Models\User::find($value);
                    if ($user && $user->role_id != 3) {
                        $fail('The selected user must have the Driver role.');
                    }
                },
            ],
        ], [
            'status_id.required' => 'Status pesanan wajib dipilih.',
            'final_price.numeric' => 'Harga final harus berupa angka.',
            'final_price.min' => 'Harga final tidak boleh negatif.',
        ]);

        $order = Order::findOrFail($id);
        $oldPrice = $order->final_price;
        $oldStatusId = $order->status_id;

        $order->status_id = $request->status_id;
        if ($request->has('final_price')) {
            $order->final_price = $request->final_price;
        }
        $order->driver_id = $request->driver_id;
        $order->save();

        // 1. Handle Status Change Notification
        if ($oldStatusId != $order->status_id) {
            $statusName = $order->status->status_name; // Fixed: status_name instead of name
            $notification = Notification::create([
                'user_id' => $order->user_id,
                'type' => 'order_status',
                'title' => 'Update Status Pesanan #' . $order->order_id,
                'message' => 'Pesanan Anda sekarang: ' . $statusName,
                'related_id' => $order->order_id,
            ]);

            $this->sendPush($order, $notification);
        }

        // 2. Handle Price Update Notification
        if ($request->has('final_price') && $oldPrice != $order->final_price) {
            $notification = Notification::create([
                'user_id' => $order->user_id,
                'type' => 'order_price',
                'title' => 'Update Harga Pesanan #' . $order->order_id,
                'message' => 'Admin telah menetapkan harga final untuk pesanan Anda: Rp ' . number_format($order->final_price, 0, ',', '.'),
                'related_id' => $order->order_id,
            ]);

            $this->sendPush($order, $notification);
        }

        return redirect()->back()->with('success', 'Detail pesanan berhasil diperbarui');
    }

    /**
     * Helper to send push notification safely
     */
    private function sendPush($order, $notification)
    {
        \Log::info('Attempting Push Notification', [
            'order_id' => $order->order_id,
            'user_id' => $order->user_id,
            'fcm_token' => $order->user->fcm_token ? 'Exists' : 'Missing'
        ]);

        if ($order->user->fcm_token) {
            try {
                $firebase = new FirebaseService();
                $result = $firebase->sendNotification(
                    $order->user->fcm_token,
                    $notification->title,
                    $notification->message,
                    [
                        'type' => (string) $notification->type,
                        'order_id' => (string) $order->order_id,
                    ]
                );
                
                \Log::info('Push Notification Result', ['success' => $result]);
            } catch (\Exception $e) {
                \Log::error('Firebase Push Failed: ' . $e->getMessage());
            }
        } else {
            \Log::warning('Push skipped: No FCM token for user ' . $order->user_id);
        }
    }
}
