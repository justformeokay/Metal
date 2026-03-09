<?php
/**
 * Response Utility
 * 
 * Standardized JSON response helper for consistent API output.
 */

class Response
{
    /**
     * Send a success response
     *
     * @param string $message  Response message
     * @param mixed  $data     Response data (optional)
     * @param int    $code     HTTP status code (default: 200)
     */
    public static function success(string $message, mixed $data = null, int $code = 200): void
    {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');

        $response = [
            'success' => true,
            'message' => $message,
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    /**
     * Send an error response
     *
     * @param string $message  Error message
     * @param int    $code     HTTP status code (default: 400)
     * @param mixed  $errors   Additional error details (optional)
     */
    public static function error(string $message, int $code = 400, mixed $errors = null): void
    {
        http_response_code($code);
        header('Content-Type: application/json; charset=utf-8');

        $response = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $response['errors'] = $errors;
        }

        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    /**
     * Send a validation error response
     *
     * @param array $errors  Array of validation errors
     */
    public static function validationError(array $errors): void
    {
        self::error('Validation failed', 422, $errors);
    }
}
