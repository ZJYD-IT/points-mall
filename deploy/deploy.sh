#!/usr/bin/env bash
# 在服务器上执行：bash deploy.sh <tag>
# 做的事：确保数据库在跑 → 拉新镜像 → 重启 api/web → 健康检查 → 失败自动回滚
#
# 注意：api/web 用 --no-deps 启动是故意的 —— 每次发布不应该重启数据库。
# 但正因为 --no-deps，数据库必须【单独确保】在运行，否则首次部署会缺 postgres，
# API 连不上库就一直起不来（这就是第一版部署失败的真实原因）。
set -euo pipefail

TAG="${1:?用法: bash deploy.sh <tag>}"
cd "$(dirname "$0")"

PREV_TAG="$(cat .tag 2>/dev/null || echo '')"

# nginx.conf 是挂载进 web 容器的。如果它不存在，docker 会自动建一个同名目录，
# 导致 nginx 启动失败。这里提前拦住，给出明确提示。
if [[ ! -f nginx.conf ]]; then
  echo "❌ 缺少 nginx.conf（应由发布流水线同步到当前目录）"
  exit 1
fi

# ---------- 1. 确保数据库在运行（首次部署 / 服务器重启后都需要）----------
echo "==> 确保数据库容器在运行"
docker compose up -d postgres

echo "==> 等待 postgres 健康"
db_ok=0
for i in $(seq 1 30); do
  if docker compose ps postgres 2>/dev/null | grep -q 'healthy'; then
    echo "    ✅ postgres 已就绪（约 $((i * 2)) 秒）"
    db_ok=1
    break
  fi
  sleep 2
done
if [[ "$db_ok" -ne 1 ]]; then
  echo "    ❌ postgres 未能就绪，最近日志："
  docker compose logs --tail=40 postgres || true
  exit 1
fi

# ---------- 2. 拉取新镜像 ----------
echo "==> 拉取镜像 TAG=$TAG"
TAG="$TAG" docker compose pull api web

# ---------- 3. 只重启应用，不动数据库 ----------
echo "==> 重启 api / web（数据库容器不动）"
TAG="$TAG" docker compose up -d --no-deps api web

# ---------- 4. 健康检查 ----------
echo "==> 健康检查 http://127.0.0.1/api/health"
for i in $(seq 1 30); do
  if curl -fsS -m 5 http://127.0.0.1/api/health >/dev/null 2>&1; then
    echo "==> ✅ 健康检查通过（约 $((i * 2)) 秒）"
    echo "$TAG" > .tag
    docker image prune -f --filter "until=168h" >/dev/null 2>&1 || true
    exit 0
  fi
  sleep 2
done

# ---------- 5. 失败：打印日志 + 回滚 ----------
echo "==> ❌ 健康检查失败，api 最近日志："
docker compose logs --tail=60 api || true

if [[ -n "$PREV_TAG" && "$PREV_TAG" != "$TAG" ]]; then
  echo "==> 回滚到 TAG=$PREV_TAG"
  TAG="$PREV_TAG" docker compose up -d --no-deps api web
else
  echo "==> 没有可回滚的历史版本（首次部署），保持现状便于排查"
fi
exit 1
