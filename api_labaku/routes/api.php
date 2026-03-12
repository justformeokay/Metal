<?php
/**
 * API Router
 * 
 * Maps incoming requests to the appropriate controller and method.
 * Handles URL parsing, HTTP method validation, and CORS headers.
 */

// ============================================================
// CORS Headers — Allow Flutter app to communicate with API
// ============================================================
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ============================================================
// Include controllers
// ============================================================
require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../controllers/AppController.php';
require_once __DIR__ . '/../controllers/UserController.php';
require_once __DIR__ . '/../controllers/StoreController.php';
require_once __DIR__ . '/../controllers/ProductController.php';
require_once __DIR__ . '/../controllers/TransactionController.php';
require_once __DIR__ . '/../controllers/ExpenseController.php';
require_once __DIR__ . '/../controllers/ReportController.php';
require_once __DIR__ . '/../controllers/DashboardController.php';
require_once __DIR__ . '/../controllers/BackupController.php';
require_once __DIR__ . '/../controllers/MemberController.php';
require_once __DIR__ . '/../utils/Response.php';

// ============================================================
// Parse the request URI
// ============================================================
$requestUri = $_SERVER['REQUEST_URI'];
$requestMethod = $_SERVER['REQUEST_METHOD'];

// Remove query string from URI
$uri = parse_url($requestUri, PHP_URL_PATH);

// Remove base path — read from .env APP_BASE_PATH
// e.g. APP_BASE_PATH=/api_labaku  → strips /api_labaku prefix
// e.g. APP_BASE_PATH=            → no prefix (subdomain deployment)
$basePath = rtrim(Env::get('APP_BASE_PATH', ''), '/');
if ($basePath !== '' && strpos($uri, $basePath) === 0) {
    $uri = substr($uri, strlen($basePath));
}

// Normalize URI
$uri = '/' . trim($uri, '/');

// ============================================================
// Route Definitions
// ============================================================
// Format: [HTTP_METHOD, URI_PATTERN, CONTROLLER_CLASS, METHOD]
$routes = [
    // ---- App Version (Public) ----
    ['GET',    '/api/app/version',             'AppController',         'version'],

    // ---- Authentication (Public) ----
    ['POST',   '/api/register',            'AuthController',        'register'],
    ['POST',   '/api/login',               'AuthController',        'login'],
    ['POST',   '/api/forgot-password',     'AuthController',        'forgotPassword'],
    ['POST',   '/api/verify-otp',          'AuthController',        'verifyOtp'],
    ['POST',   '/api/reset-password',      'AuthController',        'resetPassword'],
    ['POST',   '/api/refresh-token',       'AuthController',        'refreshToken'],

    // ---- User Profile (Protected) ----
    ['GET',    '/api/user/profile',        'UserController',        'profile'],
    ['PUT',    '/api/user/change-password', 'UserController',       'changePassword'],

    // ---- Store (Protected) ----
    ['POST',   '/api/store/create',        'StoreController',       'create'],
    ['GET',    '/api/store/my-store',      'StoreController',       'myStore'],
    ['PUT',    '/api/store/update',        'StoreController',       'update'],

    // ---- Products (Protected) ----
    ['POST',   '/api/products/create',     'ProductController',     'create'],
    ['GET',    '/api/products/list',       'ProductController',     'list'],
    ['PUT',    '/api/products/update',     'ProductController',     'update'],
    ['DELETE', '/api/products/delete',     'ProductController',     'delete'],
    ['GET',    '/api/products/low-stock',  'ProductController',     'lowStock'],

    // ---- Transactions (Protected) ----
    ['POST',   '/api/transactions/create', 'TransactionController', 'create'],
    ['GET',    '/api/transactions/list',   'TransactionController', 'list'],
    ['GET',    '/api/transactions/detail', 'TransactionController', 'detail'],

    // ---- Expenses (Protected) ----
    ['POST',   '/api/expenses/create',     'ExpenseController',     'create'],
    ['GET',    '/api/expenses/list',       'ExpenseController',     'list'],
    ['PUT',    '/api/expenses/update',     'ExpenseController',     'update'],
    ['DELETE', '/api/expenses/delete',     'ExpenseController',     'delete'],

    // ---- Reports (Protected) ----
    ['GET',    '/api/reports/profit',      'ReportController',      'profit'],
    ['GET',    '/api/reports/sales',       'ReportController',      'sales'],
    ['GET',    '/api/reports/expenses',    'ReportController',      'expenses'],

    // ---- Dashboard (Protected) ----
    ['GET',    '/api/dashboard/summary',   'DashboardController',   'summary'],

    // ---- Backup / Cloud Sync (Protected) ----
    ['POST',   '/api/backup/upload',      'BackupController',      'upload'],
    ['GET',    '/api/backup/latest',      'BackupController',      'latest'],
    ['GET',    '/api/backup/history',     'BackupController',      'history'],
    ['GET',    '/api/backup/download',    'BackupController',      'download'],

    // ---- Members (Protected) ----
    ['POST',   '/api/member/create',      'MemberController',      'create'],
    ['GET',    '/api/member/list',        'MemberController',      'list'],
    ['PUT',    '/api/member/update',      'MemberController',      'update'],
    ['DELETE', '/api/member/delete',      'MemberController',      'delete'],
];

// ============================================================
// Route Matching & Dispatch
// ============================================================
foreach ($routes as $route) {
    [$method, $pattern, $controllerClass, $action] = $route;

    if ($requestMethod === $method && $uri === $pattern) {
        $controller = new $controllerClass();
        $controller->$action();
        exit;
    }
}

// ============================================================
// No route matched — 404
// ============================================================
Response::error('Endpoint not found', 404);
