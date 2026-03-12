<?php
/**
 * Upload Controller
 * 
 * Handles file uploads (images, logos, etc.)
 * All routes require authentication.
 */

require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class UploadController
{
    /**
     * POST /api/upload/store-logo
     * 
     * Upload store logo and return the file URL.
     * File is saved to /assets/{md5(user_id)}.{ext}
     * 
     * Request: multipart/form-data
     *   - file: image file (required, max 5MB, jpg/png/webp)
     * 
     * Response:
     *   {
     *     "success": true,
     *     "message": "Logo uploaded successfully",
     *     "data": {
     *       "url": "https://ucs.mathlab.id/assets/{hash}.jpg"
     *     }
     *   }
     */
    public static function uploadStoreLogo(): void
    {
        try {
            $auth = AuthMiddleware::authenticate();

            if (empty($_FILES['file'])) {
                Response::error('No file uploaded', 400);
            }

            if ($_FILES['file']['error'] !== UPLOAD_ERR_OK) {
                Response::error('File upload error: ' . $_FILES['file']['error'], 400);
            }

            $file = $_FILES['file'];

            // Detect MIME type
            $allowedMimes = ['image/jpeg', 'image/png', 'image/webp'];
            if (function_exists('finfo_open')) {
                $fileInfo = finfo_open(FILEINFO_MIME_TYPE);
                $detectedMime = finfo_file($fileInfo, $file['tmp_name']);
                finfo_close($fileInfo);
            } else {
                $detectedMime = $file['type'];
            }

            if (!in_array($detectedMime, $allowedMimes)) {
                Response::error('Only JPG, PNG, and WebP images are allowed', 400);
            }

            if ($file['size'] > 5 * 1024 * 1024) {
                Response::error('File size must not exceed 5MB', 400);
            }

            // Get extension from detected MIME type
            $ext = match ($detectedMime) {
                'image/jpeg' => 'jpg',
                'image/png'  => 'png',
                'image/webp' => 'webp',
                default      => 'jpg',
            };

            // Filename = md5 hash of user ID — no subdirectory
            $hash     = md5((string) $auth['user_id']);
            $filename = $hash . '.' . $ext;
            $assetsDir = __DIR__ . '/../../assets';
            $filepath  = $assetsDir . '/' . $filename;

            if (!is_writable($assetsDir)) {
                Response::error('Assets directory not writable', 500);
            }

            if (!move_uploaded_file($file['tmp_name'], $filepath)) {
                Response::error('Failed to save file', 500);
            }

            $url = 'https://ucs.mathlab.id/assets/' . $filename;

            Response::success('Logo uploaded successfully', ['url' => $url], 200);
        } catch (\Throwable $e) {
            Response::error('Upload failed: ' . $e->getMessage(), 500);
        }
    }
}
