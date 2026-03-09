<?php
/**
 * Dashboard Controller
 * 
 * Provides summary data for the mobile app dashboard.
 * All routes require authentication.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Transaction.php';
require_once __DIR__ . '/../models/Expense.php';
require_once __DIR__ . '/../models/Product.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class DashboardController
{
    private PDO $db;
    private Transaction $transactionModel;
    private Expense $expenseModel;
    private Product $productModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->transactionModel = new Transaction($this->db);
        $this->expenseModel = new Expense($this->db);
        $this->productModel = new Product($this->db);
        $this->storeModel = new Store($this->db);
    }

    /**
     * Verify store ownership
     */
    private function verifyStoreAccess(int $storeId, int $userId): void
    {
        if (!$this->storeModel->belongsToUser($storeId, $userId)) {
            Response::error('Store not found or access denied', 403);
        }
    }

    /**
     * GET /api/dashboard/summary
     * 
     * Get dashboard summary for a store.
     * 
     * Query parameters:
     *   - store_id: int (required)
     * 
     * Returns:
     *   - today_sales
     *   - today_expenses
     *   - today_profit
     *   - total_products
     *   - low_stock_items
     *   - monthly_sales
     *   - monthly_expenses
     *   - monthly_profit
     */
    public function summary(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $today = date('Y-m-d');
        $monthStart = date('Y-m-01');
        $monthEnd = date('Y-m-t');

        // Today's data
        $todaySales = $this->transactionModel->getTotalSales($storeId, $today, $today);
        $todayExpenses = $this->expenseModel->getTotalExpenses($storeId, $today, $today);
        $todayCogs = $this->transactionModel->getCOGS($storeId, $today, $today);
        $todayProfit = $todaySales - $todayExpenses - $todayCogs;

        // Monthly data
        $monthlySales = $this->transactionModel->getTotalSales($storeId, $monthStart, $monthEnd);
        $monthlyExpenses = $this->expenseModel->getTotalExpenses($storeId, $monthStart, $monthEnd);
        $monthlyCogs = $this->transactionModel->getCOGS($storeId, $monthStart, $monthEnd);
        $monthlyProfit = $monthlySales - $monthlyExpenses - $monthlyCogs;

        // Product data
        $totalProducts = $this->productModel->countByStoreId($storeId);
        $lowStockItems = $this->productModel->getLowStock($storeId, 5);

        Response::success('Dashboard summary retrieved', [
            'today_sales'      => round($todaySales, 2),
            'today_expenses'   => round($todayExpenses, 2),
            'today_profit'     => round($todayProfit, 2),
            'monthly_sales'    => round($monthlySales, 2),
            'monthly_expenses' => round($monthlyExpenses, 2),
            'monthly_profit'   => round($monthlyProfit, 2),
            'total_products'   => $totalProducts,
            'low_stock_items'  => count($lowStockItems),
            'low_stock_list'   => $lowStockItems,
        ]);
    }
}
