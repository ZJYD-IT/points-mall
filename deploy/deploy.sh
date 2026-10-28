#!/usr/bin/env bash
# 在服务器上执行：bash deploy.sh <tag>
# 做的事：拉新镜像 → 重启 api/web（不动数据库）→ 健康检查 → 失败自动回滚
set -euo pipefail

TAG="${1:?用法: bash deploy.sh <tag>}"
cd "$(dirname "$0")"

PREV_TAG="$(cat .tag 2>/dev/null || echo '')"

echo "==> 拉取镜像 TAG=$TAG"
TAG="$TAG" docker compose pull api web

echo "==> 重启 api / web（数据库容器不动）"
TAG="$TAG" docker compose up -d --no-deps api web

echo "==> 健康检查 http://127.0.0.1/api/health"
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1/api/health >/dev/null 2>&1; then
    echo "==> ✅ 健康检查通过（约 $((i * 2)) 秒）"
    echo "$TAG" > .tag
    docker image prune -f --filter "until=168h" >/dev/null 2>&1 || true
    exit 0
  fi
  sleep 2
done

echo "==> ❌ 健康检查失败"
if [[ -n "$PREV_TAG" && "$PREV_TAG" != "$TAG" ]]; then
  echo "==> 回滚到 TAG=$PREV_TAG"
  TAG="$PREV_TAG" docker compose up -d --no-deps api web
fi
exit 1
