<?php
/**
 * Transaction Model
 * 
 * Handles all database operations for sales transactions.
 * Includes transaction creation with items and stock reduction.
 */

class Transaction
{
    private PDO $conn;
    private string $table = 'transactions';
    private string $itemsTable = 'transaction_items';

    // Properties
    public ?int $id = null;
    public ?int $store_id = null;
    public ?float $total_amount = null;
    public ?string $created_at = null;

    public function __construct(PDO $db)
    {
        $this->conn = $db;
    }

    /**
     * Create a new transaction with items (uses DB transaction for atomicity)
     *
     * @param array $items  Array of items: [{product_id, quantity, price, subtotal}]
     * @return bool
     */
    public function createWithItems(array $items): bool
    {
        try {
            $this->conn->beginTransaction();

            // Insert transaction
            $query = "INSERT INTO {$this->table} (store_id, total_amount) VALUES (:store_id, :total_amount)";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':store_id', $this->store_id, PDO::PARAM_INT);
            $stmt->bindParam(':total_amount', $this->total_amount);
            $stmt->execute();

            $this->id = (int) $this->conn->lastInsertId();

            // Insert transaction items and reduce stock
            $itemQuery = "INSERT INTO {$this->itemsTable} 
                          (transaction_id, product_id, quantity, price, subtotal) 
                          VALUES (:transaction_id, :product_id, :quantity, :price, :subtotal)";
            $itemStmt = $this->conn->prepare($itemQuery);

            $stockQuery = "UPDATE products SET stock = stock - :quantity WHERE id = :product_id AND stock >= :quantity";
            $stockStmt = $this->conn->prepare($stockQuery);

            foreach ($items as $item) {
                // Insert item
                $itemStmt->bindParam(':transaction_id', $this->id, PDO::PARAM_INT);
                $itemStmt->bindValue(':product_id', (int) $item['product_id'], PDO::PARAM_INT);
                $itemStmt->bindValue(':quantity', (int) $item['quantity'], PDO::PARAM_INT);
                $itemStmt->bindValue(':price', (float) $item['price']);
                $itemStmt->bindValue(':subtotal', (float) $item['subtotal']);
                $itemStmt->execute();

                // Reduce stock
                $stockStmt->bindValue(':quantity', (int) $item['quantity'], PDO::PARAM_INT);
                $stockStmt->bindValue(':product_id', (int) $item['product_id'], PDO::PARAM_INT);
                $stockStmt->execute();

                // Check if stock reduction was successful
                if ($stockStmt->rowCount() === 0) {
                    $this->conn->rollBack();
                    return false;
                }
            }

            $this->conn->commit();
            return true;

        } catch (Exception $e) {
            $this->conn->rollBack();
            throw $e;
        }
    }

    /**
     * Get all transactions for a store
     */
    public function getByStoreId(int $storeId, ?string $startDate = null, ?string $endDate = null, int $limit = 50, int $offset = 0): array
    {
        $query = "SELECT id, store_id, total_amount, created_at 
                  FROM {$this->table} 
                  WHERE store_id = :store_id";
        $params = [':store_id' => $storeId];

        if ($startDate !== null) {
            $query .= " AND DATE(created_at) >= :start_date";
            $params[':start_date'] = $startDate;
        }

        if ($endDate !== null) {
            $query .= " AND DATE(created_at) <= :end_date";
            $params[':end_date'] = $endDate;
        }

        $query .= " ORDER BY created_at DESC LIMIT :limit OFFSET :offset";

        $stmt = $this->conn->prepare($query);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /**
     * Get transaction detail with items
     */
    public function getDetail(int $transactionId): ?array
    {
        // Get transaction
        $query = "SELECT id, store_id, total_amount, created_at 
                  FROM {$this->table} 
                  WHERE id = :id LIMIT 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $transactionId, PDO::PARAM_INT);
        $stmt->execute();

        $transaction = $stmt->fetch();
        if (!$transaction) {
            return null;
        }

        // Get items with product names
        $itemQuery = "SELECT ti.id, ti.product_id, p.name AS product_name, 
                             ti.quantity, ti.price, ti.subtotal 
                      FROM {$this->itemsTable} ti 
                      LEFT JOIN products p ON ti.product_id = p.id 
                      WHERE ti.transaction_id = :transaction_id";
        $itemStmt = $this->conn->prepare($itemQuery);
        $itemStmt->bindParam(':transaction_id', $transactionId, PDO::PARAM_INT);
        $itemStmt->execute();

        $transaction['items'] = $itemStmt->fetchAll();

        return $transaction;
    }

    /**
     * Get total sales for a date range
     */
    public function getTotalSales(int $storeId, string $startDate, string $endDate): float
    {
        $query = "SELECT COALESCE(SUM(total_amount), 0) 
                  FROM {$this->table} 
                  WHERE store_id = :store_id 
                  AND DATE(created_at) >= :start_date 
                  AND DATE(created_at) <= :end_date";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':start_date', $startDate);
        $stmt->bindParam(':end_date', $endDate);
        $stmt->execute();

        return (float) $stmt->fetchColumn();
    }

    /**
     * Get Cost of Goods Sold (COGS) for a date range
     */
    public function getCOGS(int $storeId, string $startDate, string $endDate): float
    {
        $query = "SELECT COALESCE(SUM(ti.quantity * p.cost_price), 0)
                  FROM {$this->table} t
                  JOIN {$this->itemsTable} ti ON t.id = ti.transaction_id
                  JOIN products p ON ti.product_id = p.id
                  WHERE t.store_id = :store_id
                  AND DATE(t.created_at) >= :start_date
                  AND DATE(t.created_at) <= :end_date";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->bindParam(':start_date', $startDate);
        $stmt->bindParam(':end_date', $endDate);
        $stmt->execute();

        return (float) $stmt->fetchColumn();
    }

    /**
     * Count transactions for a store
     */
    public function countByStoreId(int $storeId): int
    {
        $query = "SELECT COUNT(*) FROM {$this->table} WHERE store_id = :store_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':store_id', $storeId, PDO::PARAM_INT);
        $stmt->execute();

        return (int) $stmt->fetchColumn();
    }
}
