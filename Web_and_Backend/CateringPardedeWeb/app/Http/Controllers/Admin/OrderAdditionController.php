<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\OrderAdditionRequest;
use App\Models\OrderAdditionItem;
use App\Models\Notification;
use App\Models\OrderActivity;
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

        // LOG ACTIVITY
        OrderActivity::create([
            'order_id' => $additionRequest->order_id,
            'user_id' => auth()->id(),
            'type' => 'addition_approved',
            'description' => "Permintaan menu tambahan disetujui (Total: Rp " . number_format($additionRequest->items->sum('final_price'), 0, ',', '.') . ")",
            'new_value' => 'Approved',
        ]);

        return back()->with('success', 'Permintaan tambahan berhasil disetujui');
    }

    public function reject($id)
    {
        $additionRequest = OrderAdditionRequest::findOrFail($id);
        $additionRequest->update(['status_id' => 3]); // Rejected

        // LOG ACTIVITY
        OrderActivity::create([
            'order_id' => $additionRequest->order_id,
            'user_id' => auth()->id(),
            'type' => 'addition_rejected',
            'description' => "Permintaan menu tambahan ditolak",
            'new_value' => 'Rejected',
        ]);

        return back()->with('success', 'Permintaan tambahan berhasil ditolak');
    }
}
