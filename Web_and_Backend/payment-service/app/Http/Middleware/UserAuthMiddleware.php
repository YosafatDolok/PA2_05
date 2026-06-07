<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

class UserAuthMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->header('Authorization');
        \Illuminate\Support\Facades\Log::debug('UserAuthMiddleware: Header Authorization present: ' . ($token ? 'YES' : 'NO') . ', value length: ' . ($token ? strlen($token) : 0));

        if (!$token) {
            return response()->json([
                'message' => 'Token otentikasi tidak ditemukan.'
            ], 401);
        }

        // Panggil endpoint /api/user di Backend utama untuk validasi token
        try {
            $mainAppUrl = env('MAIN_APP_URL', 'http://localhost:8000');
            $targetUrl = $mainAppUrl . '/api/user';
            \Illuminate\Support\Facades\Log::debug('UserAuthMiddleware: Sending request to ' . $targetUrl);
            
            $response = Http::withHeaders([
                'Authorization' => $token,
                'Accept' => 'application/json'
            ])->timeout(3)->get($targetUrl);

            \Illuminate\Support\Facades\Log::debug('UserAuthMiddleware: Response code: ' . $response->status() . ', body: ' . $response->body());

            if ($response->successful()) {
                $userProfile = $response->json();
                // Simpan profil user yang terautentikasi ke dalam atribut request
                $request->attributes->set('authenticated_user', $userProfile);
                return $next($request);
            }
        } catch (\Exception $e) {
            // Log error
            \Illuminate\Support\Facades\Log::error('Auth Introspection failed: ' . $e->getMessage());
        }

        return response()->json([
            'message' => 'Sesi tidak valid atau telah berakhir.'
        ], 401);
    }
}
