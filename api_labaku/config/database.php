<?php
/**
 * Database Configuration & Connection
 *
 * Uses PDO for secure database connections with prepared statements.
 * Credentials are loaded from .env via the Env class.
 */

require_once __DIR__ . '/env.php';

class Database
{
    // Database credentials are loaded from .env via Env class
    private string $host;
    private string $db_name;
    private string $username;
    private string $password;
    private string $charset;

    public function __construct()
    {
        $this->host     = Env::get('DB_HOST', 'localhost');
        $this->db_name  = Env::get('DB_NAME', 'labaku_db');
        $this->username = Env::get('DB_USER', 'labaku_db');
        $this->password = Env::get('DB_PASS', 'CXnS56bMsKy4n2G8');
        $this->charset  = Env::get('DB_CHARSET', 'utf8mb4');
    }

    private ?PDO $conn = null;

    /**
     * Get database connection (singleton pattern)
     */
    public function getConnection(): PDO
    {
        if ($this->conn === null) {

            try {
                $dsn = "mysql:host={$this->host};dbname={$this->db_name};charset={$this->charset}";

                $options = [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES {$this->charset}",
                ];

                $this->conn = new PDO($dsn, $this->username, $this->password, $options);
            } catch (PDOException $e) {
                // In production, log the error instead of exposing it
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'Database connection failed: ' . $e->getMessage()
                ]);
                exit;
            }
        }

        return $this->conn;
    }
}
