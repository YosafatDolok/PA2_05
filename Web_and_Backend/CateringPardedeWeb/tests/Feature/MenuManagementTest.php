<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Menu;
use App\Models\MenuCategory;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class MenuManagementTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;
    protected $category;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        $this->customer = User::factory()->create(['role_id' => 2]);
        $this->category = MenuCategory::first();
    }

    /** @test */
    public function admin_bisa_membuat_menu_baru()
    {
        Storage::fake('public');
        // Gunakan create() pengganti image() agar tidak bergantung pada ekstensi GD PHP
        $image = UploadedFile::fake()->create('bakso.jpg', 100);

        $response = $this->actingAs($this->admin)
            ->post(route('menus.store'), [
                'name' => 'Bakso Special',
                'category_id' => $this->category->category_id,
                'description' => 'Bakso gurih lezat',
                'image' => $image
            ]);

        $response->assertRedirect(route('menus.index'));
        $response->assertSessionHas('success', 'Menu created successfully');

        $this->assertDatabaseHas('menus', [
            'name' => 'Bakso Special',
            'category_id' => $this->category->category_id,
            'description' => 'Bakso gurih lezat',
            'user_id' => $this->admin->user_id
        ]);

        $menu = Menu::where('name', 'Bakso Special')->first();
        $this->assertNotNull($menu->image);
        Storage::disk('public')->assertExists($menu->image);
    }

    /** @test */
    public function bukan_admin_tidak_bisa_membuat_menu_baru()
    {
        $response = $this->actingAs($this->customer)
            ->post(route('menus.store'), [
                'name' => 'Bakso Special',
                'category_id' => $this->category->category_id,
                'description' => 'Bakso gurih lezat',
            ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function admin_bisa_menghapus_menu_secara_soft_delete()
    {
        $menu = Menu::create([
            'name' => 'Nasi Goreng Gila',
            'category_id' => $this->category->category_id,
            'description' => 'Nasi goreng super pedas',
            'user_id' => $this->admin->user_id,
            'image' => 'menus/placeholder.jpg', // Kolom image NOT NULL di database
            'available' => true
        ]);

        $response = $this->actingAs($this->admin)
            ->delete(route('menus.destroy', $menu->menu_id));

        $response->assertRedirect(route('menus.index'));
        $response->assertSessionHas('success', 'Menu moved to trash successfully');

        $this->assertSoftDeleted('menus', [
            'menu_id' => $menu->menu_id,
            'name' => 'Nasi Goreng Gila'
        ]);
    }

    /** @test */
    public function admin_bisa_memulihkan_menu_yang_dihapus()
    {
        $menu = Menu::create([
            'name' => 'Ayam Penyet Kobar',
            'category_id' => $this->category->category_id,
            'description' => 'Ayam penyet super pedas',
            'user_id' => $this->admin->user_id,
            'image' => 'menus/placeholder.jpg', // Kolom image NOT NULL di database
            'available' => true
        ]);

        $menu->delete();
        $this->assertSoftDeleted('menus', ['menu_id' => $menu->menu_id]);

        $response = $this->actingAs($this->admin)
            ->post(route('menus.restore', $menu->menu_id));

        $response->assertRedirect(route('menus.index'));
        $response->assertSessionHas('success', 'Menu restored successfully');

        $this->assertDatabaseHas('menus', [
            'menu_id' => $menu->menu_id,
            'deleted_at' => null
        ]);
    }
}
