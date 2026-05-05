<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function () {
            $roles = [
                ['name' => 'admin'],
                ['name' => 'user'],
                ['name' => 'driver'],
            ];

            foreach ($roles as $roleData) {
                $role = Role::firstOrCreate($roleData);

                Log::info("Role handled: {$role->name}");
            }
        });
    }
}
