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
        Schema::table('orders', function (Blueprint $table) {
            $cols = ['delivery_notes', 'reconciled_at', 'reconciled_by', 'payment_proof_image', 'payment_type'];
            $colsToDrop = array_filter($cols, function ($col) {
                return Schema::hasColumn('orders', $col);
            });
            if (!empty($colsToDrop)) {
                $table->dropColumn($colsToDrop);
            }
        });

        Schema::table('users', function (Blueprint $table) {
            $cols = ['cash_on_hand', 'remember_token', 'email_verified_at'];
            $colsToDrop = array_filter($cols, function ($col) {
                return Schema::hasColumn('users', $col);
            });
            if (!empty($colsToDrop)) {
                $table->dropColumn($colsToDrop);
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->text('delivery_notes')->nullable();
            $table->timestamp('reconciled_at')->nullable();
            $table->bigInteger('reconciled_by')->nullable();
            $table->text('payment_proof_image')->nullable();
            $table->string('payment_type')->nullable();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->decimal('cash_on_hand', 15, 2)->default(0);
            $table->rememberToken();
            $table->timestamp('email_verified_at')->nullable();
        });
    }
};
