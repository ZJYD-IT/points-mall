#!/usr/bin/env bash
# 启用 HTTPS（不需要买域名：用 nip.io 这类通配 DNS 指向 IP 即可签发真证书）
# 用法：bash ops/enable-tls.sh 149.28.133.245.nip.io
#       ACME_EMAIL=you@example.com bash ops/enable-tls.sh 149.28.133.245.nip.io
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/apps/points-mall}"
DOMAIN="${1:?用法: bash ops/enable-tls.sh <域名>，例如 149.28.133.245.nip.io}"
EMAIL="${ACME_EMAIL:-admin@${DOMAIN}}"
cd "$APP_DIR"

mkdir -p acme certs
chmod 755 acme
chmod 700 certs

echo "==> 1/4 检查域名解析"
MYIP="$(curl -s -m 10 https://api.ipify.org || true)"
RESOLVED="$(getent hosts "$DOMAIN" | awk '{print $1}' | head -1 || true)"
echo "    本机公网 IP: ${MYIP:-未知}"
echo "    域名解析到 : ${RESOLVED:-解析失败}"
[[ -z "$RESOLVED" ]] && { echo "❌ 域名解析不到"; exit 1; }
if [[ -n "$MYIP" && "$RESOLVED" != "$MYIP" ]]; then
  echo "❌ 解析到 $RESOLVED，不是本机 $MYIP，签发会失败"
  exit 1
fi

echo "==> 2/4 申请证书（Let's Encrypt，webroot 走 80 端口校验）"
docker run --rm \
  -v "$APP_DIR/certs:/etc/letsencrypt" \
  -v "$APP_DIR/acme:/var/www/acme" \
  certbot/certbot certonly --webroot -w /var/www/acme \
  -d "$DOMAIN" --agree-tos -m "$EMAIL" --non-interactive --keep-until-expiring

[[ -f "certs/live/$DOMAIN/fullchain.pem" ]] || { echo "❌ 证书没生成"; exit 1; }

echo "==> 3/4 备份原配置并写入 TLS 配置"
BAK="nginx.conf.bak.$(date +%Y%m%d-%H%M%S)"
cp nginx.conf "$BAK"
echo "    备份：$BAK"

cat > nginx.conf <<CONF
# 由 ops/enable-tls.sh 生成于 $(date -Is)
# 80 端口只保留 ACME 校验（续期要用），其余全部跳 HTTPS
server {
    listen 80;
    server_name _;
    client_max_body_size 20m;

    location /.well-known/acme-challenge/ {
        root /var/www/acme;
        default_type text/plain;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;
    client_max_body_size 20m;

    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_session_cache   shared:SSL:10m;

    add_header Strict-Transport-Security "max-age=31536000" always;

    location /api/ {
        proxy_pass http://api:8080;
        proxy_http_version 1.1;
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
    }

    location /admin/ {
        alias /usr/share/nginx/html/admin/;
        index index.html;
    }

    location / {
        root /usr/share/nginx/html/shop;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
CONF

echo "==> 4/4 校验配置并应用（校验失败自动还原）"
if docker compose exec -T web nginx -t >/dev/null 2>&1; then
  docker compose restart web
  echo
  echo "✅ HTTPS 已启用"
  echo "    https://$DOMAIN/"
  echo "    https://$DOMAIN/admin/"
  echo
  echo "别忘了续期（crontab.example 里有，每周跑一次）"
else
  echo "❌ nginx -t 校验失败，还原配置："
  docker compose exec -T web nginx -t 2>&1 | sed 's/^/    /' || true
  cp "$BAK" nginx.conf
  docker compose restart web
  echo "    已还原到 $BAK"
  exit 1
fi
