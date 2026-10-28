#!/usr/bin/env bash
# 健康探测：只在状态「变化」时写告警，避免每 5 分钟刷一条
# 用法：*/5 * * * * /opt/apps/points-mall/ops/health-watch.sh
#
# 判定标准不是 HTTP 状态码，而是响应体里必须出现 "status":"UP"。
# 原因：启用 HTTPS 后 80 端口会 301 跳转，curl -f 对 3xx 不报错，
#       只看状态码会「假通过」；而 301 的响应体里没有 status，能可靠区分。
set -uo pipefail

HTTP_URL="${HEALTH_URL:-http://127.0.0.1/api/health}"
HTTPS_URL="${HEALTH_HTTPS_URL:-https://127.0.0.1/api/health}"
LOG="${HEALTH_LOG:-/opt/backups/health-alerts.log}"
STATE="${HEALTH_STATE:-/opt/backups/health.state}"

mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

probe() {
  local body
  body="$(curl -s -k -m 10 "$HTTPS_URL" 2>/dev/null || true)"
  [[ "$body" == *'"status":"UP"'* ]] && return 0
  body="$(curl -s -m 10 "$HTTP_URL" 2>/dev/null || true)"
  [[ "$body" == *'"status":"UP"'* ]]
}

LAST="$(cat "$STATE" 2>/dev/null || echo up)"

if probe; then
  if [[ "$LAST" != "up" ]]; then
    echo "[$(date -Is)] ✅ 恢复正常 ($HTTP_URL)" >> "$LOG"
  fi
  echo up > "$STATE"
  exit 0
fi

if [[ "$LAST" == "up" ]]; then
  echo "[$(date -Is)] ❌ 异常 $HTTP_URL" >> "$LOG"
  if [[ -n "${HEALTH_WEBHOOK:-}" ]]; then
    curl -s -m 10 -X POST -H 'Content-Type: application/json' \
      -d "{\"text\":\"积分商城 API 异常\"}" "$HEALTH_WEBHOOK" >/dev/null 2>&1 || true
  fi
fi
echo down > "$STATE"
exit 1
