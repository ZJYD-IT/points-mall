<template>
  <a-layout style="height: 100%">
    <a-layout-sider theme="dark" width="200">
      <div class="logo">积分商城后台</div>
      <a-menu theme="dark" mode="inline" :selected-keys="['dashboard']">
        <a-menu-item key="dashboard">概览</a-menu-item>
        <a-menu-item key="products" disabled>商品管理（Phase 2）</a-menu-item>
        <a-menu-item key="orders" disabled>兑换订单（Phase 2）</a-menu-item>
        <a-menu-item key="users" disabled>用户与积分（Phase 2）</a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout>
      <a-layout-header class="header">
        <span>{{ user.displayName || '管理员' }}</span>
        <a-button type="link" @click="logout">退出</a-button>
      </a-layout-header>
      <a-layout-content style="padding: 24px">
        <a-card title="系统状态">
          <a-descriptions :column="2" bordered>
            <a-descriptions-item label="后端接口">
              <a-tag :color="health === 'UP' ? 'green' : 'red'">{{ health || '检查中…' }}</a-tag>
            </a-descriptions-item>
            <a-descriptions-item label="当前用户">{{ user.displayName }}</a-descriptions-item>
            <a-descriptions-item label="登录角色">{{ user.role }}</a-descriptions-item>
            <a-descriptions-item label="阶段">Phase 1 · 骨架 + 认证 + 部署</a-descriptions-item>
          </a-descriptions>
        </a-card>
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { http } from '../api'

const router = useRouter()
const user = computed(() => JSON.parse(localStorage.getItem('admin_user') || '{}'))
const health = ref('')

onMounted(async () => {
  try {
    const r = await http.get('/health')
    health.value = r.status
  } catch {
    health.value = 'DOWN'
  }
})

function logout() {
  localStorage.removeItem('admin_token')
  localStorage.removeItem('admin_user')
  router.push('/login')
}
</script>

<style scoped>
.logo { height: 48px; line-height: 48px; color: #fff; text-align: center; font-weight: 600; }
.header { background: #fff; display: flex; justify-content: flex-end; align-items: center; gap: 8px; padding-right: 16px; }
</style>
