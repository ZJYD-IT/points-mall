<template>
  <div>
    <van-nav-bar title="我的兑换" left-arrow @click-left="$router.back()" />
    <van-loading v-if="loading" style="display:block;margin:40px auto" />
    <van-empty v-else-if="!orders.length" description="还没有兑换记录" />
    <div v-else class="list">
      <div v-for="o in orders" :key="o.id" class="card">
        <div class="row">
          <span class="name">{{ o.productName }}</span>
          <van-tag type="success">{{ o.status }}</van-tag>
        </div>
        <div class="row sub">
          <span>单号 {{ o.orderNo }}</span>
          <span>×{{ o.quantity }}</span>
        </div>
        <div class="row sub">
          <span>{{ fmt(o.createdAt) }}</span>
          <span class="points">-{{ o.totalPoints }} 积分</span>
        </div>
        <div v-if="o.address || o.receiver" class="row sub">
          {{ o.receiver || '' }} {{ o.phone || '' }} {{ o.address || '' }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { showToast } from 'vant'
import { getOrders, errMsg } from '../api'

const orders = ref([])
const loading = ref(true)

const fmt = (s) => (s ? String(s).replace('T', ' ').slice(0, 19) : '')

onMounted(async () => {
  try {
    orders.value = await getOrders()
  } catch (e) {
    showToast(errMsg(e))
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.list { padding: 12px; }
.card { background: #fff; border-radius: 10px; padding: 12px 14px; margin-bottom: 10px; }
.row { display: flex; justify-content: space-between; align-items: center; gap: 8px; }
.name { font-weight: 600; }
.sub { color: #969799; font-size: 12px; margin-top: 6px; }
.points { color: #ee0a24; }
</style>
