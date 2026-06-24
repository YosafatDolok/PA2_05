<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Role;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use App\Mail\DriverEmailChangedMail;
use Tests\TestCase;

class SecureEditDriverTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $driver;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('email', 'admin@pardede.com')->first();
        $this->driver = User::where('email', 'driver1@example.com')->first();
    }

    /** @test */
    public function admin_bisa_mengakses_halaman_edit_sopir()
    {
        $response = $this->actingAs($this->admin)
            ->get(route('drivers.edit', $this->driver));

        $response->assertStatus(200);
        $response->assertSee('Edit Sopir');
        $response->assertSee('KONFIRMASI PASSWORD ADMIN');
    }

    /** @test */
    public function bukan_admin_tidak_bisa_mengakses_halaman_edit_sopir()
    {
        $response = $this->actingAs($this->driver)
            ->get(route('drivers.edit', $this->driver));

        $response->assertStatus(403);
    }

    /** @test */
    public function pembaruan_gagal_jika_password_admin_tidak_diisi()
    {
        $response = $this->actingAs($this->admin)
            ->put(route('drivers.update', $this->driver), [
                'name' => 'Updated Name',
                'email' => 'driver1@example.com',
                'phone_number' => '081234567890',
            ]);

        $response->assertSessionHasErrors('admin_password');
    }

    /** @test */
    public function pembaruan_gagal_jika_password_admin_salah()
    {
        $response = $this->actingAs($this->admin)
            ->put(route('drivers.update', $this->driver), [
                'name' => 'Updated Name',
                'email' => 'driver1@example.com',
                'phone_number' => '081234567890',
                'admin_password' => 'wrong_password',
            ]);

        $response->assertSessionHasErrors('admin_password');
    }

    /** @test */
    public function pembaruan_berhasil_dengan_password_admin_yang_benar_dan_tidak_memicu_email_jika_email_tidak_diubah()
    {
        Mail::fake();

        $response = $this->actingAs($this->admin)
            ->put(route('drivers.update', $this->driver), [
                'name' => 'Updated Driver Name',
                'email' => 'driver1@example.com',
                'phone_number' => '081234567899',
                'admin_password' => 'password123',
            ]);

        $response->assertRedirect(route('drivers.index'));
        $response->assertSessionHasNoErrors();

        $this->driver->refresh();
        $this->assertEquals('Updated Driver Name', $this->driver->name);
        $this->assertEquals('081234567899', $this->driver->phone_number);

        Mail::assertNotSent(DriverEmailChangedMail::class);
    }

    /** @test */
    public function pembaruan_memicu_notifikasi_email_saat_email_diubah()
    {
        Mail::fake();

        $response = $this->actingAs($this->admin)
            ->put(route('drivers.update', $this->driver), [
                'name' => 'Driver Budi',
                'email' => 'newdriver@example.com',
                'phone_number' => '081234567890',
                'admin_password' => 'password123',
            ]);

        $response->assertRedirect(route('drivers.index'));
        $response->assertSessionHasNoErrors();

        $this->driver->refresh();
        $this->assertEquals('newdriver@example.com', $this->driver->email);

        Mail::assertSent(DriverEmailChangedMail::class, function ($mail) {
            return $mail->oldEmail === 'driver1@example.com' &&
                   $mail->newEmail === 'newdriver@example.com' &&
                   $mail->hasTo('driver1@example.com');
        });
    }
}
