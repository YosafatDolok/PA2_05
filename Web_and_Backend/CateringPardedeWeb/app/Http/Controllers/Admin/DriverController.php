<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password as PasswordFacade;
use Illuminate\Validation\Rules\Password;
use App\Mail\DriverInviteMail;
use Illuminate\Support\Str;
use Carbon\Carbon;

class DriverController extends Controller
{
    public function index()
    {
        $drivers = User::where('role_id', 3)->latest()->get();
        return view('admin.drivers.index', compact('drivers'));
    }

    public function create()
    {
        return view('admin.drivers.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'phone_number' => 'nullable|string|max:20',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'password' => Hash::make(Str::random(16)), // Temporary random password
            'role_id' => 3, 
            'invite_token' => Str::random(40),
            'invite_expires_at' => Carbon::now()->addHours(24),
        ]);

        Mail::to($user->email)->send(new DriverInviteMail($user));

        return redirect()->route('drivers.index')->with('success', 'Undangan telah dikirim ke email Driver.');
    }

    public function edit(User $driver)
    {
        // Ensure we only edit drivers here
        if ($driver->role_id !== 3) abort(403);
        
        return view('admin.drivers.edit', compact('driver'));
    }

    public function update(Request $request, User $driver)
    {
        if ($driver->role_id !== 3) abort(403);

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,'.$driver->user_id.',user_id',
            'phone_number' => 'nullable|string|max:20',
        ]);

        $driver->update([
            'name' => $request->name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            // role_id is intentionally omitted here to prevent tampering
        ]);

        if ($request->filled('password')) {
            $request->validate([
                'password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()->symbols()]
            ]);
            $driver->update(['password' => Hash::make($request->password)]);
        }

        return redirect()->route('drivers.index')->with('success', 'Data Driver berhasil diperbarui.');
    }

    public function destroy(User $driver)
    {
        if ($driver->role_id !== 3) abort(403);
        
        $driver->delete();

        return redirect()->route('drivers.index')->with('success', 'Akun Driver telah dihapus.');
    }

    public function resendInvitation(User $driver)
    {
        if ($driver->role_id !== 3) abort(403);

        $driver->update([
            'invite_token' => Str::random(40),
            'invite_expires_at' => Carbon::now()->addHours(24),
        ]);

        Mail::to($driver->email)->send(new DriverInviteMail($driver));

        return back()->with('success', 'Tautan undangan baru telah dikirim.');
    }

    public function sendResetLink(User $driver)
    {
        if ($driver->role_id !== 3) abort(403);

        $status = PasswordFacade::sendResetLink(['email' => $driver->email]);

        return $status === PasswordFacade::RESET_LINK_SENT
            ? back()->with('success', 'Tautan reset password telah dikirim.')
            : back()->with('error', __($status));
    }
}
