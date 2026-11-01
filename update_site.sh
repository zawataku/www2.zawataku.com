#!/bin/bash
set -uo pipefail
export LC_ALL=C

WEB_DIR="/var/www/html/www2.zawataku.com/html/index"
ACCESS_LOG="/var/log/nginx/www2_access.log"

# デフォルトルートのインターフェースを自動検出
INTERFACE=$(ip route show default | awk '{print $5; exit}')

DATE=$(date "+%d %b. %Y at %H:%M in JST")

# Cloudflare Tunnel 経由では nginx への接続は cloudflared のみになるため、
# 直近1分間のアクセスログからユニークな訪問者IP数を数える（nginx の real_ip 設定前提）
SINCE=$(date -d '1 min ago' '+%d/%b/%Y:%H:%M')
CONN_HTTP=$(grep -F "[$SINCE" "$ACCESS_LOG" 2>/dev/null | awk '{print $1}' | sort -u | wc -l)

# 5秒間計測した送信（tx）速度。Webサーバーが配信している帯域に相当
TX_RATE=$(vnstat -i "$INTERFACE" -tr --json | jq -r '.tx.ratestring')

# top の1回目は不正確なため、1秒間隔で2回計測して2回目の idle 値を使う
CPU_USAGE=$(top -bn2 -d1 | grep "Cpu(s)" | tail -n1 \
    | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.1f%%", 100 - $1}')

MSG="The server handles $CONN_HTTP HTTP connections with the use of $TX_RATE bandwidth and $CPU_USAGE CPU time on $DATE."

# グラフ画像も一時ファイル経由で差し替え
vnstati -vs -i "$INTERFACE" -o "$WEB_DIR/img/.traffic.tmp.png" \
    && chmod 644 "$WEB_DIR/img/.traffic.tmp.png" \
    && mv "$WEB_DIR/img/.traffic.tmp.png" "$WEB_DIR/img/traffic.png"

TIMESTAMP=$(date +%s)

# 書きかけのHTMLが配信されないよう、一時ファイルに書いてから mv で置換
TMP=$(mktemp "$WEB_DIR/.index.XXXXXX")
sed -e "s|{{SERVER_STATUS}}|$MSG|g" \
    -e "s|traffic.png|traffic.png?t=$TIMESTAMP|g" \
    "$WEB_DIR/index.template.html" > "$TMP"
chmod 644 "$TMP"
mv "$TMP" "$WEB_DIR/index.html"
