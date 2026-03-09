<?php
/**
 * Product Model
 * 
 * Handles all database operations for products.
 * Products belong to a store.
 */

class Product
{
    private PDO $conn;
    private string $table = 'products';

    // Properties
    public ?int $id = null;
    public ?int $store_id = null;
    public ?string $name = null;
    public ?float $cost_price = null;
    public ?float $sell_price = null;
    public ?int $stock = null;
    public ?string $unit = null;
    public ?string $category = null;
    public ?string $created_at = null;

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Create a new product
     */
    public function create(): bool
    {
        $query = "INSERT INTO {$this->table} 
                  (store_id, name, cost_price, sell_price, stock, unit, category) 
                  VALUES (:store_id, :name, :cost_price, :sell_price, :stock, :unit, :category)";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':cost_price', $this->cost_price);
        $stmt->bindParam(':sell_price', $this->sell_price);
        $stmt->bindParam(':stock', $this->stock, PDO::PARAM_INT);
        $stmt->bindParam(':unit', $this->unit);
        $stmt->bindParam(':category', $this->category);

        if ($stmt->execute()) {
            $this->id = (int) $this->conn->lastInsertId();
            return true;
        }

        return false;
    }

    /**
     * Get all products for a store
     */
    public function getByStoreId(int $storeId, ?string $category = null, ?string $search = null): array
    {
        $query = "SELECT id, store_id, name, cost_price, sell_price, stock, unit, category, created_at 
                  FROM {$this->table} 
                  WHERE store_id = :store_id";
        $params = [':store_id' => $storeId];

        if ($category !== null && $category !== '') {
            $query .= " AND category = :category";
            $params[':category'] = $category;
        }

        if ($search !== null && $search !== '') {
            $query .= " AND name LIKE :search";
            $params[':search'] = "%{$search}%";
        }

        $query .= " ORDER BY name ASC";

        $stmt = $this->conn->prepare($query);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /**
     * Find product by ID
     */
    public function findById(int $id): ?array
    {
        $query = "SELECT id, store_id, name, cost_price, sell_price, stock, unit, category, created_at 
                  FROM {$this->table} 
                  WHERE id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id, PDO::PARAM_INT);
        $stmt->execute();

        $row = $stmt->fetch();
        return $row ?: null;
    }

    /**
     * Update product
     */
    public function update(): bool
    {
        $query = "UPDATE {$this->table} 
                  SET name = :name, cost_price = :cost_price, sell_price = :sell_price, 
                      stock = :stock, unit = :unit, category = :category 
                  WHERE id = :id AND store_id = :store_id";
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':cost_price', $this->cost_price);
        $stmt->bindParam(':sell_price', $this->sell_price);
        $stmt->bindParam(':stock', $this->stock, PDO::PARAM_INT);
        $stmt->bindParam(':unit', $this->unit);
        $stmt->bindParam(':category', $this->category);
        $stmt->bindParam(':id', $this->id, PDO::PARAM_INT);
        $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);

        return $stmt->execute() && $stmt->rowCount() > 0;
    }

    /**
     * Delete product
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
     * Reduce stock after a sale
     */
    public function reduceStock(int $productId, int $quantity): bool
    {
        $query = "UPDATE {$this->table} SET stock = stock - :quantity WHERE id = :id AND stock >= :quantity";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':quantity', $quantity, PDO::PARAM_INT);
        $stmt->bindParam(':id', $productId, PDO::PARAM_INT);

        return $stmt->execute() && $stmt->rowCount() > 0;
    }

    /**
     * Get low stock products (stock <= threshold)
     */
    public function getLowStock(int $storeId, int $threshold = 5): array
    {
        $query = "SELECT id, store_id, name, cost_price, sell_price, stock, unit, category 
                  FROM {$this->table} 
                  WHERE store_id = :store_id AND stock <= :threshold 
                  ORDER BY stock ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':threshold', $threshold, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /**
     * Count total products in a store
     */
    public function countByStoreId(int $storeId): int
    {
        $query = "SELECT COUNT(*) FROM {$this->table} WHERE store_id = :store_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->execute();

        return (int) $stmt->fetchColumn();
    }

    /**
     * Get categories for a store
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
