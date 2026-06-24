<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\OrderMessage;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Event;
use App\Events\MessageSent;
use App\Events\MessageDeleted;

class ChatMessageTest extends TestCase
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
        $this->admin->update(['fcm_token' => 'admin_fake_fcm_token']);
        $this->customer = User::where('role_id', 2)->first();
        $this->otherCustomer = User::factory()->create(['role_id' => 2]);

        $this->order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Pardede No. 1',
            'event_latitude' => 2.437190,
            'event_longitude' => 99.157618,
            'status_id' => 1, // Pending
            'final_price' => 100000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(7),
            'people' => 10,
            'total_paid' => 0.00
        ]);
    }

    /** @test */
    public function pengguna_terkait_bisa_mengirim_pesan_chat()
    {
        Bus::fake();
        Event::fake();

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/messages", [
                'message' => 'Halo Admin, kateringnya bisa tambah porsi?'
            ]);

        $response->assertStatus(201);
        $response->assertJsonPath('message', 'Halo Admin, kateringnya bisa tambah porsi?');

        $this->assertDatabaseHas('order_messages', [
            'order_id' => $this->order->order_id,
            'sender_id' => $this->customer->user_id,
            'message' => 'Halo Admin, kateringnya bisa tambah porsi?'
        ]);

        // Pastikan job push notification didispatch (karena dikirim ke admin)
        Bus::assertDispatched(\App\Jobs\SendPushNotification::class);
        
        // Pastikan event MessageSent dibroadcast
        Event::assertDispatched(MessageSent::class);
    }

    /** @test */
    public function pengguna_tidak_bisa_mengirim_pesan_pada_pesanan_orang_lain()
    {
        $response = $this->actingAs($this->otherCustomer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/messages", [
                'message' => 'Halo, ini pesan penyusup'
            ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function pengirim_bisa_menghapus_pesannya_sendiri_yang_belum_dibaca()
    {
        Event::fake();

        // 1. Buat pesan baru dari pelanggan (belum dibaca)
        $message = OrderMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->customer->user_id,
            'message' => 'Pesan salah kirim',
            'is_read' => false
        ]);

        // 2. Pelanggan menghapus pesan tersebut
        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/messages/{$message->message_id}");

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);

        // Pastikan terhapus secara soft delete
        $this->assertSoftDeleted('order_messages', [
            'message_id' => $message->message_id
        ]);

        // Pastikan event MessageDeleted dibroadcast
        Event::assertDispatched(MessageDeleted::class);
    }

    /** @test */
    public function pengirim_tidak_bisa_menghapus_pesan_yang_sudah_dibaca()
    {
        // 1. Buat pesan baru dari pelanggan yang bertanda sudah dibaca (is_read = true)
        $message = OrderMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->customer->user_id,
            'message' => 'Pesan penting',
            'is_read' => true
        ]);

        // 2. Coba hapus
        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/messages/{$message->message_id}");

        $response->assertStatus(403);
        $response->assertJsonPath('message', 'Pesan sudah dibaca dan tidak dapat dihapus.');
    }

    /** @test */
    public function pengguna_tidak_bisa_menghapus_pesan_orang_lain()
    {
        // 1. Buat pesan dari Admin
        $message = OrderMessage::create([
            'order_id' => $this->order->order_id,
            'sender_id' => $this->admin->user_id,
            'message' => 'Pesan dari Admin',
            'is_read' => false
        ]);

        // 2. Pelanggan mencoba menghapus pesan admin tersebut
        $response = $this->actingAs($this->customer, 'sanctum')
            ->deleteJson("/api/orders/{$this->order->order_id}/messages/{$message->message_id}");

        $response->assertStatus(403);
        $response->assertJsonPath('message', 'Anda hanya dapat menghapus pesan Anda sendiri.');
    }
}
