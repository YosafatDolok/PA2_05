<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Menu;
use App\Models\MenuCategory;
use App\Models\User;

class MenuSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::whereHas('role', function($q) { $q->where('name', 'admin'); })->first();
        if (!$admin) return;

        $nasiBox = MenuCategory::where('name', 'Nasi Box')->first();
        $prasmanan = MenuCategory::where('name', 'Prasmanan')->first();
        $snack = MenuCategory::where('name', 'Snack Box')->first();

        $menus = [
            [
                'name' => 'Paket Nasi Kuning Spesial',
                'description' => 'Nasi kuning, ayam goreng, telur balado, perkedel, dan sambal.',
                'image' => 'menus/nasi_kuning.jpg',
                'category_id' => $nasiBox->category_id,
                'user_id' => $admin->user_id,
                'available' => true,
            ],
            [
                'name' => 'Nasi Kotak Ayam Bakar',
                'description' => 'Nasi putih, ayam bakar, tahu tempe, lalapan, dan sambal terasi.',
                'image' => 'menus/nasi_ayam_bakar.jpg',
                'category_id' => $nasiBox->category_id,
                'user_id' => $admin->user_id,
                'available' => true,
            ],
            [
                'name' => 'Menu Prasmanan A',
                'description' => 'Nasi putih, soup kimlo, rendang daging, kakap asam manis, capcay.',
                'image' => 'menus/prasmanan_a.jpg',
                'category_id' => $prasmanan->category_id,
                'user_id' => $admin->user_id,
                'available' => true,
            ],
            [
                'name' => 'Snack Box Arisan',
                'description' => 'Lemper, risol mayo, dan kue sus.',
                'image' => 'menus/snack_arisan.jpg',
                'category_id' => $snack->category_id,
                'user_id' => $admin->user_id,
                'available' => true,
            ],
        ];

        foreach ($menus as $menuData) {
            Menu::firstOrCreate(['name' => $menuData['name']], $menuData);
        }
    }
}
