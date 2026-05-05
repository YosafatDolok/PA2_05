<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use App\Models\Menu;
use App\Models\OrderStatus;
use Carbon\Carbon;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        $customers = User::whereHas('role', function($q) { $q->where('name', 'user'); })->get();
        $menus = Menu::all();
        $statuses = OrderStatus::all();

        if ($customers->isEmpty() || $menus->isEmpty()) return;

        // Create 20 orders over the last 6 months
        for ($i = 0; $i < 20; $i++) {
            $date = Carbon::now()->subDays(rand(0, 180));
            
            $order = Order::create([
                'user_id' => $customers->random()->user_id,
                'event_address' => 'Jl. Contoh Alamat No. ' . rand(1, 100),
                'event_date' => $date->copy()->addDays(7),
                'order_date' => $date,
                'status_id' => $statuses->random()->status_id,
                'final_price' => rand(500000, 5000000),
                'people' => rand(20, 200),
                'notes' => 'Catatan pesanan ke-' . ($i + 1),
                'created_at' => $date,
                'updated_at' => $date,
            ]);

            // Add 1-3 items per order
            $orderMenus = $menus->random(rand(1, 3));
            foreach ($orderMenus as $menu) {
                OrderItem::create([
                    'order_id' => $order->order_id,
                    'menu_id' => $menu->menu_id,
                    'final_price' => $order->final_price / $orderMenus->count(),
                ]);
            }
        }
    }
}
