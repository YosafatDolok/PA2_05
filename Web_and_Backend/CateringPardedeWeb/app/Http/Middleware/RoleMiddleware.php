<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, $role): Response
    {
        if (!Auth::check()) {
            return redirect('/login');
        }

        $user = Auth::user();

        if ($role === 'admin' && $user->role_id === 1) {
            return $next($request);
        }

        if ($role === 'user' && $user->role_id === 2) {
            return $next($request);
        }

        return redirect('/login')->with('error', 'Akses ditolak.');
    }
}
