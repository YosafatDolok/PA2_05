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
        Schema::create('reviews', function (Blueprint $wrapper) {
            $wrapper->id('review_id');
            $wrapper->unsignedBigInteger('order_id')->unique(); // One review per order
            $wrapper->unsignedBigInteger('user_id');
            $wrapper->tinyInteger('rating')->unsigned(); // 1-5
            $wrapper->text('comment')->nullable();
            $wrapper->boolean('is_visible')->default(true);
            $wrapper->timestamps();

            // Foreign Keys
            $wrapper->foreign('order_id')->references('order_id')->on('orders')->onDelete('cascade');
            $wrapper->foreign('user_id')->references('user_id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
