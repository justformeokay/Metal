<?php
/**
 * Report Controller
 * 
 * Handles profit calculation and reporting endpoints.
 * All routes require authentication.
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/Transaction.php';
require_once __DIR__ . '/../models/Expense.php';
require_once __DIR__ . '/../models/Store.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class ReportController
{
    private PDO $db;
    private Transaction $transactionModel;
    private Expense $expenseModel;
    private Store $storeModel;

    public function __construct()
    {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->transactionModel = new Transaction($this->db);
        $this->expenseModel = new Expense($this->db);
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
     * Calculate profit for a date range
     * 
     * Profit = Total Sales - Total Expenses - Cost of Goods Sold (COGS)
     */
    private function calculateProfit(int $storeId, string $startDate, string $endDate): array
    {
        $totalSales = $this->transactionModel->getTotalSales($storeId, $startDate, $endDate);
        $totalExpenses = $this->expenseModel->getTotalExpenses($storeId, $startDate, $endDate);
        $cogs = $this->transactionModel->getCOGS($storeId, $startDate, $endDate);
        $profit = $totalSales - $totalExpenses - $cogs;

        return [
            'total_sales'    => round($totalSales, 2),
            'total_expenses' => round($totalExpenses, 2),
            'cogs'           => round($cogs, 2),
            'profit'         => round($profit, 2),
            'start_date'     => $startDate,
            'end_date'       => $endDate,
        ];
    }

    /**
     * GET /api/reports/profit
     * 
     * Get daily, weekly, and monthly profit.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - date: string (optional, default: today, format: YYYY-MM-DD)
     */
    public function profit(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $date = $_GET['date'] ?? date('Y-m-d');

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        // Daily profit
        $dailyProfit = $this->calculateProfit($storeId, $date, $date);

        // Weekly profit (Monday to Sunday of the given date's week)
        $weekStart = date('Y-m-d', strtotime('monday this week', strtotime($date)));
        $weekEnd = date('Y-m-d', strtotime('sunday this week', strtotime($date)));
        $weeklyProfit = $this->calculateProfit($storeId, $weekStart, $weekEnd);

        // Monthly profit (first to last day of the given date's month)
        $monthStart = date('Y-m-01', strtotime($date));
        $monthEnd = date('Y-m-t', strtotime($date));
        $monthlyProfit = $this->calculateProfit($storeId, $monthStart, $monthEnd);

        Response::success('Profit report retrieved', [
            'daily_profit'   => $dailyProfit,
            'weekly_profit'  => $weeklyProfit,
            'monthly_profit' => $monthlyProfit,
        ]);
    }

    /**
     * GET /api/reports/sales
     * 
     * Get sales report for a date range.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - start_date: string (optional, default: first day of current month)
     *   - end_date: string (optional, default: today)
     */
    public function sales(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $startDate = $_GET['start_date'] ?? date('Y-m-01');
        $endDate = $_GET['end_date'] ?? date('Y-m-d');

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $totalSales = $this->transactionModel->getTotalSales($storeId, $startDate, $endDate);
        $transactions = $this->transactionModel->getByStoreId($storeId, $startDate, $endDate);
        $totalTransactions = count($transactions);

        Response::success('Sales report retrieved', [
            'total_sales'       => round($totalSales, 2),
            'total_transactions' => $totalTransactions,
            'transactions'      => $transactions,
            'start_date'        => $startDate,
            'end_date'          => $endDate,
        ]);
    }

    /**
     * GET /api/reports/expenses
     * 
     * Get expenses report for a date range.
     * 
     * Query parameters:
     *   - store_id: int (required)
     *   - start_date: string (optional)
     *   - end_date: string (optional)
     */
    public function expenses(): void
    {
        $auth = AuthMiddleware::authenticate();

        $storeId = isset($_GET['store_id']) ? (int) $_GET['store_id'] : 0;
        $startDate = $_GET['start_date'] ?? date('Y-m-01');
        $endDate = $_GET['end_date'] ?? date('Y-m-d');

        if ($storeId === 0) {
            Response::error('Store ID is required', 400);
        }

        $this->verifyStoreAccess($storeId, $auth['user_id']);

        $totalExpenses = $this->expenseModel->getTotalExpenses($storeId, $startDate, $endDate);
        $expenses = $this->expenseModel->getByStoreId($storeId, $startDate, $endDate);

        Response::success('Expenses report retrieved', [
            'total_expenses' => round($totalExpenses, 2),
            'total_records'  => count($expenses),
            'expenses'       => $expenses,
            'start_date'     => $startDate,
            'end_date'       => $endDate,
        ]);
    }
}
