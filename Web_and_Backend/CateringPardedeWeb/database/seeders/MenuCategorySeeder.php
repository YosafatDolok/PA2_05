<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\MenuCategory;

class MenuCategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Nasi Box'],
            ['name' => 'Prasmanan'],
            ['name' => 'Snack Box'],
            ['name' => 'Minuman'],
        ];

        foreach ($categories as $category) {
            MenuCategory::firstOrCreate(['name' => $category['name']]);
        }
    }
}
