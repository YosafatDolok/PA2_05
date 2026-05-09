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

        // Update fields
        $user->update([
            'name' => $request->name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'profile_picture' => $user->profile_picture, // Ensure the path set above is persisted
        ]);

        // API response (for mobile reuse)
        if ($request->wantsJson()) {
            return response()->json([
                'message' => 'Profile updated',
                'user' => $user
            ]);
        }

        return back()->with('success', 'Profile updated successfully');
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
}