<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Kode Verifikasi</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }
        .header {
            background-color: #7A0000;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            color: #FFD700;
            margin: 0;
            font-size: 28px;
            letter-spacing: 2px;
            text-transform: uppercase;
        }
        .content {
            padding: 40px;
            color: #333333;
            line-height: 1.6;
        }
        .otp-container {
            background-color: #f9f9f9;
            border: 2px dashed #7A0000;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
            margin: 30px 0;
        }
        .otp-code {
            font-size: 42px;
            font-weight: 900;
            color: #7A0000;
            letter-spacing: 10px;
        }
        .footer {
            background-color: #f9f9f9;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #888888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Pardede Catering</h1>
        </div>
        <div class="content">
            <h2 style="color: #7A0000;">Halo, {{ $userName }}!</h2>
            <p>Kami menerima permintaan untuk mengatur ulang kata sandi akun Anda. Gunakan kode verifikasi di bawah ini untuk melanjutkan:</p>
            
            <div class="otp-container">
                <div class="otp-code">{{ $otp }}</div>
                <p style="margin-top: 10px; font-size: 14px; color: #666;">Kode ini berlaku selama 15 menit.</p>
            </div>
            
            <p>Jika Anda tidak merasa melakukan permintaan ini, silakan abaikan email ini. Keamanan akun Anda adalah prioritas kami.</p>
            
            <p>Terika kasih,<br><strong>Tim Pardede Catering</strong></p>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} Pardede Catering. Seluruh Hak Cipta Dilindungi.<br>
            Tradisi Kemewahan dalam Setiap Sajian.
        </div>
    </div>
</body>
</html>
