# 积分商城（练习项目）

一个人维护的全栈项目：客户端 H5 + 后台管理 + API，带一键发布流水线。

| 目录 | 技术栈 | 说明 |
|---|---|---|
| `apps/shop` | Vue 3 + Vite + Vant 4 | 客户端 H5（移动端） |
| `apps/admin` | Vue 3 + Vite + Ant Design Vue | 后台管理 |
| `apps/api` | Spring Boot 3.3 + JPA + Flyway + PostgreSQL 16 | 接口服务 |
| `deploy` | Docker Compose + nginx | 一台机器跑全套 |
| `.github/workflows` | GitHub Actions | CI + 手动触发的发布 |

## 当前进度

- [x] Phase 1：骨架、数据库迁移、JWT 认证、Docker 编排、一键发布
- [x] Phase 2：商品管理、积分流水、兑换流程（幂等 + 事务 + 原子扣减防超卖）
- [ ] Phase 3：客户端页面、订单、监控、备份演练
- [ ] Phase 4（可选）：AI 客服 / 推荐

---

## 一、本地跑起来

### 0. 前置

- JDK 17、Maven（用仓库自带的 `./mvnw` 即可）
- Node 20+
- Docker（用来跑 PostgreSQL）

### 1. 起数据库

```bash
docker run -d --name points-pg \
  -e POSTGRES_DB=points -e POSTGRES_USER=points -e POSTGRES_PASSWORD=points_dev_pwd \
  -p 5432:5432 postgres:16-alpine
```

### 2. 起后端

```bash
cd apps/api
./mvnw spring-boot:run
```

启动时 Flyway 会自动建表，`DataSeeder` 会写两个演示账号并在日志里提示：

| 角色 | 账号 | 密码 |
|---|---|---|
| 后台 | `admin` | `admin123` |
| 客户端 | `13800000000` | `123456`（初始 1000 积分） |

接口文档：<http://localhost:8080/api/swagger-ui.html>

### 3. 起前端

```bash
# 客户端 → http://localhost:5173
cd apps/shop && npm install && npm run dev

# 后台 → http://localhost:5174/admin/
cd apps/admin && npm install && npm run dev
```

> 注意后台用了 `base: '/admin/'`，所以本地地址是 `http://localhost:5174/admin/`。

---

## 二、推送到 GitHub

```bash
git init
git add .
git commit -m "Phase 1: 骨架 + 认证 + 部署流水线"
git branch -M main
git remote add origin git@github.com:<你的用户名>/points-mall.git
git push -u origin main
```

推上去后 CI 会自动跑一次（`.github/workflows/ci.yml`）。

---

## 三、服务器一次性准备

### 1. 基础环境

按 `practice-server/init-server.sh` 跑过之后，服务器上已经有 Docker 和 ufw（只开 22/80/443）。

### 2. 建目录 + 填 .env

```bash
mkdir -p /opt/apps/points-mall && cd /opt/apps/points-mall
cp deploy/.env.example .env      # 或手写
```

`.env` 至少要改这几项：

```ini
POSTGRES_PASSWORD=<强密码>
JWT_SECRET=<openssl rand -base64 48 的输出>
REGISTRY=ghcr.io/<你的github用户名小写>
CORS_ORIGINS=http://149.28.133.245
```

### 3. 拉私有镜像需要登录 GHCR（二选一）

- **方式 A**：把两个 package 设为 public
  GitHub → 你的 Packages → `points-api` / `points-web` → Package settings → Change visibility → Public
- **方式 B**：服务器登录一次
  ```bash
  echo <你的GitHub PAT，勾选 read:packages> | docker login ghcr.io -u <用户名> --password-stdin
  ```

---

## 四、配置 GitHub Secrets

仓库 → **Settings → Secrets and variables → Actions → New repository secret**

| Name | 值 |
|---|---|
| `DEPLOY_HOST` | 服务器 IP，如 `149.28.133.245` |
| `DEPLOY_USER` | `root` |
| `DEPLOY_PATH` | `/opt/apps/points-mall` |
| `DEPLOY_SSH_KEY` | 服务器私钥全文（`cat ~/.ssh/id_ed25519`，含 `-----BEGIN` 和 `-----END`） |

> 也可以单独新建一对部署专用密钥，把公钥追加到服务器 `~/.ssh/authorized_keys`，私钥放这里。

---

## 五、点一下发布

GitHub 仓库页面 → **Actions** → 左侧 **Deploy** → 右侧 **Run workflow**

```
① 构建 api 镜像并推 ghcr.io/<owner>/points-api:<tag>
② 构建 shop / admin 两个前端
③ 构建 web 镜像并推 ghcr.io/<owner>/points-web:<tag>
④ scp 编排文件到服务器，SSH 执行 deploy.sh <tag>
⑤ deploy.sh：docker compose pull → up -d → 轮询 /api/health 最多 60 秒
   ├─ 通过 → 记录 .tag，成功
   └─ 失败 → 自动回滚到上一个 tag 并返回失败
```

访问：

| 地址 | 内容 |
|---|---|
| `http://<服务器IP>/` | 客户端 H5 |
| `http://<服务器IP>/admin/` | 后台管理 |
| `http://<服务器IP>/api/health` | 健康检查 |

---

## 六、接口清单

| 方法 | 路径 | 权限 | 说明 |
|---|---|---|---|
| POST | `/api/auth/admin/login` | 公开 | 后台登录 |
| POST | `/api/auth/user/login` | 公开 | 客户端登录 |
| GET | `/api/health` | 公开 | 健康检查（发布流水线用） |
| GET | `/api/shop/me` | USER | 我的信息 + 积分余额 |
| GET | `/api/shop/products` | USER | 上架商品 |
| POST | `/api/shop/redeem` | USER | **兑换**（幂等键必填） |
| GET | `/api/shop/orders` | USER | 我的兑换单 |
| GET | `/api/shop/ledger` | USER | 我的积分明细 |
| GET | `/api/admin/products` | ADMIN | 全部商品 |
| POST | `/api/admin/products` | ADMIN | 新增商品 |
| PUT | `/api/admin/products/{id}` | ADMIN | 修改/上下架 |
| GET | `/api/admin/orders` | ADMIN | 全部兑换单 |

### 兑换流程怎么保证不出错

```
① 幂等：唯一约束 (user_id, idempotency_key)
   └─ 同一笔重复提交 → 第二次直接返回已有订单，不重复扣积分
② 防超卖 / 防透支：条件更新一条 SQL 搞定
   update product   set stock  = stock  - ? where id=? and stock  >= ?
   update app_user  set points = points - ? where id=? and points >= ?
   └─ 返回影响行数 0 就抛业务异常，判断和扣减是原子的
③ 一致性：扣库存 + 扣积分 + 写订单 + 写流水在同一个事务里
   └─ 任何一步失败全部回滚，不会出现"扣了积分没给货"
④ 可对账：每次积分变动都写 points_ledger，余额可用流水全量重算
```

## 七、日常命令

```bash
cd /opt/apps/points-mall

docker compose ps                 # 看状态
docker compose logs -f api        # 看后端日志
docker compose logs -f web
docker compose down               # 停（数据在 volume 里，不会丢）
docker compose down -v            # ⚠️ 连数据一起删

# 手动执行一次部署（等价于点按钮）
bash deploy.sh <tag>

# ⚠️ 手动跑 compose 时，凡是涉及 api / web 都要带 TAG，否则会退化成"本地构建"
TAG=<tag> docker compose up -d api web    ✅
docker compose up -d api web              ❌ 会用 latest 然后尝试本地构建
```

---

## 八、设计上的几个决定（面试会被问）

1. **表结构只由 Flyway 管**：`ddl-auto: validate`，JPA 不会偷偷改表。
2. **积分余额 + 流水双写**：`app_user.points` 是冗余余额，`points_ledger` 是只增流水，可对账。
3. **乐观锁**：`app_user.version` 用 `@Version`，兑换时并发扣积分不会超扣。
4. **镜像 Tag 用 commit SHA**：每次发布可追溯、可回滚。
5. **健康检查在流水线里**：不是"部署成功"就算成功，`/api/health` 通过才算。
6. **数据库不映射端口**：只走 Docker 内网，外面连不上。
7. **只暴露必要端口**：ufw 只放 22/80/443。
8. **发布先确保数据库在跑**：`deploy.sh` 会先拉起并等待 postgres 健康，
   再 `--no-deps` 重启 api/web —— 不重启数据库，但也不会漏掉它。
9. **镜像 tag 用 commit SHA**：可追溯、可回滚；`deploy.sh` 健康检查失败会自动退回上一个 tag。

---

## 九、运维：备份 / 恢复演练 / 监控

脚本都在 `ops/`，部署时会自动同步到服务器 `$DEPLOY_PATH/ops/`。

### 1. 备份

```bash
# 手动跑一次
ssh root@<服务器IP> 'cd /opt/apps/points-mall && bash ops/backup.sh'

# 装定时任务
ssh root@<服务器IP> 'crontab -e'
# 把 ops/crontab.example 里的两行粘进去
```

备份文件落在 `/opt/backups/points-mall/`，`-Fc` 自定义格式，保留最近 7 份。
每次备份都会用 `pg_restore --list` 做**完整性自检** —— 读不出来的备份直接删掉并报错，
避免"以为备份了其实是个空文件"。

### 2. 恢复演练（这是重点）

```bash
ssh root@<服务器IP> 'cd /opt/apps/points-mall && bash ops/restore-drill.sh'
```

它会：

```
① 新建临时库 drill_<时间戳>
② 用最近一份备份 pg_restore 进去
③ 逐表比对行数：admin_user / app_user / product / redeem_order / points_ledger
④ 积分对账：用户余额 vs 流水累计
⑤ 删掉临时库
⑥ 输出 RTO（恢复耗时）
```

**输出示例**：

```
=== 结果 ===
  恢复耗时（RTO）: 3 秒
  ✅ 恢复演练通过
```

> "我做过恢复演练，RTO 是 3 秒" —— 这句话比"我每天备份"值钱得多。

### 3. 监控

`ops/health-watch.sh` 每 5 分钟探一次 `/api/health`，**只在状态变化时**写一条告警
（避免每 5 分钟刷一条），可选通过 `HEALTH_WEBHOOK` 环境变量推 webhook。

```bash
cat /opt/backups/health-alerts.log     # 看告警历史
```

### 4. 故障演练剧本（手工做，练的是判断力）

| 剧本 | 制造故障 | 你要观察/记录 |
|---|---|---|
| 数据库挂了 | `docker compose stop postgres` | 前端报什么错？多久发现？`docker compose start postgres` 后能自愈吗？ |
| API 挂了 | `docker compose stop api` | 健康检查多久探测到？deploy.sh 会回滚吗？ |
| 磁盘满了 | `fallocate -l 100G /tmp/fill` | 日志里报什么？备份会失败吗？怎么定位？ |
| 误删数据 | `delete from product` | 从备份恢复到可用要多久？（正好用 restore-drill 量） |

每次演练记录三件事：**现象 / 发现时间 / 恢复时间**。这三行就是你的运维履历。
