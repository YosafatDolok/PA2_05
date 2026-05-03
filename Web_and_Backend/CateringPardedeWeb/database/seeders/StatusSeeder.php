<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
class StatusSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('order_statuses')->insert([
            [
                'status_name' => 'Pending',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'status_name' => 'Preparing',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'status_name' => 'Out for Delivery',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'status_name' => 'Delivered',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'status_name' => 'Paid',
                'created_at' => now(),
                'updated_at' => now(),
            ]
        ]);
    }
}