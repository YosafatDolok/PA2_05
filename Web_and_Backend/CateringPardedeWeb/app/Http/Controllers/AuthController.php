<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Models\User;
use App\Models\Role;

class AuthController extends Controller
{
    public function requestRegistrationOtp(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|unique:users',
            'password' => 'required|string|min:8',
        ]);

        $otp = rand(100000, 999999);

        \Illuminate\Support\Facades\DB::table('pending_registrations')->updateOrInsert(
            ['email' => $validated['email']],
            [
                'name' => $validated['name'],
                'password' => Hash::make($validated['password']),
                'otp_code' => $otp,
                'expires_at' => \Carbon\Carbon::now()->addMinutes(5),
                'created_at' => \Carbon\Carbon::now(),
                'updated_at' => \Carbon\Carbon::now(),
            ]
        );

        try {
            \Illuminate\Support\Facades\Mail::to($validated['email'])->send(new \App\Mail\RegistrationOtpMail($otp, $validated['name']));
            return response()->json([
                'success' => true,
                'message' => 'Kode verifikasi telah dikirim ke email Anda.'
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Gagal mengirim email verifikasi.'], 500);
        }
    }

    public function register(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'otp' => 'required|string|size:6',
        ]);

        $pending = \Illuminate\Support\Facades\DB::table('pending_registrations')
            ->where('email', $validated['email'])
            ->where('otp_code', $validated['otp'])
            ->first();

        if (!$pending) {
            return response()->json(['message' => 'Kode verifikasi salah.'], 422);
        }

        if (\Carbon\Carbon::parse($pending->expires_at)->isPast()) {
            return response()->json(['message' => 'Kode verifikasi telah kadaluarsa.'], 422);
        }

        $userRole = Role::where('name', 'user')->first();

        if (!$userRole) {
            return response()->json(['message' => 'Role user tidak ditemukan'], 500);
        }

        $user = User::create([
            'name' => $pending->name,
            'email' => $pending->email,
            'password' => $pending->password,
            'role_id' => $userRole->id,
        ]);

        // Delete pending registration
        \Illuminate\Support\Facades\DB::table('pending_registrations')->where('email', $pending->email)->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registrasi berhasil',
            'user' => $user->load('role'),
            'token' => $token
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Password atau email salah'], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'token' => $token, 
            'user' => $user->load('role')
        ]);
    }

    public function user(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Not Authenticated'], 401);
        }

        return response()->json($user->load('role'));
    }

    public function logout(Request $request)
    {
        // Revoke the specific token used for the request
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Keluar berhasil']);
    }
}