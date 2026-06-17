<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class RoleMiddleware
{
    /**
     * Role ID
     *  1 = admin
     *  2 = user (customer)
     *  3 = driver
     */
    private const ROLE_MAP = [
        'admin'  => 1,
        'user'   => 2,
        'driver' => 3,
    ];

    public function handle(Request $request, Closure $next, string $role): Response
    {
        if (!Auth::check()) {
            return redirect('/login');
        }

        $requiredRoleId = self::ROLE_MAP[$role] ?? null;

        if ($requiredRoleId !== null && Auth::user()->role_id === $requiredRoleId) {
            return $next($request);
        }

        abort(403, 'Akses ditolak. Anda tidak memiliki izin untuk halaman ini.');
    }
}
