<template>
  <div class="login-wrap">
    <a-card title="积分商城 · 后台管理" style="width: 380px">
      <a-form layout="vertical" @finish="submit">
        <a-form-item label="用户名">
          <a-input v-model:value="account" placeholder="admin" />
        </a-form-item>
        <a-form-item label="密码">
          <a-input-password v-model:value="password" placeholder="admin123" />
        </a-form-item>
        <a-button type="primary" html-type="submit" block :loading="loading">登录</a-button>
        <p class="hint">演示账号：admin / admin123</p>
      </a-form>
    </a-card>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { adminLogin } from '../api'

const account = ref('admin')
const password = ref('admin123')
const loading = ref(false)
const router = useRouter()

async function submit() {
  loading.value = true
  try {
    const data = await adminLogin(account.value, password.value)
    localStorage.setItem('admin_token', data.token)
    localStorage.setItem('admin_user', JSON.stringify(data))
    message.success('登录成功')
    router.push('/')
  } catch (e) {
    message.error(e.response?.status === 401 ? '账号或密码错误' : '登录失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrap { height: 100%; display: flex; align-items: center; justify-content: center; background: #f0f2f5; }
.hint { text-align: center; color: #999; font-size: 12px; margin-top: 12px; }
</style>
