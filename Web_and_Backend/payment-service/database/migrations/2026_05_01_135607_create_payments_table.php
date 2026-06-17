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
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->string('midtrans_id')->nullable()->unique();
            $table->string('snap_token')->nullable();
            $table->decimal('amount', 15, 2);
            $table->string('payment_method')->nullable(); // midtrans, bank_transfer, dll.
            $table->string('payment_type')->nullable(); // gopay, credit_card, dll.
            $table->string('status')->default('pending'); // pending, settlement, expire, cancel, deny
            $table->string('external_id')->nullable();
            $table->timestamp('transaction_time')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
