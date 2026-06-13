<!DOCTYPE html>
<html>
<head>
    <title>Kode Verifikasi Perubahan Profil</title>
</head>
<body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #A41215; text-align: center;">Catering Pardede</h2>
        
        <p>Halo <strong>{{ $name }}</strong>,</p>
        
        <p>Kami menerima permintaan untuk mengubah alamat email atau nomor telepon profil Anda. Gunakan kode verifikasi (OTP) berikut untuk mengonfirmasi perubahan ini:</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #A41215; background-color: #f9f9f9; padding: 15px 30px; border-radius: 8px; border: 1px dashed #A41215;">
                {{ $otp }}
            </span>
        </div>
        
        <p style="color: #666; font-size: 14px; text-align: center;">
            Kode ini berlaku selama <strong>5 menit</strong>. Jangan berikan kode ini kepada siapa pun.
        </p>

        <p>Jika Anda tidak merasa melakukan perubahan profil, abaikan email ini.</p>
        
        <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 30px 0;">
        <p style="font-size: 12px; color: #999; text-align: center;">
            &copy; {{ date('Y') }} Catering Pardede. Hak cipta dilindungi.
        </p>
    </div>
</body>
</html>
