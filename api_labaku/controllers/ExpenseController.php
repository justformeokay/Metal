<?php
/**
 * Expense Controller
 * 
 * Handles expense CRUD operations.
 * All routes require authentication and store ownership verification.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Expense.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class ExpenseController
{
    private PDO $db;
    private Expense $expenseModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->expenseModel = new Expense($this->db);
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
     * POST /api/expenses/create
     * 
     * Create a new expense record.
     * 
     * Request body:
     *   - store_id: int (required)
     *   - name: string (required)
     *   - amount: float (required)
     *   - category: string (optional)
     *   - notes: string (optional)
     *   - expense_date: string (required, format: YYYY-MM-DD)
     */
    public function create(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];
        if (empty($data['store_id'])) $errors[] = 'Store ID is required';
        if (empty($data['name'])) $errors[] = 'Expense name is required';
        if (!isset($data['amount']) || (float) $data['amount'] <= 0) $errors[] = 'Valid amount is required';
        if (empty($data['expense_date'])) $errors[] = 'Expense date is required';

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        // Validate date format
        $date = date_create($data['expense_date']);
        if (!$date) {
            Response::error('Invalid date format. Use YYYY-MM-DD', 400);
        }

        $storeId = (int) $data['store_id'];
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $this->expenseModel->store_id = $storeId;
        $this->expenseModel->name = trim($data['name']);
        $this->expenseModel->category = $data['category'] ?? null;
        $this->expenseModel->amount = (float) $data['amount'];
        $this->expenseModel->notes = $data['notes'] ?? null;
        $this->expenseModel->expense_date = $data['expense_date'];

        if ($this->expenseModel->create()) {
            $expense = $this->expenseModel->findById($this->expenseModel->id);
            Response::success('Expense created successfully', $expense, 201);
        }

        Response::error('Failed to create expense', 500);
    }

    /**
     * GET /api/expenses/list
     * 
     * Get expenses for a store.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - start_date: string (optional)
     *   - end_date: string (optional)
     *   - category: string (optional)
     */
    public function list(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $startDate = $_GET['start_date'] ?? null;
        $endDate = $_GET['end_date'] ?? null;
        $category = $_GET['category'] ?? null;

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $expenses = $this->expenseModel->getByStoreId($storeId, $startDate, $endDate, $category);
        Response::success('Expenses retrieved successfully', $expenses);
    }

    /**
     * PUT /api/expenses/update
     * 
     * Update an expense record.
     * 
     * Request body:
     *   - id: int (required)
     *   - store_id: int (required)
     *   - name: string (required)
     *   - amount: float (required)
     *   - category: string (optional)
     *   - notes: string (optional)
     *   - expense_date: string (required)
     */
    public function update(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate input
        $errors = [];
        if (empty($data['id'])) $errors[] = 'Expense ID is required';
        if (empty($data['store_id'])) $errors[] = 'Store ID is required';
        if (empty($data['name'])) $errors[] = 'Expense name is required';
        if (!isset($data['amount']) || (float) $data['amount'] <= 0) $errors[] = 'Valid amount is required';
        if (empty($data['expense_date'])) $errors[] = 'Expense date is required';

        if (!empty($errors)) {
            Response::validationError($errors);
        }

        $storeId = (int) $data['store_id'];
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        // Verify expense exists
        $existing = $this->expenseModel->findById((int) $data['id']);
        if ($existing === null || (int) $existing['store_id'] !== $storeId) {
            Response::error('Expense not found', 404);
        }

        $this->expenseModel->id = (int) $data['id'];
        $this->expenseModel->store_id = $storeId;
        $this->expenseModel->name = trim($data['name']);
        $this->expenseModel->category = $data['category'] ?? null;
        $this->expenseModel->amount = (float) $data['amount'];
        $this->expenseModel->notes = $data['notes'] ?? null;
        $this->expenseModel->expense_date = $data['expense_date'];

        if ($this->expenseModel->update()) {
            $expense = $this->expenseModel->findById($this->expenseModel->id);
            Response::success('Expense updated successfully', $expense);
        }

        Response::error('Failed to update expense', 500);
    }

    /**
     * DELETE /api/expenses/delete
     * 
     * Delete an expense record.
     * 
     * Query parameters:
     *   - id: int (required)
     *   - store_id: int (required)
     */
    public function delete(): void
    {
        $auth = AuthMiddleware::authenticate();

        $expenseId = isset($_GET['id']) ? (int) $_GET['id'] : 0;
        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;

        if ($expenseId === 0 || $storeId === 0) {
            Response::error('Expense ID and Store ID are required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        if ($this->expenseModel->delete($expenseId, $storeId)) {
            Response::success('Expense deleted successfully');
        }

        Response::error('Expense not found or already deleted', 404);
    }
}
