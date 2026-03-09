<?php
/**
 * User Controller
 * 
 * Handles user profile operations.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/User.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class UserController
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
     * GET /api/user/profile
     * 
     * Get authenticated user's profile.
     */
    public function profile(): void
    {
        $auth = AuthMiddleware::authenticate();
        $user = $this->userModel->findById($auth['user_id']);

        if ($user === null) {
            Response::error('User not found', 404);
        }

        Response::success('User profile retrieved', $user);
    }

    /**
     * PUT /api/user/change-password
     * 
     * Change the authenticated user's password.
     * 
     * Request body:
     *   - current_password: string (required)
     *   - new_password: string (required, min 6 chars)
     */
    public function changePassword(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate
        if (empty($data['current_password']) || empty($data['new_password'])) {
            Response::error('Current password and new password are required', 400);
        }

        if (strlen($data['new_password']) < 6) {
            Response::error('New password must be at least 6 characters', 400);
        }

        // Verify current password
        $user = $this->userModel->findByEmail($auth['email']);
        if (!password_verify($data['current_password'], $user['password'])) {
            Response::error('Current password is incorrect', 401);
        }

        // Update password
        $this->userModel->updatePassword($auth['user_id'], $data['new_password']);
        Response::success('Password changed successfully');
    }
}
