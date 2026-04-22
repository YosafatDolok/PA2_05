<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class StatusSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        \App\Models\OrderStatus::insert([
            ['status_name' => 'Pending'],
            ['status_name' => 'Preparing'],
            ['status_name' => 'Out for Delivery'],
            ['status_name' => 'Delivered'],
        ]);

        \App\Models\PaymentStatus::insert([
            ['pstatus_name' => 'Unpaid'],
            ['pstatus_name' => 'Paid'],
        ]);
    }
}
