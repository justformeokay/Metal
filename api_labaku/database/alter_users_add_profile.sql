-- ============================================================
-- Migration: Tambah kolom name & phone ke tabel users
-- Jalankan di server HANYA SEKALI:
--   mysql -u labaku_user -p labaku_db < alter_users_add_profile.sql
-- ============================================================

USE labaku_db;

ALTER TABLE users
    ADD COLUMN name    VARCHAR(150) NOT NULL DEFAULT '' AFTER email,
    ADD COLUMN phone   VARCHAR(30)  NOT NULL DEFAULT '' AFTER name;
