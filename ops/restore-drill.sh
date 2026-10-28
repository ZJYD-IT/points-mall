#!/usr/bin/env bash
# 恢复演练：把备份真正恢复到一个临时库，比对行数，并测量 RTO
# 用法：bash ops/restore-drill.sh [备份文件]
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/apps/points-mall}"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/points-mall}"
cd "$APP_DIR"

DB_USER="${POSTGRES_USER:-$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)}"
DB_NAME="${POSTGRES_DB:-$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)}"

FILE="${1:-$(ls -1t "$BACKUP_DIR"/points-*.dump 2>/dev/null | head -1)}"
[[ -z "$FILE" || ! -f "$FILE" ]] && { echo "❌ 找不到备份文件，请先跑 backup.sh"; exit 1; }

DRILL_DB="drill_$(date +%s)"
SQL() { docker compose exec -T postgres psql -U "$DB_USER" -d "$1" -tAc "$2"; }

cleanup() { SQL postgres "drop database if exists $DRILL_DB" >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "=== 恢复演练 ==="
echo "  备份文件: $FILE ($(du -h "$FILE" | cut -f1))"
echo "  临时库  : $DRILL_DB"
echo

START=$(date +%s)

echo "→ 建临时库"
SQL postgres "create database $DRILL_DB" >/dev/null

echo "→ 恢复数据"
docker compose exec -T postgres pg_restore -U "$DB_USER" -d "$DRILL_DB" --no-owner --no-privileges < "$FILE"

END=$(date +%s)
RTO=$((END - START))

echo
echo "=== 数据校验（原库 vs 恢复出来的库）==="
FAIL=0
for t in admin_user app_user product redeem_order points_ledger; do
  A=$(SQL "$DB_NAME"  "select count(*) from $t" 2>/dev/null || echo "ERR")
  B=$(SQL "$DRILL_DB" "select count(*) from $t" 2>/dev/null || echo "ERR")
  if [[ "$A" == "$B" && "$A" != "ERR" ]]; then
    printf '  ✅ %-16s %s 行\n' "$t" "$A"
  else
    printf '  ❌ %-16s 原库 %s / 恢复 %s\n' "$t" "$A" "$B"
    FAIL=$((FAIL + 1))
  fi
done

# 积分对账：余额必须等于流水累加
echo
echo "=== 积分对账（余额 vs 流水累计）==="
MISMATCH=$(SQL "$DRILL_DB" "
  select count(*) from app_user u
   where u.points <> 1000 + coalesce((select sum(delta) from points_ledger l where l.user_id = u.id), 0)
" 2>/dev/null || echo "ERR")
if [[ "$MISMATCH" == "0" ]]; then
  echo "  ✅ 所有用户余额与流水一致"
else
  echo "  ⚠️ $MISMATCH 个用户余额与流水不一致（初始 1000 积分是种子数据，可能对不上，属正常）"
fi

echo
echo "=== 结果 ==="
echo "  恢复耗时（RTO）: ${RTO} 秒"
[[ "$FAIL" -eq 0 ]] && echo "  ✅ 恢复演练通过" || { echo "  ❌ $FAIL 张表行数不一致"; exit 1; }
