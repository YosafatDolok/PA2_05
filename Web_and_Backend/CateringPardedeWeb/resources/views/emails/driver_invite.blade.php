<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Undangan Driver</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .header { background-color: #7A0000; padding: 40px; text-align: center; }
        .header h1 { color: #FFD700; margin: 0; font-size: 28px; letter-spacing: 2px; text-transform: uppercase; }
        .content { padding: 40px; color: #333333; line-height: 1.6; }
        .btn-container { text-align: center; margin: 30px 0; }
        .btn { background-color: #7A0000; color: #FFD700 !important; padding: 15px 30px; border-radius: 10px; text-decoration: none; font-weight: bold; font-size: 18px; display: inline-block; box-shadow: 0 4px 10px rgba(122, 0, 0, 0.3); }
        .footer { background-color: #f9f9f9; padding: 20px; text-align: center; font-size: 12px; color: #888888; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Pardede Catering</h1>
        </div>
        <div class="content">
            <h2 style="color: #7A0000;">Selamat Bergabung, {{ $user->name }}!</h2>
            <p>Anda telah terdaftar sebagai mitra driver di <strong>Pardede Catering</strong>. Untuk mulai melayani pelanggan kami, silakan aktifkan akun Anda dan buat kata sandi baru melalui tombol di bawah ini:</p>
            
            <div class="btn-container">
                <a href="{{ $inviteUrl }}" class="btn">AKTIFKAN AKUN SAYA</a>
            </div>
            
            <p style="font-size: 14px; color: #666;">Tautan aktivasi ini berlaku selama 24 jam. Jika Anda mengalami kesulitan mengklik tombol, salin dan tempel tautan berikut ke browser Anda:</p>
            <p style="font-size: 12px; color: #7A0000; word-break: break-all;">{{ $inviteUrl }}</p>
            
            <p>Terima kasih,<br><strong>Tim Operasional Pardede Catering</strong></p>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} Pardede Catering. Seluruh Hak Cipta Dilindungi.<br>
            Tradisi Kemewahan dalam Setiap Sajian.
        </div>
    </div>
</body>
</html>
