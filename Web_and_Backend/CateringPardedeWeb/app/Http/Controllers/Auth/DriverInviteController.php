<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Carbon\Carbon;

class DriverInviteController extends Controller
{
    public function showSetPasswordForm($token)
    {
        $user = User::where('invite_token', $token)
            ->where('invite_expires_at', '>', Carbon::now())
            ->firstOrFail();

        return view('auth.driver_set_password', compact('user', 'token'));
    }

    public function success()
    {
        return view('auth.driver_invite_success');
    }

    public function setPassword(Request $request, $token)
    {
        $user = User::where('invite_token', $token)
            ->where('invite_expires_at', '>', Carbon::now())
            ->firstOrFail();

        $request->validate([
            'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()->symbols()],
        ]);

        $user->update([
            'password' => Hash::make($request->password),
            'invite_token' => null,
            'invite_expires_at' => null,
        ]);

        return redirect()->route('driver.invite.success');
    }
}
