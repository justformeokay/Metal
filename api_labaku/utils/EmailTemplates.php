<?php
/**
 * Email Templates
 *
 * Branded HTML email templates for Metal. application.
 */

class EmailTemplates
{
    /**
     * OTP verification email with styled digit boxes.
     */
    public static function otpEmail(string $name, string $otpCode): string
    {
        $digits = str_split($otpCode);
        $digitBoxes = '';
        foreach ($digits as $d) {
            $digitBoxes .= <<<HTML
            <td style="padding:0 4px;">
              <div style="width:48px;height:56px;background:#2563EB;color:#ffffff;
                          font-size:26px;font-weight:700;line-height:56px;
                          text-align:center;border-radius:10px;">
                {$d}
              </div>
            </td>
            HTML;
        }

        return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f4f6f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f9;padding:40px 0;">
<tr><td align="center">
<table width="480" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">

  <!-- Header -->
  <tr><td style="background:linear-gradient(135deg,#2563EB,#1d4ed8);padding:32px 40px;text-align:center;">
    <h1 style="color:#ffffff;font-size:28px;font-weight:700;margin:0;">Metal.</h1>
    <p style="color:rgba(255,255,255,0.85);font-size:13px;margin:6px 0 0;">Kode Verifikasi OTP</p>
  </td></tr>

  <!-- Body -->
  <tr><td style="padding:36px 40px;">
    <p style="font-size:15px;color:#1e293b;margin:0 0 8px;">Halo <strong>{$name}</strong>,</p>
    <p style="font-size:14px;color:#64748b;line-height:1.6;margin:0 0 28px;">
      Gunakan kode OTP berikut untuk mengatur ulang password akun Metal. Anda:
    </p>

    <!-- OTP Digits -->
    <table cellpadding="0" cellspacing="0" style="margin:0 auto 28px;">
      <tr>{$digitBoxes}</tr>
    </table>

    <p style="font-size:13px;color:#64748b;text-align:center;margin:0 0 24px;">
      Kode ini berlaku selama <strong>10 menit</strong>.
    </p>

    <!-- Warning -->
    <div style="background:#fef3c7;border-left:4px solid #f59e0b;padding:14px 18px;border-radius:8px;margin:0 0 24px;">
      <p style="font-size:13px;color:#92400e;margin:0;">
        <strong>Jangan bagikan kode ini kepada siapapun.</strong><br>
        Tim Metal. tidak pernah meminta kode OTP Anda.
      </p>
    </div>

    <p style="font-size:13px;color:#94a3b8;margin:0;">
      Jika Anda tidak meminta reset password, abaikan email ini.
    </p>
  </td></tr>

  <!-- Footer -->
  <tr><td style="background:#f8fafc;padding:20px 40px;text-align:center;border-top:1px solid #e2e8f0;">
    <p style="font-size:12px;color:#94a3b8;margin:0;">© 2026 Metal. — Kelola Keuangan Usahamu</p>
  </td></tr>

</table>
</td></tr>
</table>
</body>
</html>
HTML;
    }

    /**
     * Welcome email sent after registration.
     */
    public static function welcomeEmail(string $name): string
    {
        return <<<HTML
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>Selamat Datang di Metal.</title>
</head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:48px 16px;">
<tr><td align="center">
<table width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);max-width:520px;">

  <!-- ===== HEADER ===== -->
  <tr>
    <td style="background:linear-gradient(135deg,#1e40af 0%,#2563EB 50%,#3b82f6 100%);padding:40px 40px 32px;text-align:center;">
      <img src="https://ucs.mathlab.id/assets/logo.png"
           alt="Metal."
           width="80"
           style="display:block;margin:0 auto 16px;border-radius:16px;" />
      <h1 style="color:#ffffff;font-size:30px;font-weight:800;margin:0 0 6px;letter-spacing:-0.5px;">Metal.</h1>
      <p style="color:rgba(255,255,255,0.80);font-size:13px;font-weight:400;margin:0;letter-spacing:0.4px;text-transform:uppercase;">
        Solusi Keuangan untuk UMKM
      </p>
    </td>
  </tr>

  <!-- ===== WELCOME BADGE ===== -->
  <tr>
    <td style="padding:0 40px;">
      <div style="background:linear-gradient(135deg,#ecfdf5,#d1fae5);border:1px solid #6ee7b7;border-radius:12px;padding:14px 20px;text-align:center;margin-top:-1px;">
        <p style="font-size:14px;color:#065f46;font-weight:600;margin:0;">
          ✅ &nbsp;Akun Anda berhasil dibuat
        </p>
      </div>
    </td>
  </tr>

  <!-- ===== GREETING ===== -->
  <tr>
    <td style="padding:32px 40px 20px;">
      <p style="font-size:22px;font-weight:700;color:#0f172a;margin:0 0 16px;">
        Halo, {$name}!
      </p>
      <p style="font-size:15px;color:#475569;line-height:1.75;margin:0 0 16px;">
        Selamat datang di <strong style="color:#2563EB;">Metal.</strong> — kami sangat senang menyambut Anda!
        Terima kasih telah mempercayakan pengelolaan keuangan usaha Anda kepada kami.
      </p>
      <p style="font-size:15px;color:#475569;line-height:1.75;margin:0;">
        Metal. hadir untuk membantu Anda mencatat transaksi, mengelola produk,
        dan memantau perkembangan bisnis secara real-time — semua dalam satu platform
        yang mudah digunakan.
      </p>
    </td>
  </tr>

  <!-- ===== DIVIDER ===== -->
  <tr>
    <td style="padding:0 40px;">
      <hr style="border:none;border-top:1px solid #e2e8f0;margin:0;" />
    </td>
  </tr>

  <!-- ===== FEATURES ===== -->
  <tr>
    <td style="padding:28px 40px 8px;">
      <p style="font-size:13px;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:0.8px;margin:0 0 20px;">
        Yang bisa Anda lakukan di Metal.
      </p>

      <!-- Feature 1 -->
      <table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:16px;">
        <tr>
          <td width="48" valign="top">
            <div style="width:40px;height:40px;background:#eff6ff;border-radius:10px;text-align:center;line-height:40px;font-size:20px;">📦</div>
          </td>
          <td style="padding-left:14px;">
            <p style="font-size:14px;font-weight:600;color:#1e293b;margin:0 0 2px;">Kelola Produk &amp; Stok</p>
            <p style="font-size:13px;color:#64748b;margin:0;line-height:1.5;">Tambah, perbarui, dan pantau stok produk usaha Anda kapan saja.</p>
          </td>
        </tr>
      </table>

      <!-- Feature 2 -->
      <table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:16px;">
        <tr>
          <td width="48" valign="top">
            <div style="width:40px;height:40px;background:#f0fdf4;border-radius:10px;text-align:center;line-height:40px;font-size:20px;">💳</div>
          </td>
          <td style="padding-left:14px;">
            <p style="font-size:14px;font-weight:600;color:#1e293b;margin:0 0 2px;">Catat Transaksi</p>
            <p style="font-size:13px;color:#64748b;margin:0;line-height:1.5;">Rekam setiap pemasukan dan pengeluaran dengan cepat dan akurat.</p>
          </td>
        </tr>
      </table>

      <!-- Feature 3 -->
      <table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:8px;">
        <tr>
          <td width="48" valign="top">
            <div style="width:40px;height:40px;background:#fff7ed;border-radius:10px;text-align:center;line-height:40px;font-size:20px;">📊</div>
          </td>
          <td style="padding-left:14px;">
            <p style="font-size:14px;font-weight:600;color:#1e293b;margin:0 0 2px;">Laporan Keuangan</p>
            <p style="font-size:13px;color:#64748b;margin:0;line-height:1.5;">Dapatkan insight bisnis melalui laporan otomatis yang mudah dipahami.</p>
          </td>
        </tr>
      </table>
    </td>
  </tr>

  <!-- ===== DIVIDER ===== -->
  <tr>
    <td style="padding:24px 40px 0;">
      <hr style="border:none;border-top:1px solid #e2e8f0;margin:0;" />
    </td>
  </tr>

  <!-- ===== CLOSING ===== -->
  <tr>
    <td style="padding:24px 40px 32px;">
      <p style="font-size:15px;color:#475569;line-height:1.75;margin:0 0 20px;">
        Jika Anda memiliki pertanyaan atau membutuhkan bantuan, jangan ragu untuk menghubungi kami melalui media sosial kami di bawah ini. Kami siap membantu!
      </p>
      <p style="font-size:14px;color:#0f172a;margin:0;">
        Salam hangat,<br>
        <strong style="color:#2563EB;">Tim Metal.</strong>
      </p>
    </td>
  </tr>

  <!-- ===== FOOTER ===== -->
  <tr>
    <td style="background:#f8fafc;border-top:1px solid #e2e8f0;padding:28px 40px 32px;text-align:center;">

      <!-- Social Media -->
      <p style="font-size:12px;font-weight:600;color:#94a3b8;text-transform:uppercase;letter-spacing:0.8px;margin:0 0 16px;">
        Ikuti kami di
      </p>
      <table cellpadding="0" cellspacing="0" style="margin:0 auto 24px;">
        <tr>
          <!-- TikTok -->
          <td style="padding:0 8px;">
            <a href="https://tiktok.com/@metal.app" target="_blank"
               style="display:inline-block;background:#000000;color:#ffffff;
                      font-size:12px;font-weight:600;text-decoration:none;
                      padding:9px 18px;border-radius:8px;letter-spacing:0.3px;">
              TikTok
            </a>
          </td>
          <!-- Instagram -->
          <td style="padding:0 8px;">
            <a href="https://instagram.com/metal.app" target="_blank"
               style="display:inline-block;background:linear-gradient(45deg,#f09433,#e6683c,#dc2743,#cc2366,#bc1888);
                      color:#ffffff;font-size:12px;font-weight:600;text-decoration:none;
                      padding:9px 18px;border-radius:8px;letter-spacing:0.3px;">
              Instagram
            </a>
          </td>
          <!-- LinkedIn -->
          <td style="padding:0 8px;">
            <a href="https://linkedin.com/company/metal-app" target="_blank"
               style="display:inline-block;background:#0a66c2;color:#ffffff;
                      font-size:12px;font-weight:600;text-decoration:none;
                      padding:9px 18px;border-radius:8px;letter-spacing:0.3px;">
              LinkedIn
            </a>
          </td>
        </tr>
      </table>

      <!-- Copyright -->
      <p style="font-size:12px;color:#cbd5e1;margin:0 0 4px;">
        © 2026 <strong>Metal.</strong> — Kelola Keuangan Usahamu
      </p>
      <p style="font-size:11px;color:#e2e8f0;margin:0;">
        Email ini dikirim karena Anda baru saja mendaftar di Metal.
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>
HTML;
    }
}

