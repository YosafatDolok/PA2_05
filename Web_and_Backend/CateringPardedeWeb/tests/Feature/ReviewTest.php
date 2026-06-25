<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\Review;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ReviewTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;
    protected $otherCustomer;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        $this->customer = User::where('role_id', 2)->first();
        $this->otherCustomer = User::factory()->create(['role_id' => 2]);

        // Buat pesanan default (status_id = 4 (Delivered) agar bisa diulas)
        $this->order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Danau Toba No. 10',
            'event_latitude' => 2.583,
            'event_longitude' => 98.817,
            'status_id' => 4, // Delivered
            'final_price' => 300000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(5),
            'people' => 30,
            'total_paid' => 300000.00
        ]);
    }

    /** @test */
    public function pelanggan_bisa_membuat_ulasan_untuk_pesanan_yang_telah_selesai()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/review", [
                'rating' => 5,
                'comment' => 'Makanannya sangat enak dan pelayanannya memuaskan!'
            ]);

        $response->assertStatus(201);
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('message', 'Terima kasih atas ulasan Anda!');

        $this->assertDatabaseHas('reviews', [
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 5,
            'comment' => 'Makanannya sangat enak dan pelayanannya memuaskan!'
        ]);
    }

    /** @test */
    public function pelanggan_tidak_bisa_mengulas_pesanan_yang_belum_selesai()
    {
        // Ubah status pesanan menjadi Pending (status_id = 1)
        $this->order->update(['status_id' => 1]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/review", [
                'rating' => 4,
                'comment' => 'Pesanan belum diantar tapi dicoba diulas'
            ]);

        $response->assertStatus(400);
        $response->assertJsonPath('success', false);
        $response->assertJsonPath('message', 'Anda hanya dapat memberikan ulasan untuk pesanan yang sudah selesai');
    }

    /** @test */
    public function pelanggan_tidak_bisa_mengulas_pesanan_orang_lain()
    {
        $response = $this->actingAs($this->otherCustomer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/review", [
                'rating' => 4,
                'comment' => 'Mencoba mengulas pesanan orang lain'
            ]);

        // Karena model mencari pesanan milik user login, harusnya return 404 (tidak ditemukan)
        $response->assertStatus(404);
        $response->assertJsonPath('success', false);
        $response->assertJsonPath('message', 'Pesanan tidak ditemukan');
    }

    /** @test */
    public function pelanggan_tidak_bisa_mengulas_pesanan_yang_sama_dua_kali()
    {
        // Buat ulasan pertama langsung di database
        Review::create([
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 5,
            'comment' => 'Ulasan pertama',
            'is_visible' => true
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/review", [
                'rating' => 3,
                'comment' => 'Ulasan kedua'
            ]);

        $response->assertStatus(400);
        $response->assertJsonPath('message', 'Anda sudah memberikan ulasan untuk pesanan ini');
    }

    /** @test */
    public function pelanggan_bisa_memperbarui_ulasannya()
    {
        // Buat ulasan awal
        $review = Review::create([
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 4,
            'comment' => 'Bagus saja',
            'is_visible' => true
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->patchJson("/api/orders/{$this->order->order_id}/review", [
                'rating' => 5,
                'comment' => 'Sangat bagus setelah diperbarui!'
            ]);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('message', 'Ulasan berhasil diperbarui');

        $this->assertDatabaseHas('reviews', [
            'review_id' => $review->review_id,
            'rating' => 5,
            'comment' => 'Sangat bagus setelah diperbarui!'
        ]);
    }

    /** @test */
    public function pelanggan_bisa_menghapus_ulasannya()
    {
        // Buat ulasan awal
        $review = Review::create([
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 4,
            'comment' => 'Komentar yang mau dihapus',
            'is_visible' => true
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/review");

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('message', 'Ulasan berhasil dihapus');

        $this->assertDatabaseMissing('reviews', [
            'review_id' => $review->review_id
        ]);
    }

    /** @test */
    public function pengunjung_bisa_mengambil_ulasan_publik_terbaru()
    {
        // Buat ulasan terlihat
        Review::create([
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 5,
            'comment' => 'Ulasan publik terlihat',
            'is_visible' => true
        ]);

        // Buat pesanan lain untuk ulasan tersembunyi
        $otherOrder = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Danau Toba No. 12',
            'event_latitude' => 2.583,
            'event_longitude' => 98.817,
            'status_id' => 4,
            'final_price' => 100000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(5),
            'people' => 10,
            'total_paid' => 100000.00
        ]);

        Review::create([
            'order_id' => $otherOrder->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 1,
            'comment' => 'Ulasan tersembunyi admin',
            'is_visible' => false
        ]);

        // Lakukan request publik tanpa login
        $response = $this->getJson("/api/reviews");

        $response->assertStatus(200);
        $response->assertJsonCount(1, 'data'); // Hanya ulasan terlihat yang dikembalikan
        $response->assertJsonPath('data.0.comment', 'Ulasan publik terlihat');
    }

    /** @test */
    public function admin_bisa_mengubah_visibilitas_ulasan()
    {
        $review = Review::create([
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 5,
            'comment' => 'Ulasan tersembunyi',
            'is_visible' => true
        ]);

        // Jalankan toggle visibility sebagai Admin
        $response = $this->actingAs($this->admin)
            ->patch("/admin/reviews/{$review->review_id}/toggle");

        $response->assertStatus(302); // Redirect back

        $this->assertDatabaseHas('reviews', [
            'review_id' => $review->review_id,
            'is_visible' => false
        ]);
    }

    /** @test */
    public function bukan_admin_tidak_bisa_mengubah_visibilitas_ulasan()
    {
        $review = Review::create([
            'order_id' => $this->order->order_id,
            'user_id' => $this->customer->user_id,
            'rating' => 5,
            'comment' => 'Ulasan tersembunyi',
            'is_visible' => true
        ]);

        // Coba jalankan toggle visibility sebagai Customer biasa
        $response = $this->actingAs($this->customer)
            ->patch("/admin/reviews/{$review->review_id}/toggle");

        $response->assertStatus(403); // Terblokir oleh middleware 'role:admin'
    }
}
