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

        // 1.Validasi secret key
        if (!$secret || $secret !== $expectedSecret) {
            return response()->json([
                'message' => 'Unauthorized service access. Invalid Secret.'
            ], 403);
        }

        //Validasi alamat IP atau asal layanan
        $allowedIps = ['127.0.0.1', '::1'];
        if ($envIp = env('PAYMENT_SERVICE_IP')) {
            $allowedIps[] = $envIp;
        }

        if (!in_array($request->ip(), $allowedIps) && env('APP_ENV') !== 'local') {
            //production, pembatasan alamat IP diterapkan secara ketat
            return response()->json([
                'message' => 'Unauthorized service origin IP.'
            ], 403);
        }

        return $next($request);
    }
}
