#!/bin/bash
set -euo pipefail

REPO_DIR="/var/www/html/www2.zawataku.com"

cd "$REPO_DIR"
git pull --ff-only origin main

# テンプレート変更を即時反映
"$REPO_DIR/update_site.sh"
