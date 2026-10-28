# 构建上下文是仓库根目录，前端 dist 由 CI 先构建好
FROM nginx:1.27-alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY deploy/edge/nginx.conf /etc/nginx/conf.d/default.conf
COPY apps/shop/dist  /usr/share/nginx/html/shop
COPY apps/admin/dist /usr/share/nginx/html/admin
EXPOSE 80
