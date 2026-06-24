<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CheckoutTokenTest extends TestCase
{
    use RefreshDatabase;

    protected $pelanggan1;
    protected $pelanggan2;
    protected $pesanan1;
    protected $pesanan2;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Mengisi database (role, status, dll.)
        $this->seed(DatabaseSeeder::class);

        // Mengambil atau membuat pengguna
        $this->pelanggan1 = User::factory()->create(['role_id' => 2]); // Role Pelanggan
        $this->pelanggan2 = User::factory()->create(['role_id' => 2]);

        // Membuat pesanan
        $this->pesanan1 = Order::create([
            'user_id' => $this->pelanggan1->user_id,
            'event_address' => 'Jl. Pardede No. 1',
            'event_latitude' => 2.437190,
            'event_longitude' => 99.157618,
            'status_id' => 1, // Pending
            'final_price' => 200000.00,
            'is_price_confirmed' => true,
            'order_date' => now(),
            'event_date' => now()->addDays(7),
            'people' => 50
        ]);

        $this->pesanan2 = Order::create([
            'user_id' => $this->pelanggan2->user_id,
            'event_address' => 'Jl. Dolok No. 2',
            'event_latitude' => 2.437190,
            'event_longitude' => 99.157618,
            'status_id' => 1, // Pending
            'final_price' => 300000.00,
            'is_price_confirmed' => true,
            'order_date' => now(),
            'event_date' => now()->addDays(7),
            'people' => 75
        ]);
    }

    /** @test */
    public function tamu_tidak_bisa_membuat_token_checkout()
    {
        $response = $this->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(401);
    }

    /** @test */
    public function pemilik_bisa_membuat_token_checkout_yang_valid()
    {
        $response = $this->actingAs($this->pelanggan1, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'checkout_token',
            'min_payment_allowed',
            'remaining_balance'
        ]);

        $token = $response->json('checkout_token');
        $this->assertNotEmpty($token);
        
        // Memastikan token terdiri dari payload.signature
        $parts = explode('.', $token);
        $this->assertCount(2, $parts);
    }

    /** @test */
    public function bukan_pemilik_tidak_bisa_membuat_token_checkout()
    {
        $response = $this->actingAs($this->pelanggan2, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(403);
        $response->assertJson([
            'message' => 'Anda tidak memiliki akses ke pesanan ini.'
        ]);
    }

    /** @test */
    public function pemilik_tidak_bisa_membuat_token_untuk_pesanan_yang_sudah_lunas()
    {
        // Melunasi pesanan 1
        $this->pesanan1->total_paid = 200000.00;
        $this->pesanan1->save();

        $response = $this->actingAs($this->pelanggan1, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(400);
        $response->assertJson([
            'message' => 'Pesanan ini sudah lunas.'
        ]);
    }

    /** @test */
    public function pemilik_tidak_bisa_membuat_token_jika_harga_final_belum_ditentukan()
    {
        // Set harga final menjadi 0
        $this->pesanan1->final_price = 0.00;
        $this->pesanan1->save();

        $response = $this->actingAs($this->pelanggan1, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(400);
        $response->assertJson([
            'message' => 'Harga final pesanan belum ditentukan oleh Admin.'
        ]);
    }

    /** @test */
    public function token_checkout_memuat_pilihan_allowed_amounts_dp_dan_lunas_saat_belum_bayar()
    {
        $response = $this->actingAs($this->pelanggan1, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(200);
        $response->assertJsonFragment([
            'allowed_amounts' => [
                'dp' => 100000.00,
                'full' => 200000.00
            ]
        ]);
    }

    /** @test */
    public function token_checkout_hanya_memuat_pilihan_lunas_setelah_membayar_dp()
    {
        // Menandai total paid sudah setengah jalan (DP 50%)
        $this->pesanan1->total_paid = 100000.00;
        $this->pesanan1->save();

        $response = $this->actingAs($this->pelanggan1, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(200);
        $response->assertJsonFragment([
            'allowed_amounts' => [
                'full' => 100000.00
            ]
        ]);
    }

    /** @test */
    public function pemilik_tidak_bisa_membuat_token_checkout_jika_harga_belum_dikonfirmasi()
    {
        // Set is_price_confirmed ke false
        $this->pesanan1->is_price_confirmed = false;
        $this->pesanan1->save();

        $response = $this->actingAs($this->pelanggan1, 'sanctum')
            ->getJson("/api/orders/{$this->pesanan1->order_id}/checkout-token");

        $response->assertStatus(400);
        $response->assertJson([
            'message' => 'Harga pesanan belum dikonfirmasi oleh Admin.'
        ]);
    }
}
