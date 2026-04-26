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
            'name' => 'required|string',
            'email' => 'required|email|unique:users,email,' . $user->user_id . ',user_id',
            'phone_number' => 'nullable|string',
            'profile_picture' => 'nullable|image|max:2048'
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
}