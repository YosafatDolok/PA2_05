<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\OrderAdditionRequest;
use App\Models\OrderMessage;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OrderBugFixesTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
    }

    /** @test */
    public function permintaan_tambahan_pesanan_memiliki_atribut_status_text()
    {
        $order = Order::first();
        $request = OrderAdditionRequest::create([
            'order_id' => $order->order_id,
            'status_id' => 1,
            'notes' => 'Catatan tes'
        ]);
        $this->assertNotNull($request);
        
        $request->status_id = 1;
        $this->assertEquals('Pending', $request->status_text);

        $request->status_id = 2;
        $this->assertEquals('Approved', $request->status_text);

        $request->status_id = 3;
        $this->assertEquals('Rejected', $request->status_text);

        // Memastikan status_text dilampirkan dalam serialisasi JSON
        $json = $request->toArray();
        $this->assertArrayHasKey('status_text', $json);
        $this->assertEquals('Rejected', $json['status_text']);
    }


    /** @test */
    public function sopir_yang_ditugaskan_pada_pesanan_bisa_melihat_detail_pesanan()
    {
        $order = Order::first();
        
        // Cari atau buat akun sopir
        $driver = User::where('role_id', 3)->first();
        if (!$driver) {
            $driver = User::factory()->create(['role_id' => 3]);
        }

        // Terapkan sopir ke pesanan
        $order->update(['driver_id' => $driver->user_id]);

        // Melakukan request detail pesanan sebagai sopir
        $response = $this->actingAs($driver, 'sanctum')
            ->getJson("/api/orders/{$order->order_id}");

        // Memastikan data berhasil diambil
        $response->assertStatus(200);
        $response->assertJsonPath('order_id', $order->order_id);
    }

    /** @test */
    public function job_pengiriman_push_notification_bisa_dijalankan()
    {
        \Illuminate\Support\Facades\Bus::fake();

        $job = new \App\Jobs\SendPushNotification('token', 'title', 'body', []);
        dispatch($job);

        \Illuminate\Support\Facades\Bus::assertDispatched(\App\Jobs\SendPushNotification::class);
    }

    /** @test */
    public function admin_bisa_mengelola_pesan_chat_melalui_rute_web()
    {
        $order = Order::first();
        $admin = User::where('role_id', 1)->first();

        // 1. Mengambil riwayat pesan
        $response = $this->actingAs($admin)
            ->get("/admin/orders/{$order->order_id}/messages");
        $response->assertStatus(200);

        // 2. Mengirim pesan baru
        $response = $this->actingAs($admin)
            ->postJson("/admin/orders/{$order->order_id}/messages", [
                'message' => 'Halo dari Admin via Web'
            ]);
        $response->assertStatus(201);
        $messageId = $response->json('message_id');
        $this->assertDatabaseHas('order_messages', [
            'message_id' => $messageId,
            'message' => 'Halo dari Admin via Web'
        ]);

        // 3. Menghapus pesan
        $response = $this->actingAs($admin)
            ->deleteJson("/admin/orders/{$order->order_id}/messages/{$messageId}");
        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
    }
}
