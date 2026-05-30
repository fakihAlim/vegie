<?php
/**
 * Database Configuration & Connection
 * LovingHarmony API
 */

class Database {
    private static $instance = null;
    private $connection;

    private $host = 'localhost';
    private $dbname = 'lovingharmony';
    private $username = 'root';
    private $password = '';
    private $charset = 'utf8mb4';

    private function __construct() {
        // Check for environment configuration
        $envFile = __DIR__ . '/../env.php';
        if (file_exists($envFile)) {
            $env = require $envFile;
            $this->host = $env['DB_HOST'] ?? $this->host;
            $this->dbname = $env['DB_NAME'] ?? $this->dbname;
            $this->username = $env['DB_USER'] ?? $this->username;
            $this->password = $env['DB_PASS'] ?? $this->password;
            $this->charset = $env['DB_CHARSET'] ?? $this->charset;

            // AI Configuration
            if (!defined('OLLAMA_BASE_URL') && isset($env['OLLAMA_BASE_URL'])) {
                define('OLLAMA_BASE_URL', $env['OLLAMA_BASE_URL']);
            }
            if (!defined('OLLAMA_MODEL') && isset($env['OLLAMA_MODEL'])) {
                define('OLLAMA_MODEL', $env['OLLAMA_MODEL']);
            }
            if (!defined('GEMINI_API_KEY') && isset($env['GEMINI_API_KEY'])) {
                define('GEMINI_API_KEY', $env['GEMINI_API_KEY']);
            }
        }

        try {
            $dsn = "mysql:host={$this->host};dbname={$this->dbname};charset={$this->charset}";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];
            $this->connection = new PDO($dsn, $this->username, $this->password, $options);
        } catch (PDOException $e) {
            if (strpos($_SERVER['REQUEST_URI'] ?? '', '/api/') !== false) {
                http_response_code(500);
                echo json_encode([
                    'success' => false,
                    'message' => 'Database connection failed: ' . $e->getMessage()
                ]);
                exit;
            } else {
                throw $e;
            }
        }
    }

    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    public function getConnection() {
        return $this->connection;
    }

    // Prevent cloning
    private function __clone() {}

    // Prevent unserialization
    public function __wakeup() {
        throw new \Exception("Cannot unserialize singleton");
    }
}
