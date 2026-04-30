<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrderAdditionRequest;
use App\Models\OrderAdditionItem;
use App\Models\Notification;
use Illuminate\Http\Request;

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

        // Notify User
        Notification::create([
            'user_id' => $additionRequest->order->user_id,
            'type' => 'order_status',
            'title' => 'Tambahan Menu Disetujui',
            'message' => 'Tambahan menu Anda untuk Order #ORD-' . str_pad($additionRequest->order_id, 5, '0', STR_PAD_LEFT) . ' telah disetujui.',
            'related_id' => $additionRequest->order_id,
        ]);

        return back()->with('success', 'Permintaan tambahan berhasil disetujui');
    }

    public function reject($id)
    {
        $additionRequest = OrderAdditionRequest::findOrFail($id);
        $additionRequest->update(['status_id' => 3]); // Rejected

        return back()->with('success', 'Permintaan tambahan berhasil ditolak');
    }
}
