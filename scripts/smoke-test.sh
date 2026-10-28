#!/usr/bin/env bash
# 兑换流程冒烟测试
# 用法：bash scripts/smoke-test.sh [http://服务器IP]
# 依赖：curl、python3
set -uo pipefail

BASE="${1:-http://149.28.133.245}"
PASS=0; FAIL=0
ok()  { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

jget() {
  python3 -c '
import sys, json
d = json.load(sys.stdin)
for p in sys.argv[1].split("."):
    d = d[int(p)] if p.lstrip("-").isdigit() else d[p]
print(d)
' "$1"
}

post() { curl -s -m 15 -X POST "$BASE$1" -H "Content-Type: application/json" ${3:+-H "Authorization: Bearer $3"} -d "$2"; }
get()  { curl -s -m 15 "$BASE$1" ${2:+-H "Authorization: Bearer $2"}; }

echo "=== 目标：$BASE ==="

# ---------- 0. 登录 ----------
ADMIN=$(post /api/auth/admin/login '{"account":"admin","password":"admin123"}' | jget token) || true
USER=$(post  /api/auth/user/login  '{"account":"13800000000","password":"123456"}' | jget token) || true
[[ -z "$ADMIN" ]] && { bad "后台登录失败，后面全跳过"; exit 1; }
[[ -z "$USER"  ]] && { bad "客户端登录失败，后面全跳过"; exit 1; }
ok "后台登录、客户端登录"

# ---------- 1. 建一个专用测试商品（库存 5，1 积分）----------
PID=$(post /api/admin/products '{"name":"压测商品","pointsCost":1,"stock":5,"sortNo":-1,"status":1}' "$ADMIN" | jget id) || true
[[ -z "$PID" ]] && { bad "创建测试商品失败"; exit 1; }
ok "创建测试商品 id=${PID}（库存 5、单价 1 积分）"

# ---------- 2. 幂等：同一个 key 提交两次 ----------
P0=$(get /api/shop/me "$USER" | jget points 2>/dev/null) || P0=0
K="idem-$RANDOM$RANDOM"
R1=$(post /api/shop/redeem "{\"productId\":$PID,\"quantity\":1,\"idempotencyKey\":\"$K\"}" "$USER")
R2=$(post /api/shop/redeem "{\"productId\":$PID,\"quantity\":1,\"idempotencyKey\":\"$K\"}" "$USER")
N1=$(echo "$R1" | jget orderNo 2>/dev/null) || true
N2=$(echo "$R2" | jget orderNo 2>/dev/null) || true
REP=$(echo "$R2" | jget repeated 2>/dev/null) || true
P1=$(get /api/shop/me "$USER" | jget points 2>/dev/null) || P1=0

if [[ "$N1" == "$N2" && "$REP" == "True" ]]; then ok "幂等：第二次返回同一单 ${N1}（repeated=${REP}）"; else bad "幂等失效：$N1 / $N2 (repeated=$REP)"; fi
if [[ $((P0 - P1)) -eq 1 ]]; then ok "幂等：积分只扣了 1 次（$P0 → ${P1}）"; else bad "重复扣积分：$P0 → $P1"; fi

# ---------- 3. 并发 20 个请求抢 5 件库存 ----------
TMP=$(mktemp -d)
echo "  … 并发提交 20 个兑换请求（库存只有 4 件了）"
for i in $(seq 1 20); do
  ( curl -s -o "$TMP/$i.json" -w '%{http_code}' -m 20 -X POST "$BASE/api/shop/redeem" \
      -H "Authorization: Bearer $USER" -H 'Content-Type: application/json' \
      -d "{\"productId\":$PID,\"quantity\":1,\"idempotencyKey\":\"conc-$K-$i\"}" > "$TMP/$i.code" ) &
done
wait
SUCCESS=$(grep -l '^200$' "$TMP"/*.code 2>/dev/null | wc -l | tr -d ' ')
RESTOCK=$(get /api/admin/products "$ADMIN" | python3 -c "
import sys, json
for p in json.load(sys.stdin):
    if p['id'] == $PID: print(p['stock'])
")
if [[ "${SUCCESS:-x}" == "4" ]]; then ok "并发：20 个请求里恰好 4 个成功（库存 4）"; else bad "并发：成功 $SUCCESS 个，期望 4 个"; fi
if [[ "${RESTOCK:-x}" == "0" ]]; then ok "并发：最终库存为 0，没有超卖"; else bad "库存变成 ${RESTOCK}，超卖或异常"; fi

# ---------- 4. 库存不足 ----------
R=$(post /api/shop/redeem "{\"productId\":$PID,\"quantity\":1,\"idempotencyKey\":\"oos-$RANDOM\"}" "$USER")
MSG=$(echo "$R" | jget message 2>/dev/null) || true
[[ "$MSG" == *"库存不足"* ]] && ok "库存为 0 时拒绝兑换：$MSG" || bad "库存校验异常：$R"

# ---------- 5. 下架商品 ----------
R=$(post /api/shop/redeem "{\"productId\":6,\"quantity\":1,\"idempotencyKey\":\"off-$RANDOM\"}" "$USER")
MSG=$(echo "$R" | jget message 2>/dev/null) || true
[[ "$MSG" == *"下架"* ]] && ok "下架商品拒绝兑换：$MSG" || bad "下架校验异常：$R"

# ---------- 6. 积分不足 ----------
BIG=$(post /api/admin/products '{"name":"天价商品","pointsCost":999999,"stock":1,"status":1}' "$ADMIN" | jget id) || true
R=$(post /api/shop/redeem "{\"productId\":$BIG,\"quantity\":1,\"idempotencyKey\":\"poor-$RANDOM\"}" "$USER")
MSG=$(echo "$R" | jget message 2>/dev/null) || true
[[ "$MSG" == *"积分不足"* ]] && ok "积分不足拒绝兑换：$MSG" || bad "积分校验异常：$R"

# ---------- 7. 流水与订单 ----------
LEDGER=$(get /api/shop/ledger "$USER" | python3 -c "import sys,json;print(len(json.load(sys.stdin)))")
ORDERS=$(get /api/shop/orders "$USER" | python3 -c "import sys,json;print(len(json.load(sys.stdin)))")
ok "积分流水 $LEDGER 条、兑换单 $ORDERS 条"

rm -rf "$TMP"
echo
echo "=== 结果：通过 $PASS 项，失败 $FAIL 项 ==="
[[ "$FAIL" -eq 0 ]] || exit 1
