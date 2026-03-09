# Labaku API Documentation

## Small Business Management REST API

Native PHP 8+ backend with MySQL database, JWT authentication, and clean REST architecture.

---

## Setup Instructions

### 1. Database Setup

1. Import the SQL schema:
```bash
mysql -u root -p < database/schema.sql
```

2. Update database credentials in `config/database.php`:
```php
private string $host = 'localhost';
private string $db_name = 'labaku_db';
private string $username = 'root';
private string $password = '';
```

### 2. Server Setup

- Place the `api_labaku` folder in your web server's document root (e.g., XAMPP `htdocs/`)
- Ensure Apache `mod_rewrite` is enabled
- Ensure PHP 8.0+ is installed with PDO MySQL extension

### 3. JWT Secret Key

Update the secret key in `utils/JwtHelper.php` for production:
```php
private static string $secretKey = 'your_secure_secret_key_here';
```

---

## Base URL

```
http://localhost/api_labaku
```

---

## Response Format

### Success Response
```json
{
    "success": true,
    "message": "Data retrieved successfully",
    "data": {}
}
```

### Error Response
```json
{
    "success": false,
    "message": "Error description"
}
```

### Validation Error Response
```json
{
    "success": false,
    "message": "Validation failed",
    "errors": ["Field is required", "Invalid format"]
}
```

---

## Authentication

All protected endpoints require a JWT token in the `Authorization` header:
```
Authorization: Bearer <JWT_TOKEN>
```

---

## API Endpoints

---

### Authentication (Public)

#### POST `/api/register`
Register a new user account.

**Request Body:**
```json
{
    "email": "user@email.com",
    "password": "password123"
}
```

**Success Response (201):**
```json
{
    "success": true,
    "message": "Registration successful",
    "data": {
        "token": "eyJ0eXAiOiJKV1Q...",
        "user": {
            "id": 1,
            "email": "user@email.com"
        }
    }
}
```

---

#### POST `/api/login`
Authenticate and get JWT token.

**Request Body:**
```json
{
    "email": "user@email.com",
    "password": "password123"
}
```

**Success Response (200):**
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "token": "eyJ0eXAiOiJKV1Q...",
        "user": {
            "id": 1,
            "email": "user@email.com"
        }
    }
}
```

---

#### POST `/api/forgot-password`
Request a password reset token.

**Request Body:**
```json
{
    "email": "user@email.com"
}
```

**Response (200):**
```json
{
    "success": true,
    "message": "Password reset token generated",
    "data": {
        "reset_token": "abc123...",
        "note": "In production, this token would be sent via email"
    }
}
```

---

#### POST `/api/reset-password`
Reset password using reset token.

**Request Body:**
```json
{
    "email": "user@email.com",
    "reset_token": "abc123...",
    "new_password": "newpassword123"
}
```

---

### User Profile (Protected)

#### GET `/api/user/profile`
Get authenticated user's profile.

**Response:**
```json
{
    "success": true,
    "message": "User profile retrieved",
    "data": {
        "id": 1,
        "email": "user@email.com",
        "created_at": "2026-03-09 10:00:00"
    }
}
```

---

#### PUT `/api/user/change-password`
Change password.

**Request Body:**
```json
{
    "current_password": "oldpassword",
    "new_password": "newpassword123"
}
```

---

### Store Management (Protected)

#### POST `/api/store/create`
Create a new store.

**Request Body:**
```json
{
    "store_name": "Toko Sejahtera",
    "phone": "081234567890",
    "address": "Jl. Merdeka No. 10, Jakarta"
}
```

**Success Response (201):**
```json
{
    "success": true,
    "message": "Store created successfully",
    "data": {
        "id": 1,
        "user_id": 1,
        "store_name": "Toko Sejahtera",
        "phone": "081234567890",
        "address": "Jl. Merdeka No. 10, Jakarta",
        "created_at": "2026-03-09 10:00:00"
    }
}
```

---

#### GET `/api/store/my-store`
Get all stores belonging to the user.

---

#### PUT `/api/store/update`
Update store details.

**Request Body:**
```json
{
    "store_id": 1,
    "store_name": "Toko Sejahtera Baru",
    "phone": "081234567890",
    "address": "Jl. Baru No. 5"
}
```

---

### Products (Protected)

#### POST `/api/products/create`
Create a new product.

**Request Body:**
```json
{
    "store_id": 1,
    "name": "Indomie Goreng",
    "cost_price": 2500.00,
    "sell_price": 3500.00,
    "stock": 100,
    "unit": "pcs",
    "category": "Makanan"
}
```

---

#### GET `/api/products/list?store_id=1&category=Makanan&search=indomie`
Get all products for a store. Supports filtering by category and search.

---

#### PUT `/api/products/update`
Update a product.

**Request Body:**
```json
{
    "id": 1,
    "store_id": 1,
    "name": "Indomie Goreng Special",
    "cost_price": 2800.00,
    "sell_price": 4000.00,
    "stock": 80,
    "unit": "pcs",
    "category": "Makanan"
}
```

---

#### DELETE `/api/products/delete?id=1&store_id=1`
Delete a product.

---

#### GET `/api/products/low-stock?store_id=1&threshold=5`
Get products with stock at or below the threshold.

---

### Transactions / Sales (Protected)

#### POST `/api/transactions/create`
Create a new sales transaction. Automatically reduces product stock.

**Request Body:**
```json
{
    "store_id": 1,
    "items": [
        {
            "product_id": 1,
            "quantity": 3,
            "price": 3500.00
        },
        {
            "product_id": 2,
            "quantity": 2,
            "price": 5000.00
        }
    ]
}
```

**Success Response (201):**
```json
{
    "success": true,
    "message": "Transaction created successfully",
    "data": {
        "id": 1,
        "store_id": 1,
        "total_amount": 20500.00,
        "created_at": "2026-03-09 14:30:00",
        "items": [
            {
                "id": 1,
                "product_id": 1,
                "product_name": "Indomie Goreng",
                "quantity": 3,
                "price": 3500.00,
                "subtotal": 10500.00
            },
            {
                "id": 2,
                "product_id": 2,
                "product_name": "Teh Botol",
                "quantity": 2,
                "price": 5000.00,
                "subtotal": 10000.00
            }
        ]
    }
}
```

---

#### GET `/api/transactions/list?store_id=1&start_date=2026-03-01&end_date=2026-03-09&limit=50&offset=0`
Get all transactions for a store with pagination and date filtering.

---

#### GET `/api/transactions/detail?id=1&store_id=1`
Get transaction detail with items.

---

### Expenses (Protected)

#### POST `/api/expenses/create`
Create a new expense.

**Request Body:**
```json
{
    "store_id": 1,
    "name": "Listrik Bulan Maret",
    "category": "Utilitas",
    "amount": 500000.00,
    "notes": "Tagihan listrik bulan Maret 2026",
    "expense_date": "2026-03-05"
}
```

---

#### GET `/api/expenses/list?store_id=1&start_date=2026-03-01&end_date=2026-03-31&category=Utilitas`
Get expenses with optional date and category filters.

---

#### PUT `/api/expenses/update`
Update an expense.

**Request Body:**
```json
{
    "id": 1,
    "store_id": 1,
    "name": "Listrik Bulan Maret (Revisi)",
    "category": "Utilitas",
    "amount": 550000.00,
    "notes": "Tagihan listrik revisi",
    "expense_date": "2026-03-05"
}
```

---

#### DELETE `/api/expenses/delete?id=1&store_id=1`
Delete an expense.

---

### Reports (Protected)

#### GET `/api/reports/profit?store_id=1&date=2026-03-09`
Get daily, weekly, and monthly profit.

**Profit Formula:** `Profit = Total Sales - Total Expenses - COGS`

**Response:**
```json
{
    "success": true,
    "message": "Profit report retrieved",
    "data": {
        "daily_profit": {
            "total_sales": 500000,
            "total_expenses": 50000,
            "cogs": 200000,
            "profit": 250000,
            "start_date": "2026-03-09",
            "end_date": "2026-03-09"
        },
        "weekly_profit": {
            "total_sales": 3500000,
            "total_expenses": 350000,
            "cogs": 1400000,
            "profit": 1750000,
            "start_date": "2026-03-03",
            "end_date": "2026-03-09"
        },
        "monthly_profit": {
            "total_sales": 15000000,
            "total_expenses": 2000000,
            "cogs": 6000000,
            "profit": 7000000,
            "start_date": "2026-03-01",
            "end_date": "2026-03-31"
        }
    }
}
```

---

#### GET `/api/reports/sales?store_id=1&start_date=2026-03-01&end_date=2026-03-31`
Get sales report for a date range.

---

#### GET `/api/reports/expenses?store_id=1&start_date=2026-03-01&end_date=2026-03-31`
Get expenses report for a date range.

---

### Dashboard (Protected)

#### GET `/api/dashboard/summary?store_id=1`
Get dashboard summary.

**Response:**
```json
{
    "success": true,
    "message": "Dashboard summary retrieved",
    "data": {
        "today_sales": 500000,
        "today_expenses": 120000,
        "today_profit": 380000,
        "monthly_sales": 15000000,
        "monthly_expenses": 2000000,
        "monthly_profit": 7000000,
        "total_products": 45,
        "low_stock_items": 3,
        "low_stock_list": [
            {
                "id": 5,
                "name": "Sabun Mandi",
                "stock": 2,
                "unit": "pcs"
            }
        ]
    }
}
```

---

## Project Structure

```
api_labaku/
├── index.php              # Entry point
├── .htaccess              # URL rewriting
├── config/
│   └── database.php       # Database connection
├── controllers/
│   ├── AuthController.php
│   ├── UserController.php
│   ├── StoreController.php
│   ├── ProductController.php
│   ├── TransactionController.php
│   ├── ExpenseController.php
│   ├── ReportController.php
│   └── DashboardController.php
├── models/
│   ├── User.php
│   ├── Store.php
│   ├── Product.php
│   ├── Transaction.php
│   └── Expense.php
├── middleware/
│   └── AuthMiddleware.php
├── routes/
│   └── api.php            # Route definitions
├── utils/
│   ├── Response.php       # JSON response helper
│   └── JwtHelper.php      # JWT token helper
└── database/
    └── schema.sql         # Database schema
```

---

## Security Features

- **JWT Authentication** — Token-based auth for stateless API
- **Password Hashing** — bcrypt via `password_hash()` / `password_verify()`
- **SQL Injection Protection** — PDO prepared statements throughout
- **Input Validation** — Server-side validation on all endpoints
- **Store Ownership Verification** — Users can only access their own stores/data
- **CORS Headers** — Configured for cross-origin Flutter requests
- **Authorization Header Support** — Multiple fallback methods for Apache compatibility

---

## Flutter Integration

### Base HTTP Client Setup (Dart)
```dart
const String baseUrl = 'http://your-server/api_labaku';

Future<Map<String, String>> getHeaders() async {
  final token = await getStoredToken();
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
```

### Example: Login Request
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'user@email.com',
    'password': 'password123',
  }),
);

final data = jsonDecode(response.body);
if (data['success']) {
  final token = data['data']['token'];
  // Store token securely
}
```
