<?php
/**
 * Authentication Middleware
 * 
 * Validates JWT token from the Authorization header.
 * Must be called before any protected route.
 */

require_once __DIR__ . '/../utils/JwtHelper.php';
require_once __DIR__ . '/../utils/Response.php';

class AuthMiddleware
{
    /**
     * Authenticate request using JWT token
     *
     * Extracts the Bearer token from the Authorization header,
     * verifies it, and returns the decoded payload.
     *
     * @return array  Decoded JWT payload containing user data
     */
    public static function authenticate(): array
    {
        // Get Authorization header
        $authHeader = self::getAuthorizationHeader();

        if ($authHeader === null || $authHeader === '') {
            Response::error('Authorization token is required', 401);
        }

        // Extract Bearer token
        if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
            Response::error('Invalid authorization format. Use: Bearer <token>', 401);
        }

        $token = $matches[1];

        // Verify token
        $decoded = JwtHelper::verifyToken($token);

        if ($decoded === null) {
            Response::error('Invalid or expired token', 401);
        }

        return $decoded;
    }

    /**
     * Get the Authorization header from various sources
     */
    private static function getAuthorizationHeader(): ?string
    {
        // Method 1: Standard header
        if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            return $_SERVER['HTTP_AUTHORIZATION'];
        }

        // Method 2: Apache redirect
        if (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            return $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }

        // Method 3: apache_request_headers() fallback
        if (function_exists('apache_request_headers')) {
            $headers = apache_request_headers();
            if (isset($headers['Authorization'])) {
                return $headers['Authorization'];
            }
            // Case-insensitive search
            foreach ($headers as $key => $value) {
                if (strtolower($key) === 'authorization') {
                    return $value;
                }
            }
        }

        // Method 4: getallheaders() fallback
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
            if (isset($headers['Authorization'])) {
                return $headers['Authorization'];
            }
        }

        return null;
    }
}
