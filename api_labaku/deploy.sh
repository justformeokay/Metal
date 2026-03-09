#!/bin/bash
# ============================================================
# Labaku API — VPS Deployment Script (Ubuntu + Nginx)
# ============================================================
# Run this script on your LOCAL machine to deploy to the VPS
# Usage: bash deploy.sh
#
# Or run section by section manually via SSH on the VPS
# ============================================================

set -e  # Exit on error

# ── Config (edit these) ─────────────────────────────────────
VPS_USER="ubuntu"
VPS_IP="YOUR_VPS_IP"
VPS_SSH_KEY="~/.ssh/id_rsa"
APP_DIR="/var/www/labaku/api_labaku"
# ────────────────────────────────────────────────────────────

echo "🚀  Deploying Labaku API to $VPS_IP..."

rsync -avz --exclude='.env' \
           --exclude='vendor/' \
           --exclude='*.log' \
           --exclude='.git/' \
           -e "ssh -i $VPS_SSH_KEY" \
           . "$VPS_USER@$VPS_IP:$APP_DIR/"

echo "✅  Files uploaded. Run the VPS setup script manually after first deploy."
