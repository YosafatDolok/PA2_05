<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function edit()
    {
        $user = auth()->user();
        return view('admin.profile.edit', compact('user'));
    }

    public function update(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->user_id . ',user_id',
            'phone_number' => 'nullable|numeric|digits_between:10,15',
            'profile_picture' => 'nullable|image|max:2048'
        ], [
            'name.required' => 'Nama lengkap wajib diisi.',
            'email.required' => 'Email wajib diisi.',
            'email.email' => 'Format email tidak valid.',
            'email.unique' => 'Email ini sudah digunakan oleh akun lain.',
            'phone_number.numeric' => 'Nomor telepon harus berupa angka.',
            'phone_number.digits_between' => 'Nomor telepon harus berjumlah 10 hingga 15 digit.',
            'profile_picture.max' => 'Ukuran foto profil maksimal 2MB.',
            'profile_picture.image' => 'File harus berupa gambar.',
        ]);

        // Handle image upload
        if ($request->hasFile('profile_picture')) {

            // Delete old image
            if ($user->profile_picture) {
                Storage::disk('public')->delete($user->profile_picture);
            }

            // Save new image
            $user->profile_picture = $request
                ->file('profile_picture')
                ->store('profiles', 'public');
        }

        // Check if email or phone changed
        $emailChanged = $request->email !== $user->email;
        $phoneChanged = $request->phone_number !== $user->phone_number;

        if ($request->wantsJson() && ($emailChanged || $phoneChanged)) {
            // Save to pending_profile_updates
            $otp = (string) rand(100000, 999999);
            $expiresAt = \Carbon\Carbon::now()->addMinutes(5);

            \Illuminate\Support\Facades\DB::table('pending_profile_updates')->updateOrInsert(
                ['user_id' => $user->user_id],
                [
                    'new_email' => $emailChanged ? $request->email : null,
                    'new_phone_number' => $phoneChanged ? $request->phone_number : null,
                    'otp_code' => $otp,
                    'expires_at' => $expiresAt,
                    'created_at' => \Carbon\Carbon::now(),
                    'updated_at' => \Carbon\Carbon::now(),
                ]
            );

            // Send OTP to the NEW email if email changed, otherwise to CURRENT email
            $targetEmail = $emailChanged ? $request->email : $user->email;
            
            try {
                \Illuminate\Support\Facades\Mail::to($targetEmail)->send(new \App\Mail\ProfileUpdateOtpMail($otp, $user->name));
                
                // Update name and profile picture immediately
                $user->update([
                    'name' => $request->name,
                    'profile_picture' => $user->profile_picture,
                ]);

                return response()->json([
                    'requires_otp' => true,
                    'target_email' => $targetEmail,
                    'message' => 'Kode verifikasi telah dikirim ke email Anda.'
                ]);
            } catch (\Exception $e) {
                return response()->json(['message' => 'Gagal mengirim email verifikasi.'], 500);
            }
        }

        // Handle web update requiring password confirmation if email/phone changed
        if (!$request->wantsJson() && ($emailChanged || $phoneChanged)) {
            session([
                'pending_email' => $request->email,
                'pending_phone' => $request->phone_number,
                'requires_password_confirmation' => true
            ]);
            $user->update(['name' => $request->name, 'profile_picture' => $user->profile_picture]);
            return redirect()->route('profile.edit')->with('info', 'Harap masukkan password Anda untuk mengonfirmasi perubahan.');
        }

        // Normal update (only name/picture changed or mobile request)
        $user->update([
            'name' => $request->name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'profile_picture' => $user->profile_picture, 
        ]);

        return redirect()->route('profile.edit')->with('success', 'Profil berhasil diperbarui.');
    }

    public function confirmUpdate(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'current_password' => 'required',
        ], [
            'current_password.required' => 'Password saat ini wajib diisi.',
        ]);

        if (!\Illuminate\Support\Facades\Hash::check($request->current_password, $user->password)) {
            return back()->with('error', 'Password yang Anda masukkan salah. Perubahan profil dibatalkan.');
        }

        // Apply pending changes from session
        $pendingEmail = session('pending_email');
        $pendingPhone = session('pending_phone');

        if ($pendingEmail || $pendingPhone) {
            $user->update([
                'email' => $pendingEmail ?? $user->email,
                'phone_number' => $pendingPhone ?? $user->phone_number,
            ]);

            // Clear session data
            session()->forget(['pending_email', 'pending_phone', 'requires_password_confirmation']);

            return redirect()->route('profile.edit')->with('success', 'Profil berhasil diperbarui dengan aman.');
        }

        return redirect()->route('profile.edit')->with('error', 'Tidak ada perubahan yang tertunda.');
    }

    public function verifyProfileOtp(Request $request)
    {
        $request->validate([
            'otp' => 'required|string|size:6',
        ]);

        $user = auth()->user();

        $pending = \Illuminate\Support\Facades\DB::table('pending_profile_updates')
            ->where('user_id', $user->user_id)
            ->where('otp_code', $request->otp)
            ->first();

        if (!$pending) {
            return response()->json(['message' => 'Kode verifikasi salah.'], 422);
        }

        if (\Carbon\Carbon::parse($pending->expires_at)->isPast()) {
            return response()->json(['message' => 'Kode verifikasi telah kadaluarsa.'], 422);
        }

        // Apply the updates
        $updates = [];
        if ($pending->new_email) $updates['email'] = $pending->new_email;
        if ($pending->new_phone_number) $updates['phone_number'] = $pending->new_phone_number;

        $user->update($updates);

        // Delete pending request
        \Illuminate\Support\Facades\DB::table('pending_profile_updates')->where('user_id', $user->user_id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Profil berhasil diperbarui.',
            'user' => $user
        ]);
    }

    public function resendProfileOtp(Request $request)
    {
        $user = auth()->user();

        $pending = \Illuminate\Support\Facades\DB::table('pending_profile_updates')
            ->where('user_id', $user->user_id)
            ->first();

        if (!$pending) {
            return response()->json(['message' => 'Tidak ada permintaan perubahan profil yang tertunda.'], 404);
        }

        $rateLimitKey = 'otp-send-profile:' . $user->user_id;

        if (\Illuminate\Support\Facades\RateLimiter::tooManyAttempts($rateLimitKey, 3)) {
            $seconds = \Illuminate\Support\Facades\RateLimiter::availableIn($rateLimitKey);
            $minutes = ceil($seconds / 60);
            return response()->json([
                'message' => "Terlalu banyak permintaan. Silakan coba lagi dalam {$minutes} menit."
            ], 429);
        }

        \Illuminate\Support\Facades\RateLimiter::hit($rateLimitKey, 300);

        $otp = (string) rand(100000, 999999);

        \Illuminate\Support\Facades\DB::table('pending_profile_updates')
            ->where('user_id', $user->user_id)
            ->update([
                'otp_code' => $otp,
                'expires_at' => \Carbon\Carbon::now()->addMinutes(5),
                'updated_at' => \Carbon\Carbon::now(),
            ]);

        $targetEmail = $pending->new_email ?: $user->email;

        try {
            \Illuminate\Support\Facades\Mail::to($targetEmail)->send(new \App\Mail\ProfileUpdateOtpMail($otp, $user->name));
            return response()->json([
                'success' => true,
                'message' => 'Kode verifikasi baru telah dikirim ke email Anda.'
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengirim email verifikasi.'], 500);
        }
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $user = auth()->user();
        \Log::info('FCM Token Update Request', [
            'user_id' => $user->user_id, 
            'token' => $request->fcm_token
        ]);
        
        $user->update(['fcm_token' => $request->fcm_token]);

        return response()->json(['message' => 'FCM token updated successfully']);
    }

    public function updatePassword(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'current_password' => ['required', function ($attribute, $value, $fail) use ($user) {
                if (!\Hash::check($value, $user->password)) {
                    $fail('Password saat ini tidak cocok dengan data kami.');
                }
            }],
            'new_password' => 'required|string|min:8|confirmed',
        ], [
            'current_password.required' => 'Password saat ini wajib diisi.',
            'new_password.required' => 'Password baru wajib diisi.',
            'new_password.min' => 'Password baru minimal harus terdiri dari 8 karakter.',
            'new_password.confirmed' => 'Konfirmasi password baru tidak cocok.',
        ]);

        $user->update([
            'password' => \Hash::make($request->new_password)
        ]);

        if ($request->wantsJson()) {
            return response()->json([
                'message' => 'Password berhasil diperbarui!'
            ]);
        }

        return back()->with('password_success', 'Password updated successfully!');
    }
}