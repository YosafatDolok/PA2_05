<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->uuid('uuid')->nullable()->unique()->after('user_id');
        });

        // Populate existing users with UUIDs
        $users = DB::table('users')->get();
        foreach ($users as $user) {
            DB::table('users')
                ->where('user_id', $user->user_id)
                ->update(['uuid' => (string) Str::uuid()]);
        }

        // Make it non-nullable after population
        Schema::table('users', function (Blueprint $table) {
            $table->uuid('uuid')->nullable(false)->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('uuid');
        });
    }
};
