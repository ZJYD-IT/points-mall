<template>
  <a-layout style="height: 100%">
    <a-layout-sider theme="dark" width="200">
      <div class="logo">积分商城后台</div>
      <a-menu theme="dark" mode="inline" :selected-keys="['/orders']" @click="go">
        <a-menu-item key="/">概览</a-menu-item>
        <a-menu-item key="/products">商品管理</a-menu-item>
        <a-menu-item key="/orders">兑换订单</a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout>
      <a-layout-header class="header"><span>共 {{ rows.length }} 单</span></a-layout-header>
      <a-layout-content style="padding: 24px">
        <a-card :bordered="false">
          <a-table :data-source="rows" :columns="columns" :loading="loading" row-key="id"
                   :pagination="{ pageSize: 20 }">
            <template #bodyCell="{ column, record }">
              <template v-if="column.dataIndex === 'createdAt'">
                {{ fmt(record.createdAt) }}
              </template>
              <template v-else-if="column.dataIndex === 'totalPoints'">
                <b style="color:#f5222d">{{ record.totalPoints }}</b>
              </template>
              <template v-else-if="column.dataIndex === 'status'">
                <a-tag color="green">{{ record.status }}</a-tag>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-layout-content>
    </a-layout>
  </a-layout>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { listOrders, errMsg } from '../api'

const router = useRouter()
const rows = ref([])
const loading = ref(false)
const go = ({ key }) => router.push(key)
const fmt = (s) => (s ? String(s).replace('T', ' ').slice(0, 19) : '')

const columns = [
  { title: '单号', dataIndex: 'orderNo', width: 190 },
  { title: '商品', dataIndex: 'productName' },
  { title: '单价', dataIndex: 'pointsCost', width: 90 },
  { title: '数量', dataIndex: 'quantity', width: 70 },
  { title: '总积分', dataIndex: 'totalPoints', width: 100 },
  { title: '状态', dataIndex: 'status', width: 100 },
  { title: '收件人', dataIndex: 'receiver', width: 110 },
  { title: '时间', dataIndex: 'createdAt', width: 180 }
]

onMounted(async () => {
  loading.value = true
  try {
    rows.value = await listOrders()
  } catch (e) {
    message.error(errMsg(e))
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.logo { height: 48px; line-height: 48px; color: #fff; text-align: center; font-weight: 600; }
.header { background: #fff; display: flex; justify-content: flex-end; align-items: center; padding-right: 16px; }
</style>
