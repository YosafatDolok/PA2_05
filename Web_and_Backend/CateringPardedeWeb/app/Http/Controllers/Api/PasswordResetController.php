<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Mail\OtpMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class PasswordResetController extends Controller
{
    public function sendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Email tidak terdaftar.'], 422);
        }

        $email = $request->email;
        $user = User::where('email', $email)->first();
        
        // Generate 6-digit OTP
        $otp = rand(100000, 999999);

        // Store OTP in database
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            [
                'token' => $otp,
                'created_at' => Carbon::now()
            ]
        );

        // Send Email
        try {
            Mail::to($email)->send(new OtpMail($otp, $user->name));
            return response()->json([
                'success' => true,
                'message' => 'Kode OTP telah dikirim ke email Anda.'
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengirim email. Silakan coba lagi.'], 500);
        }
    }

    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'otp' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Data tidak valid.'], 422);
        }

        $resetData = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->where('token', $request->otp)
            ->first();

        if (!$resetData) {
            return response()->json(['message' => 'Kode OTP salah.'], 422);
        }

        // Check if expired (5 minutes)
        if (Carbon::parse($resetData->created_at)->addMinutes(5)->isPast()) {
            return response()->json(['message' => 'Kode OTP telah kadaluarsa.'], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'Kode OTP berhasil diverifikasi.'
        ]);
    }

    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'otp' => 'required|string|size:6',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validasi gagal: ' . implode(', ', $validator->errors()->all())], 422);
        }

        $resetData = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->where('token', $request->otp)
            ->first();

        if (!$resetData || Carbon::parse($resetData->created_at)->addMinutes(5)->isPast()) {
            return response()->json(['message' => 'Sesi reset password tidak valid atau telah kadaluarsa.'], 422);
        }

        // Update Password
        $user = User::where('email', $request->email)->first();
        $user->update([
            'password' => Hash::make($request->password)
        ]);

        // Delete used token
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kata sandi berhasil diperbarui.'
        ]);
    }
}
