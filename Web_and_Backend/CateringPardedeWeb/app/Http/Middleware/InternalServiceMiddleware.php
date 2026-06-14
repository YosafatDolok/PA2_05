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

        // 1. Validate Secret
        if (!$secret || $secret !== $expectedSecret) {
            return response()->json([
                'message' => 'Unauthorized service access. Invalid Secret.'
            ], 403);
        }

        // 2. Validate IP / Origin (Basic Whitelist)
        $allowedIps = ['127.0.0.1', '::1'];
        if ($envIp = env('PAYMENT_SERVICE_IP')) {
            $allowedIps[] = $envIp;
        }

        if (!in_array($request->ip(), $allowedIps) && env('APP_ENV') !== 'local') {
            // In production, enforce IP whitelisting strictly
            return response()->json([
                'message' => 'Unauthorized service origin IP.'
            ], 403);
        }

        return $next($request);
    }
}
