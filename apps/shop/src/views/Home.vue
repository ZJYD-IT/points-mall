<template>
  <div class="page">
    <van-nav-bar title="积分商城" />

    <div class="points-card">
      <div class="points">{{ me.points ?? '--' }}</div>
      <div class="label">可用积分</div>
      <div class="links">
        <span @click="$router.push('/orders')">我的兑换</span>
        <span @click="$router.push('/ledger')">积分明细</span>
        <span @click="logout">退出</span>
      </div>
    </div>

    <van-loading v-if="loading" class="loading" />
    <van-empty v-else-if="!products.length" description="暂无商品" />

    <div v-else class="list">
      <div v-for="p in products" :key="p.id" class="item">
        <div class="info">
          <div class="name">{{ p.name }}</div>
          <div class="desc">{{ p.description }}</div>
          <div class="meta">
            <b>{{ p.pointsCost }}</b> 积分
            <span class="stock">库存 {{ p.stock }}</span>
          </div>
        </div>
        <van-button size="small" type="primary" :disabled="p.stock <= 0" @click="open(p)">
          {{ p.stock > 0 ? '兑换' : '已兑完' }}
        </van-button>
      </div>
    </div>

    <van-popup v-model:show="show" position="bottom" round>
      <div class="sheet" v-if="current">
        <h3>{{ current.name }}</h3>
        <p class="sub">{{ current.pointsCost }} 积分/件 · 剩余 {{ current.stock }} 件</p>
        <van-cell-group inset>
          <van-field v-model.number="form.quantity" type="digit" label="数量" />
          <van-field v-model="form.receiver" label="收件人" placeholder="选填" />
          <van-field v-model="form.phone" label="手机号" placeholder="选填" />
          <van-field v-model="form.address" label="地址" type="textarea" rows="2" autosize placeholder="选填" />
        </van-cell-group>
        <div class="total">
          合计 <b>{{ totalPoints }}</b> 积分
          <span v-if="!enough" class="warn">（积分不足）</span>
        </div>
        <van-button type="primary" block :loading="submitting" :disabled="!canSubmit" @click="submit">
          确认兑换
        </van-button>
      </div>
    </van-popup>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { showToast } from 'vant'
import { getMe, getProducts, redeem, errMsg, newIdempotencyKey } from '../api'

const router = useRouter()
const me = ref({})
const products = ref([])
const loading = ref(true)

const show = ref(false)
const current = ref(null)
const submitting = ref(false)
const form = reactive({ quantity: 1, receiver: '', phone: '', address: '' })
// 同一次「确认兑换」重试必须复用同一个幂等键，成功后清空
let idemKey = ''

const totalPoints = computed(() => (current.value?.pointsCost ?? 0) * (Number(form.quantity) || 0))
const enough = computed(() => totalPoints.value <= (me.value.points ?? 0))
const canSubmit = computed(() => form.quantity > 0 && enough.value && !submitting.value)

async function load() {
  loading.value = true
  try {
    const [m, ps] = await Promise.all([getMe(), getProducts()])
    me.value = m
    products.value = ps
  } catch (e) {
    showToast(errMsg(e))
  } finally {
    loading.value = false
  }
}

function open(p) {
  current.value = p
  form.quantity = 1
  form.receiver = ''
  form.phone = ''
  form.address = ''
  idemKey = newIdempotencyKey()
  show.value = true
}

async function submit() {
  submitting.value = true
  try {
    const r = await redeem({
      productId: current.value.id,
      quantity: Number(form.quantity),
      receiver: form.receiver || null,
      phone: form.phone || null,
      address: form.address || null,
      idempotencyKey: idemKey
    })
    showToast(r.repeated ? '这笔已兑换过，未重复扣积分' : `兑换成功，余额 ${r.balanceAfter}`)
    show.value = false
    idemKey = ''
    await load()
  } catch (e) {
    showToast(errMsg(e))
  } finally {
    submitting.value = false
  }
}

function logout() {
  localStorage.removeItem('shop_token')
  localStorage.removeItem('shop_user')
  router.push('/login')
}

onMounted(load)
</script>

<style scoped>
.page { padding-bottom: 24px; }
.points-card { margin: 12px 16px; padding: 20px; border-radius: 12px; color: #fff; text-align: center; background: linear-gradient(135deg, #1989fa, #39c5bb); }
.points { font-size: 36px; font-weight: 700; }
.label { font-size: 13px; opacity: .9; }
.links { margin-top: 12px; display: flex; justify-content: center; gap: 18px; font-size: 13px; }
.links span { text-decoration: underline; cursor: pointer; }
.loading { display: block; margin: 40px auto; }
.list { margin: 0 12px; }
.item { display: flex; align-items: center; gap: 12px; padding: 14px; background: #fff; border-radius: 10px; margin-bottom: 10px; }
.info { flex: 1; min-width: 0; }
.name { font-weight: 600; font-size: 15px; }
.desc { color: #969799; font-size: 12px; margin: 2px 0 6px; }
.meta { font-size: 13px; color: #ee0a24; }
.stock { color: #969799; margin-left: 8px; }
.sheet { padding: 16px 12px 24px; }
.sheet h3 { margin: 0 0 4px; font-size: 17px; }
.sub { color: #969799; font-size: 12px; margin: 0 0 12px; }
.total { text-align: center; margin: 14px 0; font-size: 14px; }
.total b { color: #ee0a24; font-size: 20px; }
.warn { color: #ee0a24; font-size: 12px; }
</style>
