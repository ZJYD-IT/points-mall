<template>
  <div>
    <van-nav-bar title="积分明细" left-arrow @click-left="$router.back()" />
    <van-loading v-if="loading" style="display:block;margin:40px auto" />
    <van-empty v-else-if="!list.length" description="暂无明细" />
    <van-cell-group v-else inset style="margin-top:12px">
      <van-cell v-for="l in list" :key="l.id">
        <template #title>
          <span :class="l.delta > 0 ? 'plus' : 'minus'">{{ l.delta > 0 ? '+' : '' }}{{ l.delta }}</span>
          <span class="type">{{ l.bizType }}</span>
        </template>
        <template #label>
          <span>{{ l.remark || '' }}</span>
          <br />
          <span>{{ fmt(l.createdAt) }} · 余额 {{ l.balanceAfter }}</span>
        </template>
      </van-cell>
    </van-cell-group>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { showToast } from 'vant'
import { getLedger, errMsg } from '../api'

const list = ref([])
const loading = ref(true)
const fmt = (s) => (s ? String(s).replace('T', ' ').slice(0, 19) : '')

onMounted(async () => {
  try {
    list.value = await getLedger()
  } catch (e) {
    showToast(errMsg(e))
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.plus { color: #07c160; font-weight: 600; }
.minus { color: #ee0a24; font-weight: 600; }
.type { margin-left: 8px; color: #969799; font-size: 12px; }
</style>
