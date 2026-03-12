<?php
/**
 * Store Controller
 * 
 * Handles store CRUD operations.
 * All routes require authentication.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class StoreController
{
    private PDO $db;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->storeModel = new Store($this->db);
    }

    /**
     * POST /api/store/create
     * 
     * Create a new store for the authenticated user.
     * 
     * Request body:
     *   - store_name: string (required)
     *   - business_type: string (optional)
     *   - logo_url: string (optional, URL from upload endpoint)
     *   - phone: string (optional)
     *   - address: string (optional)
     *   - description: string (optional)
     */
    public function create(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        if (empty($data['store_name'])) {
            Response::error('Store name is required', 400);
        }

        $this->storeModel->user_id = $auth['user_id'];
        $this->storeModel->store_name = trim($data['store_name']);
        $this->storeModel->business_type = $data['business_type'] ?? null;
        $this->storeModel->logo_url = $data['logo_url'] ?? null;
        $this->storeModel->phone = $data['phone'] ?? null;
        $this->storeModel->address = $data['address'] ?? null;
        $this->storeModel->description = $data['description'] ?? null;

        if ($this->storeModel->create()) {
            // Return the created store
            $store = $this->storeModel->findById($this->storeModel->id);
            Response::success('Store created successfully', $store, 201);
        }

        Response::error('Failed to create store', 500);
    }

    /**
     * GET /api/store/my-store
     * 
     * Get all stores belonging to the authenticated user.
     */
    public function myStore(): void
    {
        $auth = AuthMiddleware::authenticate();
        $stores = $this->storeModel->getByUserId($auth['user_id']);

        Response::success('Stores retrieved successfully', $stores);
    }

    /**
     * PUT /api/store/update
     * 
     * Update store details.
     * 
     * Request body:
     *   - store_id: int (required)
     *   - store_name: string (required)
     *   - phone: string (optional)
     *   - address: string (optional)
     *   - description: string (optional)
     */
    public function update(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        if (empty($data['store_id'])) {
            Response::error('Store ID is required', 400);
        }
        if (empty($data['store_name'])) {
            Response::error('Store name is required', 400);
        }

        // Verify ownership
        if (!$this->storeModel->belongsToUser($data['store_id'], $auth['user_id'])) {
            Response::error('Store not found or access denied', 403);
        }

        $this->storeModel->id = (int) $data['store_id'];
        $this->storeModel->user_id = $auth['user_id'];
        $this->storeModel->store_name = trim($data['store_name']);
        $this->storeModel->phone = $data['phone'] ?? null;
        $this->storeModel->address = $data['address'] ?? null;
        $this->storeModel->description = $data['description'] ?? null;

        if ($this->storeModel->update()) {
            $store = $this->storeModel->findById($this->storeModel->id);
            Response::success('Store updated successfully', $store);
        }

        Response::error('Failed to update store', 500);
    }
}
