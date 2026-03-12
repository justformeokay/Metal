<?php
/**
 * Member Model
 * 
 * Handles all database operations for store members/customers.
 * Members belong to a store and can have discount percentages.
 */

class Member
{
    private PDO $conn;
    private string $table = 'members';

    // Properties
    public ?string $id = null;
    public ?int $store_id = null;
    public ?string $name = null;
    public ?string $phone = null;
    public ?string $email = null;
    public ?float $discount_percent = 0;
    public ?string $member_since = null;
    public ?string $status = 'active';

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Create a new member
     */
    public function create(): bool
    {
        $query = "INSERT INTO {$this->table} (id, store_id, name, phone, email, discount_percent, member_since, status) 
                  VALUES (:id, :store_id, :name, :phone, :email, :discount_percent, :member_since, :status)";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':phone', $this->phone);
        $stmt->bindParam(':email', $this->email);
        $stmt->bindParam(':discount_percent', $this->discount_percent);
        $stmt->bindParam(':member_since', $this->member_since);
        $stmt->bindParam(':status', $this->status);

        return $stmt->execute();
    }

    /**
     * Get all members for a store
     */
    public function getByStoreId(int $storeId): array
    {
        $query = "SELECT id, store_id, name, phone, email, discount_percent, member_since, status 
                  FROM {$this->table} 
                  WHERE store_id = :store_id 
                  ORDER BY name ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Find a member by ID and store
     */
    public function findById(string $id, int $storeId): ?array
    {
        $query = "SELECT id, store_id, name, phone, email, discount_percent, member_since, status 
                  FROM {$this->table} 
                  WHERE id = :id AND store_id = :store_id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ?: null;
    }

    /**
     * Update a member
     */
    public function update(): bool
    {
        $query = "UPDATE {$this->table} 
                  SET name = :name, phone = :phone, email = :email, 
                      discount_percent = :discount_percent, status = :status
                  WHERE id = :id AND store_id = :store_id";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':phone', $this->phone);
        $stmt->bindParam(':email', $this->email);
        $stmt->bindParam(':discount_percent', $this->discount_percent);
        $stmt->bindParam(':status', $this->status);

        return $stmt->execute();
    }

    /**
     * Delete a member
     */
    public function delete(string $id, int $storeId): bool
    {
        $query = "DELETE FROM {$this->table} WHERE id = :id AND store_id = :store_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);

        return $stmt->execute();
    }
}
