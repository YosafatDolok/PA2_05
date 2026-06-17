<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrderAdditionRequest;
use App\Models\OrderAdditionItem;
use App\Models\Notification;
use App\Models\OrderActivity;
use Illuminate\Http\Request;
use App\Services\FirebaseService;

class OrderAdditionController extends Controller
{
    public function index()
    {
        $requests = OrderAdditionRequest::with(['order.user', 'items.menu', 'status'])
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return view('admin.additions.index', compact('requests'));
    }

    public function approve(Request $request, $id)
    {
        $request->validate([
            'prices' => 'required|array',
            'prices.*' => 'required|numeric|min:0',
        ], [
            'prices.*.required' => 'Harap isi semua harga untuk menu tambahan.',
            'prices.*.numeric' => 'Harga harus berupa angka.',
            'prices.*.min' => 'Harga tidak boleh kurang dari 0.',
        ]);

        $additionRequest = OrderAdditionRequest::findOrFail($id);
        
        foreach ($request->prices as $itemId => $price) {
            OrderAdditionItem::where('id', $itemId)->update(['final_price' => $price]);
        }
        
        $additionRequest->update(['status_id' => 2]); // Approved
        $additionRequest->load('items');

        //log activity
        OrderActivity::create([
            'order_id' => $additionRequest->order_id,
            'user_id' => auth()->id(),
            'type' => 'addition_approved',
            'description' => "Permintaan menu tambahan disetujui (Total: Rp " . number_format($additionRequest->items->sum('final_price'), 0, ',', '.') . ")",
            'new_value' => 'Approved',
        ]);

        //notifikasi user
        $order = $additionRequest->order;
        $notification = Notification::create([
            'user_id' => $order->user_id,
            'type' => 'order_status',
            'title' => 'Permintaan Tambahan Disetujui',
            'message' => 'Permintaan tambahan menu untuk Pesanan #ORD-' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT) . ' telah disetujui.',
            'related_id' => $order->order_id,
        ]);
        $this->sendPush($order->user, $notification, $order->order_id);

        return redirect(url()->previous() . '#additions-section')->with('success', 'Permintaan tambahan berhasil disetujui');
    }

    public function savePrices(Request $request, $id)
    {
        $request->validate([
            'prices' => 'required|array',
            'prices.*' => 'nullable|numeric|min:0',
        ], [
            'prices.*.numeric' => 'Harga harus berupa angka.',
            'prices.*.min' => 'Harga tidak boleh kurang dari 0.',
        ]);

        $additionRequest = OrderAdditionRequest::findOrFail($id);
        
        foreach ($request->prices as $itemId => $price) {
            OrderAdditionItem::where('id', $itemId)->update(['final_price' => $price]);
        }
        
        $additionRequest->load('items');

        //log aktivitas
        OrderActivity::create([
            'order_id' => $additionRequest->order_id,
            'user_id' => auth()->id(),
            'type' => 'addition_priced',
            'description' => "Harga permintaan tambahan disimpan (Total: Rp " . number_format($additionRequest->items->sum('final_price'), 0, ',', '.') . ")",
            'new_value' => 'Pending',
        ]);

        return redirect(url()->previous() . '#additions-section')->with('success', 'Harga tambahan berhasil disimpan tanpa disetujui');
    }

    public function reject($id)
    {
        $additionRequest = OrderAdditionRequest::findOrFail($id);
        $additionRequest->update(['status_id' => 3]); // Rejected

        //log aktivitas
        OrderActivity::create([
            'order_id' => $additionRequest->order_id,
            'user_id' => auth()->id(),
            'type' => 'addition_rejected',
            'description' => "Permintaan menu tambahan ditolak",
            'new_value' => 'Rejected',
        ]);

        //notifikasi user
        $order = $additionRequest->order;
        $notification = Notification::create([
            'user_id' => $order->user_id,
            'type' => 'order_status',
            'title' => 'Permintaan Tambahan Ditolak',
            'message' => 'Permintaan tambahan menu untuk Pesanan #ORD-' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT) . ' telah ditolak.',
            'related_id' => $order->order_id,
        ]);
        $this->sendPush($order->user, $notification, $order->order_id);

        return back()->with('success', 'Permintaan tambahan berhasil ditolak');
    }

    //Helper untuk push notifikasi ke user
    private function sendPush($recipient, $notification, $orderId)
    {
        \Log::info('Attempting Push Notification (Addition)', [
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
                
                \Log::info('Push Notification Result (Addition)', ['success' => $result]);
            } catch (\Exception $e) {
                \Log::error('Firebase Push Failed (Addition): ' . $e->getMessage());
            }
        } else {
            \Log::warning('Push skipped (Addition): No FCM token for user ' . $recipient->user_id);
        }
    }
}
