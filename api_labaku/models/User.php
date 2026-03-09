<?php
/**
 * User Model
 * 
 * Handles all database operations for user authentication.
 * Users table is ONLY for authentication purposes.
 */

class User
{
    private PDO $conn;
    private string $table = 'users';

    // Properties
    public ?int $id = null;
    public ?string $name = null;
    public ?string $email = null;
    public ?string $phone = null;
    public ?string $password = null;
    public ?string $reset_token = null;
    public ?string $reset_token_expiry = null;
    public ?string $created_at = null;

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Register a new user
     */
    public function create(): bool
    {
        $query = "INSERT INTO {$this->table} (name, email, phone, password) VALUES (:name, :email, :phone, :password)";
        $stmt = $this->conn->prepare($query);

        // Hash password
        $hashedPassword = password_hash($this->password, PASSWORD_BCRYPT);

        $stmt->bindParam(':name',     $this->name);
        $stmt->bindParam(':email',    $this->email);
        $stmt->bindParam(':phone',    $this->phone);
        $stmt->bindParam(':password', $hashedPassword);

        if ($stmt->execute()) {
            $this->id = (int) $this->conn->lastInsertId();
            return true;
        }

        return false;
    }

    /**
     * Find user by email
     */
    public function findByEmail(string $email): ?array
    {
        $query = "SELECT id, name, email, phone, password, created_at FROM {$this->table} WHERE email = :email LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Find user by ID
     */
    public function findById(int $id): ?array
    {
        $query = "SELECT id, name, email, phone, created_at FROM {$this->table} WHERE id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Check if email already exists
     */
    public function emailExists(string $email): bool
    {
        $query = "SELECT COUNT(*) FROM {$this->table} WHERE email = :email";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        return $stmt->fetchColumn() > 0;
    }

    /**
     * Update password
     */
    public function updatePassword(int $userId, string $newPassword): bool
    {
        $hashed = password_hash($newPassword, PASSWORD_BCRYPT);
        $query = "UPDATE {$this->table} SET password = :password WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':password', $hashed);
        $stmt->bindParam(':id', $userId, PDO::PARAM_INT);

        return $stmt->execute();
    }

    /**
     * Set password reset token
     */
    public function setResetToken(int $userId, string $token): bool
    {
        $expiry = date('Y-m-d H:i:s', strtotime('+1 hour'));
        $hashedToken = hash('sha256', $token);

        $query = "UPDATE {$this->table} SET reset_token = :token, reset_token_expiry = :expiry WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':token', $hashedToken);
        $stmt->bindParam(':expiry', $expiry);
        $stmt->bindParam(':id', $userId, PDO::PARAM_INT);

        return $stmt->execute();
    }

    /**
     * Verify reset token
     */
    public function verifyResetToken(string $email, string $token): ?array
    {
        $hashedToken = hash('sha256', $token);

        $query = "SELECT id, email FROM {$this->table} 
                  WHERE email = :email 
                  AND reset_token = :token 
                  AND reset_token_expiry > NOW() 
                  LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':token', $hashedToken);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Clear reset token after successful password reset
     */
    public function clearResetToken(int $userId): bool
    {
        $query = "UPDATE {$this->table} SET reset_token = NULL, reset_token_expiry = NULL WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $userId, PDO::PARAM_INT);

        return $stmt->execute();
    }
}
