<?php
/**
 * Environment Configuration Loader
 *
 * Parses the .env file from the project root and makes all
 * variables available via env() helper and $_ENV / getenv().
 *
 * Usage:
 *   require_once __DIR__ . '/env.php';
 *   Env::load(__DIR__ . '/..');
 *   $dbPass = Env::get('DB_PASS');
 */

class Env
{
    private static bool $loaded = false;

    /**
     * Load .env file from the given directory.
     *
     * @param string $directory  Absolute path to the folder containing .env
     */
    public static function load(string $directory): void
    {
        if (self::$loaded) {
            return;
        }

        $envFile = rtrim($directory, '/') . '/.env';

        if (!file_exists($envFile)) {
            // .env missing — fall back to existing server environment variables
            self::$loaded = true;
            return;
        }

        $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

        foreach ($lines as $line) {
            // Skip comments
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }

            // Only process KEY=VALUE lines
            if (!str_contains($line, '=')) {
                continue;
            }

            [$key, $value] = explode('=', $line, 2);
            $key   = trim($key);
            $value = trim($value);

            // Strip inline comments
            if (str_contains($value, ' #')) {
                $value = trim(explode(' #', $value, 2)[0]);
            }

            // Strip surrounding quotes
            if (
                (str_starts_with($value, '"') && str_ends_with($value, '"')) ||
                (str_starts_with($value, "'") && str_ends_with($value, "'"))
            ) {
                $value = substr($value, 1, -1);
            }

            // Set in environment
            $_ENV[$key] = $value;
            putenv("{$key}={$value}");
        }

        self::$loaded = true;
    }

    /**
     * Get an environment variable value.
     *
     * @param string      $key      Variable name
     * @param string|null $default  Default if not set
     */
    public static function get(string $key, ?string $default = null): ?string
    {
        $value = $_ENV[$key] ?? getenv($key);
        return ($value !== false && $value !== null) ? (string) $value : $default;
    }

    /**
     * Get an environment variable as boolean.
     */
    public static function bool(string $key, bool $default = false): bool
    {
        $val = strtolower(self::get($key, '') ?? '');
        if (in_array($val, ['true', '1', 'yes', 'on'], true)) return true;
        if (in_array($val, ['false', '0', 'no', 'off', ''], true)) return false;
        return $default;
    }

    /**
     * Get an environment variable as integer.
     */
    public static function int(string $key, int $default = 0): int
    {
        $val = self::get($key);
        return $val !== null ? (int) $val : $default;
    }
}
