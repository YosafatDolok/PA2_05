<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Illuminate\Http\Request;

class PaymentHistoryController extends Controller
{
    public function index()
    {
        $payments = Payment::orderBy('created_at', 'desc')
            ->get()
            ->makeHidden(['snap_token']);
        return response()->json($payments);
    }

    public function show($id)
    {
        $payment = Payment::where('order_id', $id)->first();
        if (!$payment) {
            return response()->json(['message' => 'Payment not found'], 404);
        }
        return response()->json($payment);
    }
}
