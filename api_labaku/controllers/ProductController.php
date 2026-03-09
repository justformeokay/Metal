<?php
/**
 * Product Controller
 * 
 * Handles product CRUD operations.
 * All routes require authentication and store ownership verification.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Product.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class ProductController
{
    private PDO $db;
    private Product $productModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
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
     * POST /api/products/create
     * 
     * Create a new product.
     * 
     * Request body:
     *   - store_id: int (required)
     *   - name: string (required)
     *   - cost_price: float (optional)
     *   - sell_price: float (optional)
     *   - stock: int (optional)
     *   - unit: string (optional)
     *   - category: string (optional)
     */
    public function create(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];
        if (empty($data['store_id'])) $errors[] = 'Store ID is required';
        if (empty($data['name'])) $errors[] = 'Product name is required';

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        // Verify store ownership
        $this->verifyStoreAccess((int) $data['store_id'], $auth['user_id']);

        $this->productModel->store_id = (int) $data['store_id'];
        $this->productModel->name = trim($data['name']);
        $this->productModel->cost_price = (float) ($data['cost_price'] ?? 0);
        $this->productModel->sell_price = (float) ($data['sell_price'] ?? 0);
        $this->productModel->stock = (int) ($data['stock'] ?? 0);
        $this->productModel->unit = $data['unit'] ?? 'pcs';
        $this->productModel->category = $data['category'] ?? null;

        if ($this->productModel->create()) {
            $product = $this->productModel->findById($this->productModel->id);
            Response::success('Product created successfully', $product, 201);
        }

        Response::error('Failed to create product', 500);
    }

    /**
     * GET /api/products/list
     * 
     * Get all products for a store.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - category: string (optional)
     *   - search: string (optional)
     */
    public function list(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $category = $_GET['category'] ?? null;
        $search = $_GET['search'] ?? null;

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        // Verify store ownership
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $products = $this->productModel->getByStoreId($storeId, $category, $search);
        Response::success('Products retrieved successfully', $products);
    }

    /**
     * PUT /api/products/update
     * 
     * Update a product.
     * 
     * Request body:
     *   - id: int (required)
     *   - store_id: int (required)
     *   - name: string (required)
     *   - cost_price: float
     *   - sell_price: float
     *   - stock: int
     *   - unit: string
     *   - category: string
     */
    public function update(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];
        if (empty($data['id'])) $errors[] = 'Product ID is required';
        if (empty($data['store_id'])) $errors[] = 'Store ID is required';
        if (empty($data['name'])) $errors[] = 'Product name is required';

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        // Verify store ownership
        $this->verifyStoreAccess((int) $data['store_id'], $auth['user_id']);

        // Verify product exists in the store
        $existing = $this->productModel->findById((int) $data['id']);
        if ($existing === null || (int) $existing['store_id'] !== (int) $data['store_id']) {
            Response::error('Product not found', 404);
        }

        $this->productModel->id = (int) $data['id'];
        $this->productModel->store_id = (int) $data['store_id'];
        $this->productModel->name = trim($data['name']);
        $this->productModel->cost_price = (float) ($data['cost_price'] ?? 0);
        $this->productModel->sell_price = (float) ($data['sell_price'] ?? 0);
        $this->productModel->stock = (int) ($data['stock'] ?? 0);
        $this->productModel->unit = $data['unit'] ?? 'pcs';
        $this->productModel->category = $data['category'] ?? null;

        if ($this->productModel->update()) {
            $product = $this->productModel->findById($this->productModel->id);
            Response::success('Product updated successfully', $product);
        }

        Response::error('Failed to update product', 500);
    }

    /**
     * DELETE /api/products/delete
     * 
     * Delete a product.
     * 
     * Query parameters:
     *   - id: int (required)
     *   - store_id: int (required)
     */
    public function delete(): void
    {
        $auth = AuthMiddleware::authenticate();

        $productId = isset($_GET['id']) ? (int) $_GET['id'] : 0;
        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;

        if ($productId === 0 || $storeId === 0) {
            Response::error('Product ID and Store ID are required', 400);
        }

        // Verify store ownership
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        if ($this->productModel->delete($productId, $storeId)) {
            Response::success('Product deleted successfully');
        }

        Response::error('Product not found or already deleted', 404);
    }

    /**
     * GET /api/products/low-stock
     * 
     * Get products with low stock.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - threshold: int (optional, default: 5)
     */
    public function lowStock(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $threshold = isset($_GET['threshold']) ? (int) $_GET['threshold'] : 5;

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $products = $this->productModel->getLowStock($storeId, $threshold);
        Response::success('Low stock products retrieved', $products);
    }
}
