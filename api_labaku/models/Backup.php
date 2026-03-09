<?php
/**
 * Backup Model
 * 
 * Handles all database operations for cloud backups.
 * Stores JSON backup data tied to a user and store.
 */

class Backup
{
    private PDO $conn;
    private string $table = 'backups';

    // Properties
    public ?int $id = null;
    public ?int $user_id = null;
    public ?int $store_id = null;
    public ?string $backup_data = null;
    public ?int $backup_size = null;
    public ?string $device_name = null;
    public ?string $backup_type = 'manual';
    public ?string $created_at = null;

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Create a new backup (upload)
     */
    public function create(): bool
    {
        $query = "INSERT INTO {$this->table} (user_id, store_id, backup_data, backup_size, device_name, backup_type) 
                  VALUES (:user_id, :store_id, :backup_data, :backup_size, :device_name, :backup_type)";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':user_id', $this->user_id, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);
        $stmt->bindParam(':backup_data', $this->backup_data);
        $stmt->bindParam(':backup_size', $this->backup_size, PDO::PARAM_INT);
        $stmt->bindParam(':device_name', $this->device_name);
        $stmt->bindParam(':backup_type', $this->backup_type);

        if ($stmt->execute()) {
            $this->id = (int) $this->conn->lastInsertId();
            return true;
        }

        return false;
    }

    /**
     * Get the latest backup for a user + store
     */
    public function getLatest(int $userId, int $storeId): ?array
    {
        $query = "SELECT id, user_id, store_id, backup_data, backup_size, device_name, backup_type, created_at 
                  FROM {$this->table} 
                  WHERE user_id = :user_id AND store_id = :store_id
                  ORDER BY created_at DESC 
                  LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Get backup history (without the full data, for listing)
     */
    public function getHistory(int $userId, int $storeId, int $limit = 10): array
    {
        $query = "SELECT id, user_id, store_id, backup_size, device_name, backup_type, created_at 
                  FROM {$this->table} 
                  WHERE user_id = :user_id AND store_id = :store_id
                  ORDER BY created_at DESC 
                  LIMIT :lmt";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':lmt', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /**
     * Get a specific backup by ID (with ownership check)
     */
    public function findById(int $id, int $userId): ?array
    {
        $query = "SELECT id, user_id, store_id, backup_data, backup_size, device_name, backup_type, created_at 
                  FROM {$this->table} 
                  WHERE id = :id AND user_id = :user_id 
                  LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Delete old backups, keep only the latest N
     */
    public function cleanupOld(int $userId, int $storeId, int $keepCount = 5): int
    {
        // Get IDs to keep
        $query = "SELECT id FROM {$this->table} 
                  WHERE user_id = :user_id AND store_id = :store_id
                  ORDER BY created_at DESC 
                  LIMIT :keep";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':keep', $keepCount, PDO::PARAM_INT);
        $stmt->execute();

        $keepIds = array_column($stmt->fetchAll(), 'id');

        if (empty($keepIds)) {
            return 0;
        }

        // Delete all except the ones to keep
        $placeholders = implode(',', array_fill(0, count($keepIds), '?'));
        $deleteQuery = "DELETE FROM {$this->table} 
                        WHERE user_id = ? AND store_id = ? AND id NOT IN ($placeholders)";
        $deleteStmt = $this->conn->prepare($deleteQuery);

        $params = array_merge([$userId, $storeId], $keepIds);
        $deleteStmt->execute($params);

        return $deleteStmt->rowCount();
    }
}
