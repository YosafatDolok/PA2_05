<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('order_addition_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders', 'order_id')->onDelete('cascade');
            $table->foreignId('status_id')->constrained('order_statuses', 'status_id');
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        Schema::create('order_addition_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('request_id')->constrained('order_addition_requests')->onDelete('cascade');
            $table->foreignId('menu_id')->constrained('menus', 'menu_id');
            $table->decimal('final_price', 10, 2)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_addition_items');
        Schema::dropIfExists('order_addition_requests');
    }
};
