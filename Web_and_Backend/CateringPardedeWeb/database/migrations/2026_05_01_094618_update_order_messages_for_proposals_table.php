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
        Schema::table('order_messages', function (Blueprint $table) {
            $table->string('type')->default('text'); // 'text' or 'proposal'
            $table->decimal('proposed_price', 15, 2)->nullable();
            $table->string('proposal_status')->nullable(); // 'pending', 'accepted', 'rejected'
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_messages', function (Blueprint $table) {
            $table->dropColumn(['type', 'proposed_price', 'proposal_status']);
        });
    }
};
