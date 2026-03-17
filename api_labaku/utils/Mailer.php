<?php
/**
 * Mailer Utility
 *
 * Thin wrapper around PHPMailer for sending HTML emails via SMTP.
 * Configuration is read from $_ENV (loaded by config/env.php).
 *
 * Usage:
 *   Mailer::send('user@example.com', 'Subject', '<p>HTML body</p>');
 */

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception as MailerException;

class Mailer
{
    /**
     * Send an HTML email.
     *
     * @param  string $toEmail    Recipient email address
     * @param  string $subject    Email subject
     * @param  string $htmlBody   Full HTML body
     * @return bool               true on success, false on failure
     */

    private const HOST = 'mail.karyadeveloperindonesia.com'; // Ganti dengan Host SMTP Webmail Anda
    private const USERNAME = 'no-reply@karyadeveloperindonesia.com'; // Ganti dengan Email Webmail Anda
    private const PASSWORD = 'Justformeokay23'; // Ganti dengan Password Webmail Anda
    private const PORT = 587; // Umumnya 587 (TLS) atau 465 (SSL)
    private const SENDER_NAME = 'Metal';

    public static function send(string $toEmail, string $subject, string $htmlBody): bool
    {
        $autoload = __DIR__ . '/../vendor/autoload.php';
        if (!file_exists($autoload)) {
            error_log('Mailer: vendor/autoload.php not found. Run `composer install`.');
            return false;
        }
        require_once $autoload;

        $mail = new PHPMailer(true);

        try {
            // ── Server config ──────────────────────────────────────
            $mail->isSMTP();
            $mail->SMTPDebug  = SMTP::DEBUG_OFF;
            $mail->Host       = self::HOST;
            $mail->SMTPAuth   = true;
            $mail->Username   = self::USERNAME;
            $mail->Password   = self::PASSWORD;
            $mail->CharSet    = 'UTF-8';
            $mail->Port       = self::PORT;
            $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;

            // Allow self-signed certificates (common on shared hosting)
            $mail->SMTPOptions = [
                'ssl' => [
                    'verify_peer'       => false,
                    'verify_peer_name'  => false,
                    'allow_self_signed' => true,
                ],
            ];

            // ── Sender & recipient ─────────────────────────────────
            $fromName = self::SENDER_NAME;
            $fromAddr = self::USERNAME;
            $mail->setFrom($fromAddr, $fromName);
            $mail->addAddress($toEmail);
            $mail->addReplyTo($fromAddr, $fromName);

            // ── Content ────────────────────────────────────────────
            $mail->isHTML(true);
            $mail->Subject = $subject;
            $mail->Body    = $htmlBody;
            $mail->AltBody = strip_tags(
                preg_replace(['/<br\s*\/?>/i', '/<\/p>/i', '/<\/tr>/i'], "\n", $htmlBody)
            );

            $mail->send();
            return true;

        } catch (MailerException $e) {
            error_log("Mailer: failed to send to {$toEmail}. Error: {$mail->ErrorInfo}");
            return false;
        }
    }
}
