#!/usr/bin/env bash
# 健康探测：只在状态「变化」时写告警，避免每 5 分钟刷一条
# 用法：*/5 * * * * /opt/apps/points-mall/ops/health-watch.sh
set -uo pipefail

URL="${HEALTH_URL:-http://127.0.0.1/api/health}"
LOG="${HEALTH_LOG:-/opt/backups/health-alerts.log}"
STATE="${HEALTH_STATE:-/opt/backups/health.state}"

mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
CODE=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$URL" 2>/dev/null || echo 000)
LAST=$(cat "$STATE" 2>/dev/null || echo up)

if [[ "$CODE" == "200" ]]; then
  if [[ "$LAST" != "up" ]]; then
    echo "[$(date -Is)] ✅ 恢复正常 ($URL)" >> "$LOG"
  fi
  echo up > "$STATE"
  exit 0
fi

if [[ "$LAST" == "up" ]]; then
  echo "[$(date -Is)] ❌ 异常 http=$CODE $URL" >> "$LOG"
  if [[ -n "${HEALTH_WEBHOOK:-}" ]]; then
    curl -s -m 10 -X POST -H 'Content-Type: application/json' \
      -d "{\"text\":\"积分商城 API 异常: http=$CODE\"}" "$HEALTH_WEBHOOK" >/dev/null 2>&1 || true
  fi
fi
echo down > "$STATE"
exit 1
