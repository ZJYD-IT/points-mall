#!/usr/bin/env bash
# 故障演练：制造故障 → 测量「发现耗时」和「恢复耗时」→ 记进台账
# 用法：bash ops/fail-drill.sh db     # 数据库宕机
#       bash ops/fail-drill.sh api    # API 宕机
#       bash ops/fail-drill.sh all    # 两个都跑
set -uo pipefail

APP_DIR="${APP_DIR:-/opt/apps/points-mall}"
HEALTH="${HEALTH_URL:-http://127.0.0.1/api/health}"
LOG="${DRILL_LOG:-/opt/backups/fail-drill.log}"

cd "$APP_DIR"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true

probe() {
  # 返回 0 表示健康
  curl -sf -m 3 "$HEALTH" >/dev/null 2>&1
}

wait_down() {
  local t0=$(( $(date +%s) ))
  while probe; do
    if (( $(date +%s) - t0 > 120 )); then
      echo "    ⚠️ 120 秒内没探到异常（可能是缓存/重试兜住了）"
      DETECT=-1
      return 1
    fi
    sleep 1
  done
  DETECT=$(( $(date +%s) - t0 ))
}

wait_up() {
  local t0=$(( $(date +%s) ))
  while ! probe; do
    if (( $(date +%s) - t0 > 180 )); then
      echo "    ⚠️ 180 秒内没恢复，需要人工介入"
      RECOVER=-1
      return 1
    fi
    sleep 1
  done
  RECOVER=$(( $(date +%s) - t0 ))
}

run() {
  local name="$1" stop_cmd="$2" start_cmd="$3"
  echo
  echo "=== 演练：$name ==="
  DETECT=0; RECOVER=0

  echo "→ 制造故障：$stop_cmd"
  eval "$stop_cmd" >/dev/null 2>&1
  wait_down
  echo "    发现耗时：${DETECT}s"

  echo "→ 人工恢复：$start_cmd"
  eval "$start_cmd" >/dev/null 2>&1
  wait_up
  echo "    恢复耗时：${RECOVER}s"

  echo "[$(date -Is)] $name | 发现 ${DETECT}s | 恢复 ${RECOVER}s" >> "$LOG"
}

case "${1:-all}" in
  db)  run "数据库宕机" "docker compose stop postgres" "docker compose start postgres" ;;
  api) run "API 宕机"   "docker compose stop api"      "docker compose start api"      ;;
  all)
    run "数据库宕机" "docker compose stop postgres" "docker compose start postgres"
    run "API 宕机"   "docker compose stop api"      "docker compose start api"
    ;;
  *) echo "用法：bash ops/fail-drill.sh [db|api|all]"; exit 1 ;;
esac

echo
echo "=== 台账（/opt/backups/fail-drill.log）==="
tail -10 "$LOG" 2>/dev/null | sed 's/^/  /'
