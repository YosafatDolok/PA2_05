<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Midtrans\Config;
use Midtrans\Snap;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    /**
     * 1. Inisialisasi Pembayaran (Dipanggil dari Flutter)
     */
    public function store(Request $request)
    {
        $request->validate([
            'order_id' => 'required',
            'amount' => 'nullable|numeric|min:10000' // Midtrans minimum is usually 10,000
        ]);

        $user = $request->attributes->get('authenticated_user');
        if (!$user) {
            return response()->json(['message' => 'User tidak terautentikasi.'], 401);
        }

        // Ambil info billing secara aman dari backend utama
        try {
            $mainAppUrl = env('MAIN_APP_URL', 'http://localhost:8000');
            $response = Http::withHeaders([
                'X-Internal-Secret' => env('INTERNAL_SERVICE_KEY', 'default_secret_key'),
                'Accept' => 'application/json'
            ])->timeout(10)->get($mainAppUrl . '/api/orders/' . $request->order_id . '/billing');

            if (!$response->successful()) {
                return response()->json(['message' => 'Gagal mendapatkan data tagihan pesanan.'], 400);
            }

            $billing = $response->json();
        } catch (\Exception $e) {
            Log::error('Gagal memanggil API billing internal: ' . $e->getMessage());
            return response()->json(['message' => 'Kesalahan koneksi ke server utama.'], 500);
        }

        // Verifikasi kepemilikan pesanan
        if ((int)$billing['user_id'] !== (int)$user['user_id']) {
            return response()->json(['message' => 'Anda tidak memiliki hak untuk membayar pesanan ini.'], 403);
        }

        $remainingBalance = (float)$billing['remaining_balance'];

        // Cek jika pesanan sudah lunas
        if ($remainingBalance <= 0) {
            return response()->json(['message' => 'Pesanan ini sudah lunas.'], 400);
        }

        $totalPayable = (float)($billing['total_payable'] ?? $remainingBalance);
        $minDpAmount = $totalPayable * 0.5;

        $paymentAmount = $remainingBalance;
        if ($request->has('amount') && $request->amount > 0) {
            $paymentAmount = (float)$request->amount;
            if ($paymentAmount > $remainingBalance) {
                return response()->json(['message' => 'Nominal pembayaran tidak boleh melebihi sisa tagihan.'], 400);
            }
            if ($paymentAmount < $minDpAmount && $remainingBalance >= $minDpAmount) {
                return response()->json(['message' => 'Minimal pembayaran DP adalah 50% dari total tagihan.'], 400);
            }
        }

        // Buat rekaman pembayaran baru menggunakan nominal terverifikasi
        $payment = Payment::create([
            'order_id' => $request->order_id,
            'amount' => $paymentAmount,
            'payment_method' => 'midtrans',
            'status' => 'pending',
            'external_id' => 'ORD-' . $request->order_id . '-' . strtoupper(Str::random(5)) . '-' . time(),
        ]);

        return response()->json($payment, 201);
    }

    /**
     * 2. Buat Token Snap Midtrans
     */
    public function createTransaction(Request $request, $id)
    {
        $request->validate([
            'payment_type' => 'required|string',
            'bank' => 'nullable|string'
        ]);

        // Ambil data pembayaran yang sudah ada
        $payment = Payment::find($id);
        if (!$payment) {
            return response()->json(['message' => 'Payment record not found'], 404);
        }

        $user = $request->attributes->get('authenticated_user');
        if (!$user) {
            return response()->json(['message' => 'User tidak terautentikasi.'], 401);
        }

        // Verifikasi kepemilikan pesanan dari backend utama
        try {
            $mainAppUrl = env('MAIN_APP_URL', 'http://localhost:8000');
            $response = Http::withHeaders([
                'X-Internal-Secret' => env('INTERNAL_SERVICE_KEY', 'default_secret_key'),
                'Accept' => 'application/json'
            ])->timeout(10)->get($mainAppUrl . '/api/orders/' . $payment->order_id . '/billing');

            if (!$response->successful()) {
                return response()->json(['message' => 'Gagal memverifikasi tagihan pesanan.'], 400);
            }

            $billing = $response->json();
            if ((int)$billing['user_id'] !== (int)$user['user_id']) {
                return response()->json(['message' => 'Anda tidak memiliki hak untuk mengakses pembayaran ini.'], 403);
            }
        } catch (\Exception $e) {
            Log::error('Gagal memverifikasi kepemilikan pembayaran: ' . $e->getMessage());
            return response()->json(['message' => 'Kesalahan koneksi ke server utama.'], 500);
        }

        // Konfigurasi Midtrans
        Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        Config::$isProduction = false;
        Config::$isSanitized = true;
        Config::$is3ds = true;

        $paymentType = $request->payment_type;
        $bank = $request->bank;

        // Parameter Midtrans
        $params = [
            'transaction_details' => [
                'order_id' => $payment->external_id,
                'gross_amount' => (int) $payment->amount,
            ],
            'customer_details' => [
                'first_name' => $user['name'] ?? 'Customer',
                'email' => $user['email'] ?? 'customer@example.com',
                'phone' => $user['phone_number'] ?? '',
            ],
        ];

        if ($paymentType === 'bank_transfer') {
            if ($bank === 'mandiri') {
                $params['payment_type'] = 'echannel';
                $params['echannel'] = [
                    'bill_info1' => 'Payment for',
                    'bill_info2' => 'Order ' . $payment->external_id,
                ];
            } elseif ($bank === 'permata') {
                $params['payment_type'] = 'permata';
            } else {
                $params['payment_type'] = 'bank_transfer';
                $params['bank_transfer'] = [
                    'bank' => $bank,
                ];
            }
        } else {
            return response()->json(['message' => 'Payment method not supported'], 400);
        }

        // Buat Charge CoreApi
        try {
            $response = \Midtrans\CoreApi::charge($params);
            
            $payment->update([
                'midtrans_id' => $response->transaction_id ?? null,
                'status' => 'pending'
            ]);

            return response()->json([
                'status_code' => $response->status_code ?? null,
                'transaction_id' => $response->transaction_id ?? null,
                'order_id' => $response->order_id ?? null,
                'gross_amount' => $response->gross_amount ?? null,
                'payment_type' => $response->payment_type ?? null,
                // Virtual Account info
                'va_numbers' => $response->va_numbers ?? null,
                'bca_va_number' => $response->bca_va_number ?? null,
                'bni_va_number' => $response->bni_va_number ?? null,
                'permata_va_number' => $response->permata_va_number ?? null,
                // Mandiri info
                'bill_key' => $response->bill_key ?? null,
                'biller_code' => $response->biller_code ?? null,
                // E-wallet actions
                'actions' => $response->actions ?? null,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    /**
     * 3. Ambil Data Pembayaran Berdasarkan ID Pesanan
     */
    public function getByOrder($orderId)
    {
        $payment = Payment::where('order_id', $orderId)->first();
        if (!$payment) {
            return response()->json(['message' => 'No payment found for this order'], 404);
        }
        return response()->json($payment);
    }

    /**
     * 4. Callback Midtrans (Proses Status Pembayaran & Notifikasi Backend)
     */
    public function callback(Request $request)
    {
        $data = $request->all();
        Log::info('MIDTRANS CALLBACK RECEIVED:', $data);

        $externalId = $data['order_id'] ?? null;
        $statusCode = $data['status_code'] ?? '';
        $grossAmount = $data['gross_amount'] ?? '';
        $serverKey = env('MIDTRANS_SERVER_KEY');
        $signatureKey = $data['signature_key'] ?? '';

        // Langkah Keamanan 1: Verifikasi Tanda Tangan (Signature)
        $signature = hash('sha512', $externalId . $statusCode . $grossAmount . $serverKey);

        if ($signature !== $signatureKey) {
            Log::error('FRAUD ATTEMPT: Invalid Midtrans Signature', ['data' => $data]);
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        // Langkah Keamanan 2: Cari Pembayaran dan Verifikasi Jumlah Nominal
        $payment = Payment::where('external_id', $externalId)->first();
        if (!$payment) {
            return response()->json(['message' => 'Payment not found'], 404);
        }

        if ((int)$payment->amount !== (int)$grossAmount) {
            Log::error('FRAUD ATTEMPT: Amount Mismatch', [
                'expected' => $payment->amount,
                'received' => $grossAmount
            ]);
            return response()->json(['message' => 'Amount mismatch'], 400);
        }

        // Ambil data lengkap transaksi dari Midtrans
        $payment->midtrans_id = $data['transaction_id'] ?? null;
        $payment->payment_type = $data['payment_type'] ?? null;
        $payment->transaction_time = $data['transaction_time'] ?? null;

        $transactionStatus = $data['transaction_status'];
        $paymentStatus = null;

        if ($transactionStatus == 'settlement' || $transactionStatus == 'capture') {
            $payment->status = 'paid';
            $paymentStatus = 'settled';
        } elseif ($transactionStatus == 'pending') {
            $payment->status = 'pending';
        } elseif ($transactionStatus == 'deny' || $transactionStatus == 'expire' || $transactionStatus == 'cancel') {
            $payment->status = 'failed';
            // Jangan batalkan pesanan secara otomatis jika pembayaran gagal (biarkan pelanggan mencoba lagi)
        }

        $payment->save();

        // Kirim notifikasi ke backend utama secara asinkron
        if ($paymentStatus) {
            \App\Jobs\NotifyOrderServiceJob::dispatch(
                (int)$payment->order_id,
                $paymentStatus,
                (float)$payment->amount,
                (string)$payment->external_id
            );
        }

        return response()->json(['message' => 'Callback handled']);
    }
}