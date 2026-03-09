<?php
/**
 * Expense Model
 * 
 * Handles all database operations for business expenses.
 */

class Expense
{
    private PDO $conn;
    private string $table = 'expenses';

    // Properties
    public ?int $id = null;
    public ?int $store_id = null;
    public ?string $name = null;
    public ?string $category = null;
    public ?float $amount = null;
    public ?string $notes = null;
    public ?string $expense_date = null;
    public ?string $created_at = null;

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Create a new expense
     */
    public function create(): bool
    {
        $query = "INSERT INTO {$this->table} 
                  (store_id, name, category, amount, notes, expense_date) 
                  VALUES (:store_id, :name, :category, :amount, :notes, :expense_date)";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':category', $this->category);
        $stmt->bindParam(':amount', $this->amount);
        $stmt->bindParam(':notes', $this->notes);
        $stmt->bindParam(':expense_date', $this->expense_date);

        if ($stmt->execute()) {
            $this->id = (int) $this->conn->lastInsertId();
            return true;
        }

        return false;
    }

    /**
     * Get all expenses for a store
     */
    public function getByStoreId(int $storeId, ?string $startDate = null, ?string $endDate = null, ?string $category = null): array
    {
        $query = "SELECT id, store_id, name, category, amount, notes, expense_date, created_at 
                  FROM {$this->table} 
                  WHERE store_id = :store_id";
        $params = [':store_id' => $storeId];

        if ($startDate !== null) {
            $query .= " AND expense_date >= :start_date";
            $params[':start_date'] = $startDate;
        }

        if ($endDate !== null) {
            $query .= " AND expense_date <= :end_date";
            $params[':end_date'] = $endDate;
        }

        if ($category !== null && $category !== '') {
            $query .= " AND category = :category";
            $params[':category'] = $category;
        }

        $query .= " ORDER BY expense_date DESC, created_at DESC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /**
     * Find expense by ID
     */
    public function findById(int $id): ?array
    {
        $query = "SELECT id, store_id, name, category, amount, notes, expense_date, created_at 
                  FROM {$this->table} 
                  WHERE id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Update expense
     */
    public function update(): bool
    {
        $query = "UPDATE {$this->table} 
                  SET name = :name, category = :category, amount = :amount, 
                      notes = :notes, expense_date = :expense_date 
                  WHERE id = :id AND store_id = :store_id";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':category', $this->category);
        $stmt->bindParam(':amount', $this->amount);
        $stmt->bindParam(':notes', $this->notes);
        $stmt->bindParam(':expense_date', $this->expense_date);
        $stmt->bindParam(':id', $this->id, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);

        return $stmt->execute() && $stmt->rowCount() > 0;
    }

    /**
     * Delete expense
     */
    public function delete(int $id, int $storeId): bool
    {
        $query = "DELETE FROM {$this->table} WHERE id = :id AND store_id = :store_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);

        return $stmt->execute() && $stmt->rowCount() > 0;
    }

    /**
     * Get total expenses for a date range
     */
    public function getTotalExpenses(int $storeId, string $startDate, string $endDate): float
    {
        $query = "SELECT COALESCE(SUM(amount), 0) 
                  FROM {$this->table} 
                  WHERE store_id = :store_id 
                  AND expense_date >= :start_date 
                  AND expense_date <= :end_date";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':start_date', $startDate);
        $stmt->bindParam(':end_date', $endDate);
        $stmt->execute();

        return (float) $stmt->fetchColumn();
    }

    /**
     * Get expense categories for a store
     */
    public function getCategories(int $storeId): array
    {
        $query = "SELECT DISTINCT category FROM {$this->table} 
                  WHERE store_id = :store_id AND category IS NOT NULL AND category != '' 
                  ORDER BY category";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_COLUMN);
    }
}
