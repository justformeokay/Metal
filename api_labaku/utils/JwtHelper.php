<?php
/**
 * JWT Helper
 *
 * Lightweight JWT token generation and verification.
 * Uses HMAC-SHA256 for signing — no external library required.
 * Secret and expiry are loaded from .env via JwtHelper::init().
 */

require_once __DIR__ . '/../config/env.php';

class JwtHelper
{
    // Loaded from .env JWT_SECRET (falls back to hardcoded default if not set)
    private static string $secretKey = 'labaku_jwt_secret_key_2024_change_this_in_production';

    // Loaded from .env JWT_EXPIRY in seconds (default: 30 days)
    private static int $expiry = 2592000;

    /**
     * Bootstrap secrets from environment (called once in index.php)
     */
    public static function init(): void
    {
        // Only override if env values are present
        $envSecret = Env::get('JWT_SECRET');
        if ($envSecret !== null && $envSecret !== '') {
            self::$secretKey = $envSecret;
        }
        $envExpiry = Env::get('JWT_EXPIRY');
        if ($envExpiry !== null && is_numeric($envExpiry)) {
            self::$expiry = (int) $envExpiry;
        }
    }

    /**
     * Generate a JWT token
     *
     * @param array $payload  Data to encode in the token
     * @return string         Encoded JWT token
     */
    public static function generateToken(array $payload): string
    {
        // Header
        $header = self::base64UrlEncode(json_encode([
            'alg' => 'HS256',
            'typ' => 'JWT'
        ]));

        // Add standard claims
        $payload['iat'] = time();                    // Issued at
        $payload['exp'] = time() + self::$expiry;    // Expiration

        // Payload
        $payloadEncoded = self::base64UrlEncode(json_encode($payload));

        // Signature
        $signature = self::base64UrlEncode(
            hash_hmac('sha256', "{$header}.{$payloadEncoded}", self::$secretKey, true)
        );

        return "{$header}.{$payloadEncoded}.{$signature}";
    }

    /**
     * Verify and decode a JWT token
     *
     * @param string $token  JWT token to verify
     * @return array|null    Decoded payload or null if invalid
     */
    public static function verifyToken(string $token): ?array
    {
        $parts = explode('.', $token);

        if (count($parts) !== 3) {
            return null;
        }

        [$header, $payload, $signature] = $parts;

        // Verify signature
        $expectedSignature = self::base64UrlEncode(
            hash_hmac('sha256', "{$header}.{$payload}", self::$secretKey, true)
        );

        if (!hash_equals($expectedSignature, $signature)) {
            return null;
        }

        // Decode payload
        $decodedPayload = json_decode(self::base64UrlDecode($payload), true);

        if ($decodedPayload === null) {
            return null;
        }

        // Check expiration
        if (isset($decodedPayload['exp']) && $decodedPayload['exp'] < time()) {
            return null;
        }

        return $decodedPayload;
    }

    /**
     * Base64 URL-safe encoding
     */
    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Base64 URL-safe decoding
     */
    private static function base64UrlDecode(string $data): string
    {
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
