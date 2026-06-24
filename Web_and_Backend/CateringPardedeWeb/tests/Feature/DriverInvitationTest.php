<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use App\Mail\DriverInviteMail;
use Illuminate\Support\Str;
use Carbon\Carbon;

class DriverInvitationTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->seed(DatabaseSeeder::class);
        $this->admin = User::where('role_id', 1)->first();
    }

    /** @test */
    public function admin_bisa_mengundang_sopir_baru_dan_memicu_email()
    {
        Mail::fake();

        $response = $this->actingAs($this->admin)
            ->post(route('drivers.store'), [
                'name' => 'Sopir Agus',
                'email' => 'agus.driver@example.com',
                'phone_number' => '081999888777'
            ]);

        $response->assertRedirect(route('drivers.index'));
        $response->assertSessionHas('success');

        // Pastikan sopir terdaftar dengan role_id = 3 (Sopir), status password kosong, dan token terisi
        $this->assertDatabaseHas('users', [
            'name' => 'Sopir Agus',
            'email' => 'agus.driver@example.com',
            'phone_number' => '081999888777',
            'role_id' => 3
        ]);

        $driver = User::where('email', 'agus.driver@example.com')->first();
        $this->assertNotEmpty($driver->invite_token);
        $this->assertNotNull($driver->invite_expires_at);

        // Pastikan email undangan dikirimkan
        Mail::assertSent(DriverInviteMail::class, function ($mail) use ($driver) {
            return $mail->hasTo($driver->email);
        });
    }

    /** @test */
    public function sopir_bisa_mengatur_password_dan_mengaktifkan_akun()
    {
        // 1. Buat user sopir pending dengan token undangan
        $token = Str::random(40);
        $driver = User::create([
            'name' => 'Sopir Budi Pending',
            'email' => 'budi.pending@example.com',
            'phone_number' => '081777666555',
            'role_id' => 3,
            'password' => 'pending_activation',
            'invite_token' => $token,
            'invite_expires_at' => Carbon::now()->addHours(24)
        ]);

        // 2. Akses halaman set password
        $responseGet = $this->get(route('driver.invite.set-password', $token));
        $responseGet->assertStatus(200);
        $responseGet->assertSee('Activate Account'); // Memastikan view terpanggil

        // 3. Sopir menetapkan password
        $responsePost = $this->post(route('driver.invite.setPassword', $token), [
            'password' => 'P@ssword123',
            'password_confirmation' => 'P@ssword123'
        ]);

        $responsePost->assertRedirect(route('driver.invite.success'));

        // 4. Pastikan password terupdate dan token di-clear (tanda akun aktif)
        $driver->refresh();
        $this->assertNull($driver->invite_token);
        $this->assertNull($driver->invite_expires_at);
        $this->assertTrue(\Hash::check('P@ssword123', $driver->password));
    }
}
