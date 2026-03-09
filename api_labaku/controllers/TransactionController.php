<?php
/**
 * Transaction Controller
 * 
 * Handles sales transaction operations.
 * All routes require authentication and store ownership verification.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Transaction.php';
require_once __DIR__ . '/../models/Product.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class TransactionController
{
    private PDO $db;
    private Transaction $transactionModel;
    private Product $productModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->transactionModel = new Transaction($this->db);
        $this->productModel = new Product($this->db);
        $this->storeModel = new Store($this->db);
    }

    /**
     * Verify that the authenticated user owns the specified store
     */
    private function verifyStoreAccess(int $storeId, int $userId): void
    {
        if (!$this->storeModel->belongsToUser($storeId, $userId)) {
            Response::error('Store not found or access denied', 403);
        }
    }

    /**
     * POST /api/transactions/create
     * 
     * Create a new sales transaction with items.
     * Automatically reduces product stock.
     * 
     * Request body:
     *   - store_id: int (required)
     *   - items: array of objects (required)
     *       - product_id: int
     *       - quantity: int
     *       - price: float
     * 
     * Total amount and subtotals are calculated server-side.
     */
    public function create(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];
        if (empty($data['store_id'])) $errors[] = 'Store ID is required';
        if (empty($data['items']) || !is_array($data['items'])) $errors[] = 'Transaction items are required';

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        $storeId = (int) $data['store_id'];
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        // Validate and prepare items
        $totalAmount = 0;
        $preparedItems = [];

        foreach ($data['items'] as $index => $item) {
            if (empty($item['product_id']) || empty($item['quantity'])) {
                Response::error("Item at index {$index} is missing product_id or quantity", 400);
            }

            // Verify product exists and belongs to the store
            $product = $this->productModel->findById((int) $item['product_id']);
            if ($product === null || (int) $product['store_id'] !== $storeId) {
                Response::error("Product ID {$item['product_id']} not found in this store", 404);
            }

            // Check stock availability
            $quantity = (int) $item['quantity'];
            if ($quantity <= 0) {
                Response::error("Quantity for product '{$product['name']}' must be positive", 400);
            }
            if ($quantity > (int) $product['stock']) {
                Response::error("Insufficient stock for '{$product['name']}'. Available: {$product['stock']}", 400);
            }

            // Use provided price or product's sell_price
            $price = isset($item['price']) ? (float) $item['price'] : (float) $product['sell_price'];
            $subtotal = $price * $quantity;
            $totalAmount += $subtotal;

            $preparedItems[] = [
                'product_id' => (int) $item['product_id'],
                'quantity'   => $quantity,
                'price'      => $price,
                'subtotal'   => $subtotal
            ];
        }

        // Create transaction
        $this->transactionModel->store_id = $storeId;
        $this->transactionModel->total_amount = $totalAmount;

        try {
            if ($this->transactionModel->createWithItems($preparedItems)) {
                $transaction = $this->transactionModel->getDetail($this->transactionModel->id);
                Response::success('Transaction created successfully', $transaction, 201);
            }

            Response::error('Failed to create transaction. Possibly insufficient stock.', 400);
        } catch (Exception $e) {
            Response::error('Transaction failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * GET /api/transactions/list
     * 
     * Get all transactions for a store.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - start_date: string (optional, format: YYYY-MM-DD)
     *   - end_date: string (optional, format: YYYY-MM-DD)
     *   - limit: int (optional, default: 50)
     *   - offset: int (optional, default: 0)
     */
    public function list(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $startDate = $_GET['start_date'] ?? null;
        $endDate = $_GET['end_date'] ?? null;
        $limit = isset($_GET['limit']) ? (int) $_GET['limit'] : 50;
        $offset = isset($_GET['offset']) ? (int) $_GET['offset'] : 0;

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $transactions = $this->transactionModel->getByStoreId($storeId, $startDate, $endDate, $limit, $offset);
        $total = $this->transactionModel->countByStoreId($storeId);

        Response::success('Transactions retrieved successfully', [
            'transactions' => $transactions,
            'total'        => $total,
            'limit'        => $limit,
            'offset'       => $offset
        ]);
    }

    /**
     * GET /api/transactions/detail
     * 
     * Get a transaction detail with items.
     * 
     * Query parameters:
     *   - id: int (required)
     *   - store_id: int (required)
     */
    public function detail(): void
    {
        $auth = AuthMiddleware::authenticate();

        $transactionId = isset($_GET['id']) ? (int) $_GET['id'] : 0;
        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;

        if ($transactionId === 0 || $storeId === 0) {
            Response::error('Transaction ID and Store ID are required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $transaction = $this->transactionModel->getDetail($transactionId);

        if ($transaction === null || (int) $transaction['store_id'] !== $storeId) {
            Response::error('Transaction not found', 404);
        }

        Response::success('Transaction detail retrieved', $transaction);
    }
}
