<template>
  <div class="wrap">
    <h1 class="title">积分商城</h1>
    <van-cell-group inset>
      <van-field v-model="account" label="手机号" placeholder="13800000000" />
      <van-field v-model="password" type="password" label="密码" placeholder="123456" />
    </van-cell-group>
    <div style="padding: 16px">
      <van-button type="primary" block :loading="loading" @click="submit">登录</van-button>
    </div>
    <p class="hint">演示账号：13800000000 / 123456</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { showToast } from 'vant'
import { userLogin } from '../api'

const account = ref('13800000000')
const password = ref('123456')
const loading = ref(false)
const router = useRouter()

async function submit() {
  loading.value = true
  try {
    const data = await userLogin(account.value, password.value)
    localStorage.setItem('shop_token', data.token)
    localStorage.setItem('shop_user', JSON.stringify(data))
    showToast('登录成功')
    router.push('/')
  } catch (e) {
    showToast(e.response?.data?.message || '登录失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.wrap { padding-top: 60px; }
.title { text-align: center; font-size: 22px; margin-bottom: 24px; }
.hint { text-align: center; color: #969799; font-size: 12px; margin-top: 12px; }
</style>
