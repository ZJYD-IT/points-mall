<template>
  <div>
    <van-nav-bar title="积分商城" />
    <div class="card">
      <div class="points">{{ user.points ?? 0 }}</div>
      <div class="label">我的积分</div>
    </div>
    <van-empty description="商品列表在 Phase 2 上线" />
    <div style="padding: 16px">
      <van-button block @click="logout">退出登录</van-button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const user = computed(() => JSON.parse(localStorage.getItem('shop_user') || '{}'))

function logout() {
  localStorage.removeItem('shop_token')
  localStorage.removeItem('shop_user')
  router.push('/login')
}
</script>

<style scoped>
.card { margin: 16px; padding: 24px; background: linear-gradient(135deg, #1989fa, #39c5bb); border-radius: 12px; color: #fff; text-align: center; }
.points { font-size: 36px; font-weight: 700; }
.label { font-size: 13px; opacity: 0.9; margin-top: 4px; }
</style>
