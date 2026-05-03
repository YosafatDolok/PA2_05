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
    $table->unsignedBigInteger('order_id'); // dari order service
    $table->decimal('amount', 15, 2);
    $table->string('payment_method'); // e-wallet
    $table->string('status'); // pending, paid, failed
    $table->string('external_id')->nullable(); // simulasi transaksi
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
