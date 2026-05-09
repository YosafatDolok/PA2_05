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
        $customers = User::where('role_id', 2)->get(); // User role
        $drivers = User::where('role_id', 3)->get();   // Driver role
        $menus = Menu::all();
        $statuses = OrderStatus::all();

        if ($customers->isEmpty() || $menus->isEmpty()) return;

        // Base Coordinates for Balige (Pardede Base)
        $baseLat = 2.437190;
        $baseLng = 99.157618;

        // Create 20 orders
        for ($i = 0; $i < 20; $i++) {
            $date = Carbon::now()->subDays(rand(0, 30));
            
            // For the first 5 orders, make them ACTIVE for map testing
            if ($i < 5) {
                $statusId = rand(2, 3); // Preparing or Out for Delivery
                $driverId = $drivers->isNotEmpty() ? $drivers->random()->user_id : null;
            } else {
                $statusId = $statuses->random()->status_id;
                $driverId = null;
            }

            // Generate random lat/lng within ~5km of base
            $latOffset = (rand(-500, 500) / 10000); // approx +/- 5km
            $lngOffset = (rand(-500, 500) / 10000);

            $order = Order::create([
                'user_id' => $customers->random()->user_id,
                'driver_id' => $driverId,
                'event_address' => 'Jl. Balige Jaya No. ' . rand(1, 100),
                'event_latitude' => $baseLat + $latOffset,
                'event_longitude' => $baseLng + $lngOffset,
                'event_date' => $date->copy()->addDays(rand(1, 7)),
                'order_date' => $date,
                'status_id' => $statusId,
                'final_price' => rand(500000, 2000000),
                'people' => rand(20, 100),
                'notes' => 'Generated demo order #' . ($i + 1),
                'created_at' => $date,
                'updated_at' => $date,
            ]);

            // Add items
            $orderMenus = $menus->random(rand(1, 3));
            foreach ($orderMenus as $menu) {
                OrderItem::create([
                    'order_id' => $order->order_id,
                    'menu_id' => $menu->menu_id,
                    'final_price' => rand(25000, 50000),
                ]);
            }
        }
    }
}
