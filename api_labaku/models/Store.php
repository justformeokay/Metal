<?php
/**
 * Store Model
 * 
 * Handles all database operations for stores.
 * Each user can own one or multiple stores.
 */

class Store
{
    private PDO $conn;
    private string $table = 'stores';

    // Properties
    public ?int $id = null;
    public ?int $user_id = null;
    public ?string $store_name = null;
    public ?string $phone = null;
    public ?string $address = null;
    public ?string $created_at = null;

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Create a new store
     */
    public function create(): bool
    {
        $query = "INSERT INTO {$this->table} (user_id, store_name, phone, address) 
                  VALUES (:user_id, :store_name, :phone, :address)";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':user_id', $this->user_id, PDO::PARAM_INT);
        $stmt->bindParam(':store_name', $this->store_name);
        $stmt->bindParam(':phone', $this->phone);
        $stmt->bindParam(':address', $this->address);

        if ($stmt->execute()) {
            $this->id = (int) $this->conn->lastInsertId();
            return true;
        }

        return false;
    }

    /**
     * Get all stores belonging to a user
     */
    public function getByUserId(int $userId): array
    {
        $query = "SELECT id, user_id, store_name, phone, address, created_at 
                  FROM {$this->table} 
                  WHERE user_id = :user_id 
                  ORDER BY created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /**
     * Get a store by ID
     */
    public function findById(int $id): ?array
    {
        $query = "SELECT id, user_id, store_name, phone, address, created_at 
                  FROM {$this->table} 
                  WHERE id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Update store details
     */
    public function update(): bool
    {
        $query = "UPDATE {$this->table} 
                  SET store_name = :store_name, phone = :phone, address = :address 
                  WHERE id = :id AND user_id = :user_id";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':store_name', $this->store_name);
        $stmt->bindParam(':phone', $this->phone);
        $stmt->bindParam(':address', $this->address);
        $stmt->bindParam(':id', $this->id, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $this->user_id, PDO::PARAM_INT);

        return $stmt->execute() && $stmt->rowCount() > 0;
    }

    /**
     * Delete a store
     */
    public function delete(int $id, int $userId): bool
    {
        $query = "DELETE FROM {$this->table} WHERE id = :id AND user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);

        return $stmt->execute() && $stmt->rowCount() > 0;
    }

    /**
     * Verify store ownership (check user owns the store)
     */
    public function belongsToUser(int $storeId, int $userId): bool
    {
        $query = "SELECT COUNT(*) FROM {$this->table} WHERE id = :id AND user_id = :user_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchColumn() > 0;
    }
}
