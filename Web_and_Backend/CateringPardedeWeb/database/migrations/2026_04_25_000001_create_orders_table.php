<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id('order_id');
            $table->foreignId('user_id')->constrained('users', 'user_id');
            $table->foreignId('driver_id')->nullable()->constrained('users', 'user_id');

            $table->text('event_address');
            $table->decimal('event_latitude', 10, 8)->nullable();
            $table->decimal('event_longitude', 11, 8)->nullable();
            $table->text('location_notes')->nullable();

            $table->date('event_date');
            $table->foreignId('status_id')->constrained('order_statuses', 'status_id');
            $table->decimal('final_price', 10, 2);

            $table->timestamp('order_date')->useCurrent();
            $table->integer('people');
            $table->text('notes')->nullable();

            // delivery
            $table->timestamp('started_delivery_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->text('delivery_notes')->nullable();
            $table->text('delivery_proof_image')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
