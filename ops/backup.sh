#!/usr/bin/env bash
# PostgreSQL 备份（在服务器上跑）
# 用法：bash ops/backup.sh
# 环境变量：APP_DIR / BACKUP_DIR / KEEP
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/apps/points-mall}"
BACKUP_DIR="${BACKUP_DIR:-/opt/backups/points-mall}"
KEEP="${KEEP:-7}"          # 保留最近 N 份
cd "$APP_DIR"

DB_USER="${POSTGRES_USER:-$(grep '^POSTGRES_USER=' .env | cut -d= -f2-)}"
DB_NAME="${POSTGRES_DB:-$(grep '^POSTGRES_DB=' .env | cut -d= -f2-)}"
: "${DB_USER:?.env 里没有 POSTGRES_USER}"
: "${DB_NAME:?.env 里没有 POSTGRES_DB}"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

TS="$(date +%Y%m%d-%H%M%S)"
FILE="$BACKUP_DIR/points-$TS.dump"
LOG="$BACKUP_DIR/backup.log"

echo "[$(date -Is)] 开始备份 $DB_NAME → $FILE"

# -Fc 自定义格式：支持并行恢复、可选择性恢复单表
if ! docker compose exec -T postgres pg_dump -U "$DB_USER" -d "$DB_NAME" -Fc > "$FILE"; then
  echo "[$(date -Is)] ❌ pg_dump 失败" | tee -a "$LOG"
  rm -f "$FILE"
  exit 1
fi
chmod 600 "$FILE"

SIZE=$(du -h "$FILE" | cut -f1)

# 完整性自检：pg_restore --list 读得出目录才算可用（不验证内容的备份等于没备份）
if docker compose exec -T postgres pg_restore --list < "$FILE" > /dev/null 2>&1; then
  echo "[$(date -Is)] ✅ 备份完成 $FILE ($SIZE)，完整性自检通过" | tee -a "$LOG"
else
  echo "[$(date -Is)] ❌ 备份文件无法解析，已删除 $FILE" | tee -a "$LOG"
  rm -f "$FILE"
  exit 1
fi

# 保留最近 KEEP 份
DELETED=$(ls -1t "$BACKUP_DIR"/points-*.dump 2>/dev/null | tail -n +$((KEEP + 1)) | wc -l | tr -d ' ')
ls -1t "$BACKUP_DIR"/points-*.dump 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f
[[ "$DELETED" != "0" ]] && echo "[$(date -Is)] 清理旧备份 $DELETED 份（保留最近 $KEEP 份）" | tee -a "$LOG"

echo "[$(date -Is)] 当前备份："
ls -lh "$BACKUP_DIR"/points-*.dump | awk '{print "  " $9 "  " $5}'
