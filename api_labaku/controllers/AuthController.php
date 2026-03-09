<?php
/**
 * Auth Controller
 * 
 * Handles user registration, login, and password reset.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../utils/Response.php';
require_once __DIR__ . '/../utils/JwtHelper.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';

class AuthController
{
    private PDO $db;
    private User $userModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->userModel = new User($this->db);
    }

    /**
     * POST /api/register
     * 
     * Register a new user account.
     * 
     * Request body:
     *   - name:                  string (required)
     *   - email:                 string (required, valid email)
     *   - phone:                 string (required)
     *   - password:              string (required, min 6 chars)
     *   - password_confirmation: string (required, must match password)
     */
    public function register(): void
    {
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];

        if (empty($data['name'])) {
            $errors[] = 'Nama lengkap wajib diisi';
        } elseif (strlen(trim($data['name'])) < 2) {
            $errors[] = 'Nama minimal 2 karakter';
        }

        if (empty($data['email'])) {
            $errors[] = 'Email wajib diisi';
        } elseif (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'Format email tidak valid';
        }

        if (empty($data['phone'])) {
            $errors[] = 'Nomor telepon wajib diisi';
        } elseif (!preg_match('/^[0-9+\-\s]{7,20}$/', $data['phone'])) {
            $errors[] = 'Format nomor telepon tidak valid';
        }

        if (empty($data['password'])) {
            $errors[] = 'Password wajib diisi';
        } elseif (strlen($data['password']) < 6) {
            $errors[] = 'Password minimal 6 karakter';
        }

        if (empty($data['password_confirmation'])) {
            $errors[] = 'Konfirmasi password wajib diisi';
        } elseif ($data['password'] !== $data['password_confirmation']) {
            $errors[] = 'Password dan konfirmasi password tidak cocok';
        }

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        // Check if email already exists
        if ($this->userModel->emailExists($data['email'])) {
            Response::error('Email sudah terdaftar', 409);
        }

        // Create user
        $this->userModel->name     = trim($data['name']);
        $this->userModel->email    = strtolower(trim($data['email']));
        $this->userModel->phone    = trim($data['phone']);
        $this->userModel->password = $data['password'];

        if ($this->userModel->create()) {
            // Generate token for immediate login after registration
            $token = JwtHelper::generateToken([
                'user_id' => $this->userModel->id,
                'email'   => $this->userModel->email
            ]);

            Response::success('Registrasi berhasil', [
                'token' => $token,
                'user'  => [
                    'id'    => $this->userModel->id,
                    'name'  => $this->userModel->name,
                    'email' => $this->userModel->email,
                    'phone' => $this->userModel->phone
                ]
            ], 201);
        }

        Response::error('Registrasi gagal. Silakan coba lagi.', 500);
    }

    /**
     * POST /api/login
     * 
     * Authenticate user and return JWT token.
     * 
     * Request body:
     *   - email: string (required)
     *   - password: string (required)
     */
    public function login(): void
    {
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        if (empty($data['email']) || empty($data['password'])) {
            Response::error('Email and password are required', 400);
        }

        // Find user by email
        $user = $this->userModel->findByEmail($data['email']);

        if ($user === null) {
            Response::error('Invalid credentials', 401);
        }

        // Verify password
        if (!password_verify($data['password'], $user['password'])) {
            Response::error('Invalid credentials', 401);
        }

        // Generate JWT token
        $token = JwtHelper::generateToken([
            'user_id' => $user['id'],
            'email'   => $user['email']
        ]);

        Response::success('Login successful', [
            'token' => $token,
            'user'  => [
                'id'    => (int) $user['id'],
                'name'  => $user['name']  ?? '',
                'email' => $user['email'],
                'phone' => $user['phone'] ?? ''
            ]
        ]);
    }

    /**
     * POST /api/forgot-password
     * 
     * Generate a password reset token.
     * In production, this would send an email with a reset link.
     * 
     * Request body:
     *   - email: string (required)
     */
    public function forgotPassword(): void
    {
        $data = json_decode(file_get_contents('php://input'), true);

        if (empty($data['email'])) {
            Response::error('Email is required', 400);
        }

        $user = $this->userModel->findByEmail($data['email']);

        // Always return success to prevent email enumeration
        if ($user === null) {
            Response::success('If the email exists, a reset token has been generated');
            return;
        }

        // Generate reset token
        $resetToken = bin2hex(random_bytes(32));
        $this->userModel->setResetToken($user['id'], $resetToken);

        // In production, you should send this token via email
        // For development, we return it directly
        Response::success('Password reset token generated', [
            'reset_token' => $resetToken,
            'note'        => 'In production, this token would be sent via email'
        ]);
    }

    /**
     * POST /api/reset-password
     * 
     * Reset password using the reset token.
     * 
     * Request body:
     *   - email: string (required)
     *   - reset_token: string (required)
     *   - new_password: string (required, min 6 chars)
     */
    public function resetPassword(): void
    {
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];
        if (empty($data['email'])) $errors[] = 'Email is required';
        if (empty($data['reset_token'])) $errors[] = 'Reset token is required';
        if (empty($data['new_password'])) {
            $errors[] = 'New password is required';
        } elseif (strlen($data['new_password']) < 6) {
            $errors[] = 'Password must be at least 6 characters';
        }

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        // Verify reset token
        $user = $this->userModel->verifyResetToken($data['email'], $data['reset_token']);

        if ($user === null) {
            Response::error('Invalid or expired reset token', 400);
        }

        // Update password
        $this->userModel->updatePassword($user['id'], $data['new_password']);
        $this->userModel->clearResetToken($user['id']);

        Response::success('Password has been reset successfully');
    }

    /**
     * POST /api/refresh-token
     *
     * Issue a fresh JWT using the current (still-valid) token.
     * The request must carry the existing Bearer token in the Authorization header.
     */
    public function refreshToken(): void
    {
        // AuthMiddleware already verified the token and returned the payload
        $payload = AuthMiddleware::authenticate();

        // Re-fetch user to ensure they still exist
        $user = $this->userModel->findById($payload['user_id']);
        if ($user === null) {
            Response::error('User not found', 404);
        }

        // Generate a brand-new token with a fresh expiry
        $newToken = JwtHelper::generateToken([
            'user_id' => $user['id'],
            'email'   => $user['email']
        ]);

        Response::success('Token refreshed', [
            'token' => $newToken,
            'user'  => [
                'id'    => (int) $user['id'],
                'name'  => $user['name']  ?? '',
                'email' => $user['email'],
                'phone' => $user['phone'] ?? ''
            ]
        ]);
    }
}
