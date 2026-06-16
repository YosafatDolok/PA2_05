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
    public function order_addition_request_has_status_text_attribute()
    {
        $order = Order::first();
        $request = OrderAdditionRequest::create([
            'order_id' => $order->order_id,
            'status_id' => 1,
            'notes' => 'Test notes'
        ]);
        $this->assertNotNull($request);
        
        $request->status_id = 1;
        $this->assertEquals('Pending', $request->status_text);

        $request->status_id = 2;
        $this->assertEquals('Approved', $request->status_text);

        $request->status_id = 3;
        $this->assertEquals('Rejected', $request->status_text);

        // Check if status_text is appended in JSON serialization
        $json = $request->toArray();
        $this->assertArrayHasKey('status_text', $json);
        $this->assertEquals('Rejected', $json['status_text']);
    }


    /** @test */
    public function driver_assigned_to_order_can_view_order_details()
    {
        $order = Order::first();
        
        // Find or create a driver
        $driver = User::where('role_id', 3)->first();
        if (!$driver) {
            $driver = User::factory()->create(['role_id' => 3]);
        }

        // Assign the driver to the order
        $order->update(['driver_id' => $driver->user_id]);

        // Act: request details as the driver
        $response = $this->actingAs($driver, 'sanctum')
            ->getJson("/api/orders/{$order->order_id}");

        // Assert: successful retrieval
        $response->assertStatus(200);
        $response->assertJsonPath('order_id', $order->order_id);
    }

    /** @test */
    public function send_push_notification_job_is_dispatchable()
    {
        \Illuminate\Support\Facades\Bus::fake();

        $job = new \App\Jobs\SendPushNotification('token', 'title', 'body', []);
        dispatch($job);

        \Illuminate\Support\Facades\Bus::assertDispatched(\App\Jobs\SendPushNotification::class);
    }
}
