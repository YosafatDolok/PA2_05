<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\DeliveryMessage;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Event;
use App\Events\DeliveryMessageSent;
use App\Events\DeliveryMessageDeleted;

class DeliveryChatTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;
    protected $driver;
    protected $otherCustomer;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->seed(DatabaseSeeder::class);

        // Ambil user dari database seeder
        $this->admin = User::where('role_id', 1)->first();
        $this->customer = User::where('role_id', 2)->first();
        $this->customer->update(['fcm_token' => 'customer_fake_fcm_token']);
        $this->driver = User::where('role_id', 3)->first();
        $this->driver->update(['fcm_token' => 'driver_fake_fcm_token']);
        
        // Buat customer lain yang tidak terkait dengan order
        $this->otherCustomer = User::factory()->create(['role_id' => 2]);

        // Buat pesanan dan tugaskan ke driver
        $this->order = Order::create([
            'user_id' => $this->customer->user_id,
            'driver_id' => $this->driver->user_id,
            'event_address' => 'Jl. Danau Toba No. 70',
            'event_latitude' => 2.583,
            'event_longitude' => 98.817,
            'status_id' => 3, // On Process
            'final_price' => 500000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(3),
            'people' => 50,
            'total_paid' => 250000.00
        ]);
    }

    /** @test */
    public function pengguna_terkait_bisa_mengambil_riwayat_pesan_pengiriman()
    {
        // Buat pesan pengiriman buatan
        DeliveryMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->driver->user_id,
            'message' => 'Saya sedang bersiap menuju lokasi pengiriman.',
            'is_read' => false
        ]);

        // Akses riwayat sebagai pelanggan
        $response = $this->actingAs($this->customer, 'sanctum')
            ->getJson("/api/orders/{$this->order->order_id}/delivery-messages");

        $response->assertStatus(200);
        $response->assertJsonCount(1);
        $response->assertJsonPath('0.message', 'Saya sedang bersiap menuju lokasi pengiriman.');

        // Akses riwayat sebagai driver
        $responseDriver = $this->actingAs($this->driver, 'sanctum')
            ->getJson("/api/orders/{$this->order->order_id}/delivery-messages");

        $responseDriver->assertStatus(200);
    }

    /** @test */
    public function pengguna_terkait_bisa_mengirim_pesan_pengiriman()
    {
        Bus::fake();
        Event::fake();

        // Kirim pesan sebagai driver ke pelanggan
        $response = $this->actingAs($this->driver, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/delivery-messages", [
                'message' => 'Makanan sudah siap diantar.'
            ]);

        $response->assertStatus(201);
        $response->assertJsonPath('message', 'Makanan sudah siap diantar.');

        $this->assertDatabaseHas('delivery_messages', [
            'order_id' => $this->order->order_id,
            'sender_id' => $this->driver->user_id,
            'message' => 'Makanan sudah siap diantar.'
        ]);

        // Pastikan job push notification didispatch ke pelanggan
        Bus::assertDispatched(\App\Jobs\SendPushNotification::class);
        
        // Pastikan event DeliveryMessageSent dibroadcast
        Event::assertDispatched(DeliveryMessageSent::class);
    }

    /** @test */
    public function pengguna_luar_tidak_bisa_mengirim_atau_membaca_pesan_pengiriman()
    {
        // Coba ambil pesan sebagai orang luar
        $responseGet = $this->actingAs($this->otherCustomer, 'sanctum')
            ->getJson("/api/orders/{$this->order->order_id}/delivery-messages");

        $responseGet->assertStatus(403);

        // Coba kirim pesan sebagai orang luar
        $responsePost = $this->actingAs($this->otherCustomer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/delivery-messages", [
                'message' => 'Pesan penyelundup'
            ]);

        $responsePost->assertStatus(403);
    }

    /** @test */
    public function pengirim_bisa_menghapus_pesan_pengiriman_sendiri_yang_belum_dibaca()
    {
        Event::fake();

        // Buat pesan belum dibaca
        $message = DeliveryMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->customer->user_id,
            'message' => 'Tolong antar ke pintu belakang saja',
            'is_read' => false
        ]);

        // Hapus pesan
        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/delivery-messages/{$message->message_id}");

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);

        // Pastikan terhapus secara soft delete
        $this->assertSoftDeleted('delivery_messages', [
            'message_id' => $message->message_id
        ]);

        // Pastikan event DeliveryMessageDeleted dibroadcast
        Event::assertDispatched(DeliveryMessageDeleted::class);
    }

    /** @test */
    public function pengirim_tidak_bisa_menghapus_pesan_pengiriman_yang_sudah_dibaca()
    {
        // Buat pesan sudah dibaca
        $message = DeliveryMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->customer->user_id,
            'message' => 'Pesan penting sekali',
            'is_read' => true
        ]);

        // Coba hapus
        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/delivery-messages/{$message->message_id}");

        $response->assertStatus(403);
        $response->assertJsonPath('message', 'Pesan sudah dibaca dan tidak dapat dihapus.');
    }

    /** @test */
    public function pengguna_tidak_bisa_menghapus_pesan_pengiriman_orang_lain()
    {
        // Buat pesan dari driver
        $message = DeliveryMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->driver->user_id,
            'message' => 'Pesan dari Driver',
            'is_read' => false
        ]);

        // Pelanggan mencoba menghapus pesan driver
        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/delivery-messages/{$message->message_id}");

        $response->assertStatus(403);
        $response->assertJsonPath('message', 'Anda hanya dapat menghapus pesan Anda sendiri.');
    }

    /** @test */
    public function penerima_bisa_menandai_pesan_pengiriman_sebagai_telah_dibaca()
    {
        // Buat pesan belum dibaca dari driver
        $message = DeliveryMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->driver->user_id,
            'message' => 'Pesan driver belum dibaca',
            'is_read' => false
        ]);

        // Pelanggan menandai pesan sebagai telah dibaca
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/delivery-messages/read");

        $response->assertStatus(200);

        // Verifikasi di database
        $this->assertDatabaseHas('delivery_messages', [
            'message_id' => $message->message_id,
            'is_read' => true
        ]);
    }
}
