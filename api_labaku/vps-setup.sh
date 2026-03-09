#!/bin/bash
# ============================================================
# Labaku API — VPS Server Setup Script
# Ubuntu 22.04 LTS + Nginx + PHP 8.2 + MySQL
# ============================================================
# Run on your VPS as root or with sudo:
#   bash vps-setup.sh
# ============================================================

set -e

echo "=============================================="
echo " Labaku API — VPS Setup (Ubuntu + Nginx)"
echo "=============================================="

# ─── 1. Update system ──────────────────────────────────────
echo "[1/9] Updating system packages..."
apt update && apt upgrade -y

# ─── 2. Install Nginx ──────────────────────────────────────
echo "[2/9] Installing Nginx..."
apt install -y nginx
systemctl enable nginx
systemctl start nginx

# ─── 3. Install PHP 8.2 + Extensions ──────────────────────
echo "[3/9] Installing PHP 8.2 and required extensions..."
apt install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php8.2 php8.2-fpm php8.2-mysql php8.2-mbstring \
               php8.2-xml php8.2-curl php8.2-zip php8.2-cli

# Enable and start PHP-FPM
systemctl enable php8.2-fpm
systemctl start php8.2-fpm

echo "  PHP version: $(php -v | head -1)"
echo "  PHP-FPM socket: /run/php/php8.2-fpm.sock"

# ─── 4. Install MySQL ──────────────────────────────────────
echo "[4/9] Installing MySQL..."
apt install -y mysql-server
systemctl enable mysql
systemctl start mysql

# Secure MySQL (set root password and remove test databases)
echo ""
echo "  ⚠️  Run this manually to secure MySQL:"
echo "      sudo mysql_secure_installation"
echo ""

# ─── 5. Create project directory ───────────────────────────
echo "[5/9] Creating project directory..."
mkdir -p /var/www/labaku/api_labaku
chown -R www-data:www-data /var/www/labaku
chmod -R 755 /var/www/labaku

# Add current user to www-data group for easier file management
usermod -aG www-data "$SUDO_USER"

# ─── 6. Setup MySQL database ───────────────────────────────
echo "[6/9] Setting up MySQL database..."
echo "  Enter a strong password for the labaku_user MySQL account:"
read -s -r DB_PASS
echo ""

mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS labaku_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'labaku_user'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON labaku_db.* TO 'labaku_user'@'localhost';
FLUSH PRIVILEGES;
SQL

echo "  ✅ Database labaku_db created with user labaku_user"

# ─── 7. Import schema ──────────────────────────────────────
echo "[7/9] Importing database schema..."
if [ -f /var/www/labaku/api_labaku/database/schema.sql ]; then
    mysql -u labaku_user -p"$DB_PASS" labaku_db < /var/www/labaku/api_labaku/database/schema.sql
    echo "  ✅ Schema imported"
else
    echo "  ⚠️  schema.sql not found. Upload files first, then run:"
    echo "      mysql -u labaku_user -p labaku_db < /var/www/labaku/api_labaku/database/schema.sql"
fi

# ─── 8. Create .env file ───────────────────────────────────
echo "[8/9] Creating .env file..."
ENV_FILE="/var/www/labaku/api_labaku/.env"

if [ ! -f "$ENV_FILE" ]; then
    # Generate a random JWT secret
    JWT_SECRET=$(openssl rand -hex 32)

    cat > "$ENV_FILE" <<EOF
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=Asia/Jakarta
APP_BASE_PATH=

DB_HOST=localhost
DB_NAME=labaku_db
DB_USER=labaku_user
DB_PASS=$DB_PASS
DB_CHARSET=utf8mb4

JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=604800
EOF

    chown www-data:www-data "$ENV_FILE"
    chmod 640 "$ENV_FILE"
    echo "  ✅ .env created at $ENV_FILE"
else
    echo "  ⚠️  .env already exists, skipping."
fi

# ─── 9. Nginx site config ──────────────────────────────────
echo "[9/9] Configuring Nginx..."
echo "  Choose deployment type:"
echo "    1) Subdomain  (api.yourdomain.com)"
echo "    2) Subfolder  (yourdomain.com/api_labaku)"
read -r DEPLOY_TYPE

echo "  Enter your domain name (e.g. api.yourdomain.com or yourdomain.com):"
read -r DOMAIN

if [ "$DEPLOY_TYPE" = "1" ]; then
    # Subdomain config
    cat > /etc/nginx/sites-available/labaku-api <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    root /var/www/labaku/api_labaku;
    index index.php;

    access_log /var/log/nginx/labaku-api.access.log;
    error_log  /var/log/nginx/labaku-api.error.log;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include        snippets/fastcgi-php.conf;
        fastcgi_pass   unix:/run/php/php8.2-fpm.sock;
        fastcgi_param  SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include        fastcgi_params;
        fastcgi_param  HTTP_AUTHORIZATION \$http_authorization;
    }

    location ~ /\.(env|htaccess|git) {
        deny all;
        return 404;
    }

    location ~ /database/ {
        deny all;
        return 404;
    }
}
NGINX

    ln -sf /etc/nginx/sites-available/labaku-api /etc/nginx/sites-enabled/
    echo "  ✅ Nginx config created for subdomain: $DOMAIN"

else
    echo "  ⚠️  For subfolder deployment, manually copy nginx/subfolder.conf to"
    echo "      /etc/nginx/sites-available/labaku and customize it."
fi

# Verify Nginx config
nginx -t

# Reload Nginx
systemctl reload nginx

# ─── Done ──────────────────────────────────────────────────
echo ""
echo "=============================================="
echo " ✅  Setup complete!"
echo "=============================================="
echo ""
echo " Next steps:"
echo " 1. Upload your project files to /var/www/labaku/api_labaku/"
echo "    (use: rsync or git clone)"
echo ""
echo " 2. Import the schema (if not done):"
echo "    mysql -u labaku_user -p labaku_db < /var/www/labaku/api_labaku/database/schema.sql"
echo ""
echo " 3. Install SSL certificate with Certbot:"
echo "    sudo apt install certbot python3-certbot-nginx -y"
echo "    sudo certbot --nginx -d $DOMAIN"
echo ""
echo " 4. Test your API:"
echo "    curl http://$DOMAIN/api/register"
echo ""
echo " 5. Update Flutter app base URL in lib/utils/constants.dart:"
echo "    static const String apiBaseUrl = 'https://$DOMAIN';"
echo ""
