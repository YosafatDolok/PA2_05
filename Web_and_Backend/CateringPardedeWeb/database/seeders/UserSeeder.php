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
        User::create([
            'name' => 'CateringPardede',
            'email' => 'admin@example.com',
            'password' => Hash::make('password123'),
            'role_id' => 1,
        ]);
    }
}
