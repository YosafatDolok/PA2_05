<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Admin
        $adminRole = Role::where('name', 'admin')->first();
        User::firstOrCreate(
            ['email' => 'admin@pardede.com'],
            [
                'name' => 'Admin Pardede',
                'password' => Hash::make('password123'),
                'role_id' => $adminRole->id,
            ]
        );

        // 2. Drivers
        $driverRole = Role::where('name', 'driver')->first();
        if ($driverRole) {
            User::firstOrCreate(
                ['email' => 'driver1@example.com'],
                [
                    'name' => 'Driver Budi',
                    'password' => Hash::make('password123'),
                    'role_id' => $driverRole->id,
                    'phone_number' => '081234567890'
                ]
            );
        }

        // 3. Customers (Users)
        $userRole = Role::where('name', 'user')->first();
        if ($userRole) {
            User::firstOrCreate(
                ['email' => 'customer@example.com'],
                [
                    'name' => 'Customer Yanto',
                    'password' => Hash::make('password123'),
                    'role_id' => $userRole->id,
                    'phone_number' => '089876543210'
                ]
            );
        }
    }
}
