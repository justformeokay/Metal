<?php
/**
 * Labaku API - Entry Point
 *
 * All requests are routed through this file via Nginx try_files / .htaccess rewriting.
 * Bootstraps environment, then delegates to the router.
 */

// ── Load environment variables from .env ──────────────────────────────────
require_once __DIR__ . '/config/env.php';
Env::load(__DIR__);

// ── Error reporting (controlled by APP_DEBUG in .env) ────────────────────
$debug = Env::bool('APP_DEBUG', false);
error_reporting(E_ALL);
ini_set('display_errors', $debug ? '1' : '0');
ini_set('log_errors', '1');

// ── Timezone ─────────────────────────────────────────────────────────────
date_default_timezone_set(Env::get('APP_TIMEZONE', 'Asia/Jakarta'));

// ── Bootstrap JWT secrets from env ───────────────────────────────────────
require_once __DIR__ . '/utils/JwtHelper.php';
JwtHelper::init();

// ── Route all requests ────────────────────────────────────────────────────
require_once __DIR__ . '/routes/api.php';
