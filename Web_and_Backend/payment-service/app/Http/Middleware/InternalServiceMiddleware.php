<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class InternalServiceMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $secret = $request->header('X-Internal-Secret');
        $expectedSecret = env('INTERNAL_SERVICE_KEY', 'default_secret_key');

        if (!$secret || $secret !== $expectedSecret) {
            return response()->json([
                'message' => 'Unauthorized service access.'
            ], 403);
        }

        return $next($request);
    }
}
