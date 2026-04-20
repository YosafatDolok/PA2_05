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
        // ✅ ambil role admin dulu
        $adminRole = Role::where('name', 'admin')->first();

        // ❗ cek kalau role tidak ada
        if (!$adminRole) {
            echo "Role admin tidak ditemukan\n";
            return;
        }

        // ✅ buat user admin
        User::create([
            'name' => 'CateringPardede',
            'email' => 'admin2@example.com',
            'password' => Hash::make('password123'),
            'role_id' => $adminRole->id,
        ]);
    }
}
