<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\MenuCategory;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

class MenuCategoryTest extends TestCase
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
        $this->customer = User::where('role_id', 2)->first();

        // Buat satu kategori awal
        $this->category = MenuCategory::create([
            'name' => 'Prasmanan Premium'
        ]);
    }

    /** @test */
    public function admin_bisa_mengakses_halaman_kategori()
    {
        $response = $this->actingAs($this->admin)
            ->get('/admin/categories');

        $response->assertStatus(200);
        $response->assertViewIs('admin.categories.index');
        $response->assertSee('Prasmanan Premium');
    }

    /** @test */
    public function admin_bisa_membuat_kategori_baru()
    {
        $response = $this->actingAs($this->admin)
            ->post('/admin/categories', [
                'name' => 'Nasi Kotak Hemat'
            ]);

        $response->assertStatus(302); // Redirect to categories.index
        $response->assertRedirect('/admin/categories');

        $this->assertDatabaseHas('menu_categories', [
            'name' => 'Nasi Kotak Hemat'
        ]);
    }

    /** @test */
    public function admin_tidak_bisa_membuat_kategori_dengan_nama_duplikat()
    {
        $response = $this->actingAs($this->admin)
            ->post('/admin/categories', [
                'name' => 'Prasmanan Premium' // Nama sudah ada di setup
            ]);

        $response->assertStatus(302); // Redirect back with validation error
        $response->assertSessionHasErrors('name');
    }

    /** @test */
    public function admin_bisa_mengedit_dan_memperbarui_kategori()
    {
        $response = $this->actingAs($this->admin)
            ->put("/admin/categories/{$this->category->category_id}", [
                'name' => 'Prasmanan Super Premium'
            ]);

        $response->assertStatus(302);
        $response->assertRedirect('/admin/categories');

        $this->assertDatabaseHas('menu_categories', [
            'category_id' => $this->category->category_id,
            'name' => 'Prasmanan Super Premium'
        ]);
    }

    /** @test */
    public function admin_bisa_menghapus_kategori()
    {
        $response = $this->actingAs($this->admin)
            ->delete("/admin/categories/{$this->category->category_id}");

        $response->assertStatus(302);
        $response->assertRedirect('/admin/categories');

        $this->assertDatabaseMissing('menu_categories', [
            'category_id' => $this->category->category_id
        ]);
    }

    /** @test */
    public function pengguna_bisa_mengambil_daftar_kategori_via_api()
    {
        $response = $this->getJson("/api/categories");

        $response->assertStatus(200);
        $response->assertJsonFragment([
            'name' => 'Prasmanan Premium'
        ]);
    }

    /** @test */
    public function bukan_admin_tidak_bisa_mengelola_kategori()
    {
        // Coba akses halaman admin kategori sebagai customer biasa
        $responseGet = $this->actingAs($this->customer)
            ->get('/admin/categories');
        $responseGet->assertStatus(403);

        // Coba buat kategori baru sebagai customer biasa
        $responsePost = $this->actingAs($this->customer)
            ->post('/admin/categories', [
                'name' => 'Kategori Penyusup'
            ]);
        $responsePost->assertStatus(403);
    }
}
