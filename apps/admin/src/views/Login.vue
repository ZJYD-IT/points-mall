<template>
  <div class="login-wrap">
    <a-card title="积分商城 · 后台管理" style="width: 380px">
      <!-- 不用 @finish：ant-design-vue 4 的 a-form 里 finish 需要配合 :model 才会触发，
           这里直接用按钮的 @click，最不容易出问题 -->
      <a-form layout="vertical">
        <a-form-item label="用户名">
          <a-input v-model:value="account" placeholder="admin" @keyup.enter="submit" />
        </a-form-item>
        <a-form-item label="密码">
          <a-input-password v-model:value="password" placeholder="admin123" @keyup.enter="submit" />
        </a-form-item>

        <a-alert v-if="error" :message="error" type="error" show-icon style="margin-bottom: 12px" />

        <a-button type="primary" block :loading="loading" @click="submit">登录</a-button>
        <p class="hint">演示账号：admin / admin123</p>
      </a-form>
    </a-card>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { adminLogin, errMsg } from '../api'

const account = ref('admin')
const password = ref('admin123')
const loading = ref(false)
const error = ref('')
const router = useRouter()

async function submit() {
  if (loading.value) return
  error.value = ''
  loading.value = true
  try {
    const data = await adminLogin(account.value, password.value)
    localStorage.setItem('admin_token', data.token)
    localStorage.setItem('admin_user', JSON.stringify(data))
    message.success('登录成功')
    router.push('/')
  } catch (e) {
    const msg = errMsg(e)
    error.value = msg
    message.error(msg)
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrap { height: 100%; display: flex; align-items: center; justify-content: center; background: #f0f2f5; }
.hint { text-align: center; color: #999; font-size: 12px; margin-top: 12px; }
</style>
