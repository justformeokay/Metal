<?php
/**
 * Member Controller
 * 
 * Handles member CRUD operations.
 * All routes require authentication.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Member.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class MemberController
{
    private PDO $db;
    private Member $memberModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->memberModel = new Member($this->db);
        $this->storeModel = new Store($this->db);
    }

    private function verifyStoreAccess(int $storeId, int $userId): void
    {
        if (!$this->storeModel->belongsToUser($storeId, $userId)) {
            Response::error('Store not found or access denied', 403);
        }
    }

    /**
     * POST /api/member/create
     */
    public function create(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        $errors = [];
        if (empty($data['store_id'])) $errors[] = 'Store ID is required';
        if (empty($data['name'])) $errors[] = 'Member name is required';
        if (empty($data['phone'])) $errors[] = 'Phone number is required';

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        $this->verifyStoreAccess((int) $data['store_id'], $auth['user_id']);

        $this->memberModel->id = $data['id'] ?? (string) time();
        $this->memberModel->store_id = (int) $data['store_id'];
        $this->memberModel->name = trim($data['name']);
        $this->memberModel->phone = trim($data['phone']);
        $this->memberModel->email = isset($data['email']) ? trim($data['email']) : null;
        $this->memberModel->discount_percent = (float) ($data['discount_percent'] ?? 0);
        $this->memberModel->member_since = $data['member_since'] ?? date('Y-m-d\TH:i:s');
        $this->memberModel->status = $data['status'] ?? 'active';

        if ($this->memberModel->create()) {
            $member = $this->memberModel->findById($this->memberModel->id, (int) $data['store_id']);
            Response::success('Member created successfully', $member, 201);
        }

        Response::error('Failed to create member', 500);
    }

    /**
     * GET /api/member/list?store_id=X
     */
    public function list(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $members = $this->memberModel->getByStoreId($storeId);
        Response::success('Members retrieved successfully', $members);
    }

    /**
     * PUT /api/member/update
     */
    public function update(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        if (empty($data['id']) || empty($data['store_id'])) {
            Response::error('Member ID and Store ID are required', 400);
        }

        $this->verifyStoreAccess((int) $data['store_id'], $auth['user_id']);

        $existing = $this->memberModel->findById($data['id'], (int) $data['store_id']);
        if (!$existing) {
            Response::error('Member not found', 404);
        }

        $this->memberModel->id = $data['id'];
        $this->memberModel->store_id = (int) $data['store_id'];
        $this->memberModel->name = trim($data['name'] ?? $existing['name']);
        $this->memberModel->phone = trim($data['phone'] ?? $existing['phone']);
        $this->memberModel->email = isset($data['email']) ? trim($data['email']) : $existing['email'];
        $this->memberModel->discount_percent = (float) ($data['discount_percent'] ?? $existing['discount_percent']);
        $this->memberModel->status = $data['status'] ?? $existing['status'];

        if ($this->memberModel->update()) {
            $member = $this->memberModel->findById($data['id'], (int) $data['store_id']);
            Response::success('Member updated successfully', $member);
        }

        Response::error('Failed to update member', 500);
    }

    /**
     * DELETE /api/member/delete?id=X&store_id=Y
     */
    public function delete(): void
    {
        $auth = AuthMiddleware::authenticate();

        $id = $_GET['id'] ?? '';
        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;

        if (empty($id) || $storeId === 0) {
            Response::error('Member ID and Store ID are required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $existing = $this->memberModel->findById($id, $storeId);
        if (!$existing) {
            Response::error('Member not found', 404);
        }

        if ($this->memberModel->delete($id, $storeId)) {
            Response::success('Member deleted successfully');
        }

        Response::error('Failed to delete member', 500);
    }
}
