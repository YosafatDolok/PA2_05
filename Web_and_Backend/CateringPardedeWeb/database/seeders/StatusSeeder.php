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
    // Order Status
    \App\Models\OrderStatus::updateOrInsert(
        ['status_id' => 1],
        ['status_name' => 'Pending']
    );

    \App\Models\OrderStatus::updateOrInsert(
        ['status_id' => 2],
        ['status_name' => 'Preparing']
    );

    \App\Models\OrderStatus::updateOrInsert(
        ['status_id' => 3],
        ['status_name' => 'Out for Delivery']
    );

    \App\Models\OrderStatus::updateOrInsert(
        ['status_id' => 4],
        ['status_name' => 'Delivered']
    );

    \App\Models\OrderStatus::updateOrInsert(
        ['status_id' => 5],
        ['status_name' => 'Paid']
    );

    \App\Models\OrderStatus::updateOrInsert(
        ['status_id' => 9],
        ['status_name' => 'Cancelled']
    );
    }
}
