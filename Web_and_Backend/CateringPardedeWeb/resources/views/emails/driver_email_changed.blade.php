<!DOCTYPE html>
<html>
<head>
    <title>Pemberitahuan Keamanan: Perubahan Email Akun</title>
</head>
<body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #A41215; text-align: center;">Catering Pardede</h2>
        
        <p>Halo <strong>{{ $user->name }}</strong>,</p>
        
        <p>Email login Anda untuk akun driver di **Catering Pardede** telah diubah oleh administrator.</p>
        
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 8px; border: 1px solid #e0e0e0; margin: 20px 0;">
            <table style="width: 100%; border-collapse: collapse;">
                <tr>
                    <td style="padding: 6px 0; font-weight: bold; color: #666; width: 40%;">Email Lama:</td>
                    <td style="padding: 6px 0; color: #333;">{{ $oldEmail }}</td>
                </tr>
                <tr>
                    <td style="padding: 6px 0; font-weight: bold; color: #666;">Email Baru:</td>
                    <td style="padding: 6px 0; color: #A41215; font-weight: bold;">{{ $newEmail }}</td>
                </tr>
                <tr>
                    <td style="padding: 6px 0; font-weight: bold; color: #666;">Waktu Perubahan:</td>
                    <td style="padding: 6px 0; color: #333;">{{ $changeDateTime }} WIB</td>
                </tr>
            </table>
        </div>
        
        <p style="color: #666; font-size: 14px;">
            Mulai sekarang, Anda harus menggunakan alamat email baru Anda (<strong>{{ $newEmail }}</strong>) untuk masuk ke aplikasi. Password Anda tidak berubah.
        </p>

        <div style="background-color: #fff3cd; border: 1px solid #ffeeba; color: #856404; padding: 12px; border-radius: 6px; margin: 20px 0; font-size: 14px;">
            <strong>Peringatan Keamanan:</strong> Jika Anda tidak mengetahui atau tidak mengizinkan perubahan ini, silakan segera hubungi admin untuk mengamankan akun Anda.
        </div>
        
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 30px 0;">
        <p style="font-size: 12px; color: #999; text-align: center;">
            &copy; {{ date('Y') }} Catering Pardede.
        </p>
    </div>
</body>
</html>
