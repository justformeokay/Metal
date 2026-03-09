-- ============================================================
-- Migration: Add backups table for cloud backup/sync
-- ============================================================
-- Run this migration on your database:
-- mysql -u root -p labaku_db < alter_add_backups.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS backups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    store_id INT NOT NULL,
    backup_data LONGTEXT NOT NULL,
    backup_size INT DEFAULT 0,
    device_name VARCHAR(200) DEFAULT NULL,
    backup_type ENUM('manual', 'auto') DEFAULT 'manual',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index for fast lookup by user
CREATE INDEX idx_backups_user_id ON backups(user_id);
CREATE INDEX idx_backups_store_id ON backups(store_id);
CREATE INDEX idx_backups_created_at ON backups(created_at);
