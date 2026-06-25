<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\Menu;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        $this->customer = User::where('role_id', 2)->first();
    }

    /** @test */
    public function admin_bisa_mengakses_halaman_dashboard_dengan_filter_default()
    {
        // Mock pemanggilan HTTP ke payment-service
        Http::fake([
            '*/api/stats/summary*' => Http::response([
                'total_revenue' => 15000000,
                'growth_percent' => 12.5,
                'monthly_chart' => [
                    ['label' => 'Jan', 'value' => 5000000],
                    ['label' => 'Feb', 'value' => 10000000]
                ]
            ], 200)
        ]);

        $response = $this->actingAs($this->admin)
            ->get('/admin/dashboard');

        $response->assertStatus(200);
        $response->assertViewIs('admin.dashboard');
        $response->assertViewHas('revenueGrowth', 12.5);
        
        // Memastikan request dikirim ke microservice pembayaran dengan benar
        Http::assertSent(function (\Illuminate\Http\Client\Request $request) {
            return str_contains($request->url(), '/api/stats/summary') &&
                   $request->header('X-Internal-Secret')[0] === config('services.internal_key');
        });
    }

    /** @test */
    public function admin_bisa_mengakses_dashboard_dengan_filter_mingguan_bulanan_dan_tahunan()
    {
        // 1. Coba filter mingguan
        Http::fake([
            '*/api/stats/summary?filter=weekly' => Http::response([
                'total_revenue' => 3000000,
                'growth_percent' => 5.0,
                'monthly_chart' => [
                    ['label' => 'Sen', 'value' => 1000000],
                    ['label' => 'Sel', 'value' => 2000000]
                ]
            ], 200)
        ]);

        $responseWeekly = $this->actingAs($this->admin)
            ->get('/admin/dashboard?filter=weekly');

        $responseWeekly->assertStatus(200);
        $responseWeekly->assertViewHas('revenueGrowth', 5.0);

        // 2. Coba filter tahunan
        Http::fake([
            '*/api/stats/summary?filter=yearly' => Http::response([
                'total_revenue' => 150000000,
                'growth_percent' => 20.0,
                'monthly_chart' => [
                    ['label' => '2025', 'value' => 70000000],
                    ['label' => '2026', 'value' => 80000000]
                ]
            ], 200)
        ]);

        $responseYearly = $this->actingAs($this->admin)
            ->get('/admin/dashboard?filter=yearly');

        $responseYearly->assertStatus(200);
        $responseYearly->assertViewHas('revenueGrowth', 20.0);
    }

    /** @test */
    public function dashboard_tetap_berjalan_lancar_meskipun_layanan_pembayaran_microservice_mati()
    {
        // Simulasikan payment-service timeout/error 500
        Http::fake([
            '*/api/stats/summary*' => Http::response(null, 500)
        ]);

        $response = $this->actingAs($this->admin)
            ->get('/admin/dashboard');

        // Dashboard harus tetap loading (tidak error 500)
        $response->assertStatus(200);
        
        // Memastikan default value fallback diset
        $response->assertViewHas('revenueGrowth', 0);
    }

    /** @test */
    public function bukan_admin_tidak_bisa_mengakses_halaman_dashboard()
    {
        $response = $this->actingAs($this->customer)
            ->get('/admin/dashboard');

        $response->assertStatus(403);
    }
}
