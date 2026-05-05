<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class InternalServiceMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $secret = $request->header('X-Internal-Secret');
        $expectedSecret = config('services.internal_key');

        if (!$secret || $secret !== $expectedSecret) {
            return response()->json([
                'message' => 'Unauthorized service access.'
            ], 403);
        }

        return $next($request);
    }
}
