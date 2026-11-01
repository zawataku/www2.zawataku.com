#!/bin/bash
# リポジトリの nginx 設定を、差分を確認したうえで /etc/nginx に反映する。
# 自動実行はしない（手動で sudo を使う前提）。
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/nginx/www2.zawataku.com.conf"
DEST="/etc/nginx/sites-available/default"

if cmp -s "$SRC" "$DEST"; then
    echo "変更はありません。"
    exit 0
fi

diff -u "$DEST" "$SRC" || true
echo
read -rp "この内容で反映しますか? [y/N] " ans
[[ "$ans" == [yY] ]] || { echo "中止しました。"; exit 1; }

sudo cp -p "$DEST" "$DEST.bak"
sudo install -m 644 -o root -g root "$SRC" "$DEST"

if sudo nginx -t; then
    sudo systemctl reload nginx
    echo "反映しました。（バックアップ: $DEST.bak）"
else
    sudo cp -p "$DEST.bak" "$DEST"
    echo "構文エラーのため元に戻しました。" >&2
    exit 1
fi
