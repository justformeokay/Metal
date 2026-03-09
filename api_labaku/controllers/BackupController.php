<?php
/**
 * Backup Controller
 * 
 * Handles cloud backup upload, download, and history.
 * All routes require authentication.
 * 
 * Endpoints:
 *   POST /api/backup/upload   — Upload a backup JSON to the server
 *   GET  /api/backup/latest   — Download the latest backup
 *   GET  /api/backup/history  — List backup history (without data)
 *   GET  /api/backup/download — Download a specific backup by ID
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Backup.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class BackupController
{
    private PDO $db;
    private Backup $backupModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->backupModel = new Backup($this->db);
        $this->storeModel = new Store($this->db);
    }

    /**
     * Verify that the given store belongs to the authenticated user.
     */
    private function verifyStoreAccess(int $storeId, int $userId): void
    {
        if (!$this->storeModel->belongsToUser($storeId, $userId)) {
            Response::error('Store not found or access denied', 403);
        }
    }

    /**
     * POST /api/backup/upload
     * 
     * Upload backup data (JSON) to the server.
     * 
     * Request body:
     *   - store_id: int (required)
     *   - backup_data: object (required) — the full backup JSON
     *   - device_name: string (optional)
     *   - backup_type: string (optional, "manual" or "auto")
     */
    public function upload(): void
    {
        $auth = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true);

        // Validate
        $errors = [];
        if (empty($data['store_id'])) {
            $errors[] = 'store_id is required';
        }
        if (empty($data['backup_data'])) {
            $errors[] = 'backup_data is required';
        }
        if (!empty($errors)) {
            Response::validationError($errors);
        }

        $storeId = (int) $data['store_id'];

        // Verify store ownership
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        // Encode backup_data to JSON string for storage
        $backupJson = json_encode($data['backup_data'], JSON_UNESCAPED_UNICODE);
        $backupSize = strlen($backupJson);

        // Max size check: 10MB
        if ($backupSize > 10 * 1024 * 1024) {
            Response::error('Backup data exceeds maximum size (10MB)', 413);
        }

        $this->backupModel->user_id = $auth['user_id'];
        $this->backupModel->store_id = $storeId;
        $this->backupModel->backup_data = $backupJson;
        $this->backupModel->backup_size = $backupSize;
        $this->backupModel->device_name = $data['device_name'] ?? null;
        $this->backupModel->backup_type = $data['backup_type'] ?? 'manual';

        if ($this->backupModel->create()) {
            // Cleanup: keep only latest 5 backups
            $this->backupModel->cleanupOld($auth['user_id'], $storeId, 5);

            Response::success('Backup uploaded successfully', [
                'id' => $this->backupModel->id,
                'backup_size' => $backupSize,
                'backup_type' => $this->backupModel->backup_type,
                'created_at' => date('Y-m-d H:i:s'),
            ], 201);
        }

        Response::error('Failed to upload backup', 500);
    }

    /**
     * GET /api/backup/latest?store_id=X
     * 
     * Get the latest backup for the user's store.
     */
    public function latest(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        if ($storeId <= 0) {
            Response::error('store_id query parameter is required', 400);
        }

        // Verify store ownership
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $backup = $this->backupModel->getLatest($auth['user_id'], $storeId);

        if (!$backup) {
            Response::error('No backup found', 404);
        }

        // Decode backup_data back to object
        $backup['backup_data'] = json_decode($backup['backup_data'], true);

        Response::success('Latest backup retrieved', $backup);
    }

    /**
     * GET /api/backup/history?store_id=X&limit=10
     * 
     * Get backup history (without data payload, for listing).
     */
    public function history(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        if ($storeId <= 0) {
            Response::error('store_id query parameter is required', 400);
        }

        // Verify store ownership
        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $limit = isset($_GET['limit']) ? min((int) $_GET['limit'], 50) : 10;
        $backups = $this->backupModel->getHistory($auth['user_id'], $storeId, $limit);

        Response::success('Backup history retrieved', $backups);
    }

    /**
     * GET /api/backup/download?id=X
     * 
     * Download a specific backup by ID.
     */
    public function download(): void
    {
        $auth = AuthMiddleware::authenticate();

        $backupId = isset($_GET['id']) ? (int) $_GET['id'] : 0;
        if ($backupId <= 0) {
            Response::error('Backup ID is required', 400);
        }

        $backup = $this->backupModel->findById($backupId, $auth['user_id']);

        if (!$backup) {
            Response::error('Backup not found', 404);
        }

        // Decode backup_data back to object
        $backup['backup_data'] = json_decode($backup['backup_data'], true);

        Response::success('Backup retrieved', $backup);
    }
}
