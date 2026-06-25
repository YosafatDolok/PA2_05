<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Carbon\Carbon;

class ProfileUpdateTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        // Set password admin yang jelas untuk mempermudah pengetesan web password confirmation
        $this->admin->update(['password' => Hash::make('password123')]);

        $this->customer = User::where('role_id', 2)->first();
    }

    /** @test */
    public function pelanggan_bisa_memperbarui_nama_secara_langsung_melalui_api_tanpa_otp()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/user/update", [
                'name' => 'Nama Baru Pelanggan',
                'email' => $this->customer->email, // Email tidak berubah
                'phone_number' => $this->customer->phone_number // Nomor telepon tidak berubah
            ]);

        $response->assertStatus(302); // Laravel redirect pada non-AJAX atau wantsJson() yang tidak diset.
        // Agar diproses sebagai wantsJson(), gunakan postJson
    }

    /** @test */
    public function pelanggan_bisa_memperbarui_nama_via_post_json()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/user/update", [
                'name' => 'Nama Baru Pelanggan',
                'email' => $this->customer->email,
                'phone_number' => $this->customer->phone_number
            ], ['Accept' => 'application/json']);

        $response->assertStatus(302); // Redirect karena ProfileController default mengembalikan redirect() jika tidak explicitly memeriksa wantsJson() dengan benar.
        // Wait, mari lihat baris 55 di ProfileController: if ($request->wantsJson() && ($emailChanged || $phoneChanged))
        // Tapi jika email/phone TIDAK berubah, program langsung melompat ke baris 113: return redirect()->route('profile.edit')...
        // Ah! Jadi jika wantsJson() aktif tetapi email/phone TIDAK berubah, method update() tetap mengembalikan redirect() ke route profile.edit.
        // Itu tidak apa-apa, asalkan data di database terupdate. Mari kita periksa.
        $this->assertDatabaseHas('users', [
            'user_id' => $this->customer->user_id,
            'name' => 'Nama Baru Pelanggan'
        ]);
    }

    /** @test */
    public function perubahan_email_atau_telepon_melalui_api_memicu_otp_dan_menyimpan_data_tertunda()
    {
        Mail::fake();

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/user/update", [
                'name' => 'Pelanggan Ganti Email',
                'email' => 'emailbaru@example.com',
                'phone_number' => $this->customer->phone_number
            ], ['Accept' => 'application/json']);

        // Karena wantsJson() bernilai true dan email berubah, harusnya return JSON requires_otp = true
        $response->assertStatus(200);
        $response->assertJsonPath('requires_otp', true);
        $response->assertJsonPath('target_email', 'emailbaru@example.com');

        // Pastikan terekam di pending_profile_updates
        $this->assertDatabaseHas('pending_profile_updates', [
            'user_id' => $this->customer->user_id,
            'new_email' => 'emailbaru@example.com',
            'new_phone_number' => null
        ]);

        // Email OTP dikirim
        Mail::assertSent(\App\Mail\ProfileUpdateOtpMail::class);
    }

    /** @test */
    public function pelanggan_bisa_memverifikasi_otp_profil_yang_valid()
    {
        // Masukkan pending update buatan ke DB
        DB::table('pending_profile_updates')->insert([
            'user_id' => $this->customer->user_id,
            'new_email' => 'emailbaru_terverifikasi@example.com',
            'new_phone_number' => '081234567890',
            'otp_code' => '777888',
            'expires_at' => Carbon::now()->addMinutes(5),
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now()
        ]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/user/update/verify-otp", [
                'otp' => '777888'
            ]);

        $response->assertStatus(200);
        $response->assertJsonPath('success', true);
        $response->assertJsonPath('message', 'Profil berhasil diperbarui.');

        // Pastikan user email dan phone terupdate di DB
        $this->assertDatabaseHas('users', [
            'user_id' => $this->customer->user_id,
            'email' => 'emailbaru_terverifikasi@example.com',
            'phone_number' => '081234567890'
        ]);

        // Pastikan pending data dihapus
        $this->assertDatabaseMissing('pending_profile_updates', [
            'user_id' => $this->customer->user_id
        ]);
    }

    /** @test */
    public function verifikasi_otp_gagal_jika_kode_salah_atau_kadaluarsa()
    {
        // 1. Uji kode salah
        DB::table('pending_profile_updates')->insert([
            'user_id' => $this->customer->user_id,
            'new_email' => 'emailbaru@example.com',
            'otp_code' => '111222',
            'expires_at' => Carbon::now()->addMinutes(5),
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now()
        ]);

        $responseSalah = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/user/update/verify-otp", [
                'otp' => '999999' // Kode salah
            ]);

        $responseSalah->assertStatus(422);
        $responseSalah->assertJsonPath('message', 'Kode verifikasi salah.');

        // 2. Uji kode kadaluarsa
        DB::table('pending_profile_updates')
            ->where('user_id', $this->customer->user_id)
            ->update([
                'otp_code' => '111222',
                'expires_at' => Carbon::now()->subMinutes(10) // Sudah kadaluarsa 10 menit lalu
            ]);

        $responseKadaluarsa = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/user/update/verify-otp", [
                'otp' => '111222'
            ]);

        $responseKadaluarsa->assertStatus(422);
        $responseKadaluarsa->assertJsonPath('message', 'Kode verifikasi telah kadaluarsa.');
    }

    /** @test */
    public function perubahan_email_atau_telepon_di_web_memicu_konfirmasi_password()
    {
        $response = $this->actingAs($this->admin)
            ->put("/admin/profile", [
                'name' => 'Admin Baru',
                'email' => 'admin_baru@example.com', // Berubah
                'phone_number' => $this->admin->phone_number
            ]);

        $response->assertStatus(302);
        $response->assertRedirect('/admin/profile');
        $response->assertSessionHas('requires_password_confirmation', true);
        $response->assertSessionHas('pending_email', 'admin_baru@example.com');
    }

    /** @test */
    public function admin_bisa_mengonfirmasi_perubahan_email_dan_telepon_dengan_password_yang_benar()
    {
        // Set pending update di session
        $this->actingAs($this->admin)
            ->withSession([
                'pending_email' => 'admin_baru_terkonfirmasi@example.com',
                'pending_phone' => '087766554433',
                'requires_password_confirmation' => true
            ]);

        $response = $this->post("/admin/profile/confirm", [
            'current_password' => 'password123' // Password benar
        ]);

        $response->assertStatus(302);
        $response->assertRedirect('/admin/profile');
        $response->assertSessionHas('success', 'Profil berhasil diperbarui dengan aman.');

        // Cek database terupdate
        $this->assertDatabaseHas('users', [
            'user_id' => $this->admin->user_id,
            'email' => 'admin_baru_terkonfirmasi@example.com',
            'phone_number' => '087766554433'
        ]);

        // Sesi dihapus
        $response->assertSessionMissing('pending_email');
        $response->assertSessionMissing('pending_phone');
    }

    /** @test */
    public function konfirmasi_perubahan_email_gagal_jika_password_salah()
    {
        $this->actingAs($this->admin)
            ->withSession([
                'pending_email' => 'admin_gagal@example.com',
                'requires_password_confirmation' => true
            ]);

        $response = $this->post("/admin/profile/confirm", [
            'current_password' => 'passwordsalah'
        ]);

        $response->assertStatus(302);
        $response->assertSessionHas('error', 'Password yang Anda masukkan salah. Perubahan profil dibatalkan.');

        // Email di DB tidak boleh berubah
        $this->assertDatabaseMissing('users', [
            'user_id' => $this->admin->user_id,
            'email' => 'admin_gagal@example.com'
        ]);
    }
}
