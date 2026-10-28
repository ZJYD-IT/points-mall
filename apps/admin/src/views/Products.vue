<template>
  <a-layout style="height: 100%">
    <a-layout-sider theme="dark" width="200">
      <div class="logo">积分商城后台</div>
      <a-menu theme="dark" mode="inline" :selected-keys="['/products']" @click="go">
        <a-menu-item key="/">概览</a-menu-item>
        <a-menu-item key="/products">商品管理</a-menu-item>
        <a-menu-item key="/orders">兑换订单</a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout>
      <a-layout-header class="header">
        <a-button type="primary" @click="openCreate">新增商品</a-button>
      </a-layout-header>
      <a-layout-content style="padding: 24px">
        <a-card :bordered="false">
          <a-table :data-source="rows" :columns="columns" :loading="loading" row-key="id">
            <template #bodyCell="{ column, record }">
              <template v-if="column.dataIndex === 'pointsCost'">
                <b>{{ record.pointsCost }}</b>
              </template>
              <template v-else-if="column.dataIndex === 'stock'">
                <a-tag :color="record.stock > 0 ? 'blue' : 'red'">{{ record.stock }}</a-tag>
              </template>
              <template v-else-if="column.dataIndex === 'status'">
                <a-tag :color="record.status === 1 ? 'green' : 'default'">
                  {{ record.status === 1 ? '上架' : '下架' }}
                </a-tag>
              </template>
              <template v-else-if="column.dataIndex === 'action'">
                <a-space>
                  <a @click="openEdit(record)">编辑</a>
                  <a @click="toggle(record)">{{ record.status === 1 ? '下架' : '上架' }}</a>
                </a-space>
              </template>
            </template>
          </a-table>
        </a-card>
      </a-layout-content>
    </a-layout>

    <a-modal v-model:open="showModal" :title="editing ? '编辑商品' : '新增商品'" @ok="save" :confirm-loading="saving">
      <a-form layout="vertical" style="margin-top:12px">
        <a-form-item label="名称" required>
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item label="描述">
          <a-input v-model:value="form.description" />
        </a-form-item>
        <a-form-item label="所需积分" required>
          <a-input-number v-model:value="form.pointsCost" :min="1" style="width:100%" />
        </a-form-item>
        <a-form-item label="库存" required>
          <a-input-number v-model:value="form.stock" :min="0" style="width:100%" />
        </a-form-item>
        <a-form-item label="排序（越大越靠前）">
          <a-input-number v-model:value="form.sortNo" :min="0" style="width:100%" />
        </a-form-item>
      </a-form>
    </a-modal>
  </a-layout>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { listProducts, createProduct, updateProduct, errMsg } from '../api'

const router = useRouter()
const rows = ref([])
const loading = ref(false)
const showModal = ref(false)
const saving = ref(false)
const editing = ref(null)

const form = reactive({ name: '', description: '', pointsCost: 100, stock: 10, sortNo: 0 })

const columns = [
  { title: 'ID', dataIndex: 'id', width: 70 },
  { title: '名称', dataIndex: 'name' },
  { title: '描述', dataIndex: 'description', ellipsis: true },
  { title: '所需积分', dataIndex: 'pointsCost', width: 110 },
  { title: '库存', dataIndex: 'stock', width: 90 },
  { title: '状态', dataIndex: 'status', width: 90 },
  { title: '排序', dataIndex: 'sortNo', width: 80 },
  { title: '操作', dataIndex: 'action', width: 130 }
]

const go = ({ key }) => router.push(key)

async function load() {
  loading.value = true
  try {
    rows.value = await listProducts()
  } catch (e) {
    message.error(errMsg(e))
  } finally {
    loading.value = false
  }
}

function openCreate() {
  editing.value = null
  Object.assign(form, { name: '', description: '', pointsCost: 100, stock: 10, sortNo: 0 })
  showModal.value = true
}

function openEdit(r) {
  editing.value = r
  Object.assign(form, {
    name: r.name, description: r.description, pointsCost: r.pointsCost,
    stock: r.stock, sortNo: r.sortNo
  })
  showModal.value = true
}

async function save() {
  if (!form.name) return message.warning('请填名称')
  saving.value = true
  try {
    const payload = { ...form, status: editing.value ? editing.value.status : 1 }
    if (editing.value) {
      await updateProduct(editing.value.id, payload)
    } else {
      await createProduct(payload)
    }
    message.success('保存成功')
    showModal.value = false
    await load()
  } catch (e) {
    message.error(errMsg(e))
  } finally {
    saving.value = false
  }
}

async function toggle(r) {
  try {
    await updateProduct(r.id, {
      name: r.name, description: r.description, pointsCost: r.pointsCost,
      stock: r.stock, sortNo: r.sortNo, status: r.status === 1 ? 0 : 1
    })
    message.success(r.status === 1 ? '已下架' : '已上架')
    await load()
  } catch (e) {
    message.error(errMsg(e))
  }
}

onMounted(load)
</script>

<style scoped>
.logo { height: 48px; line-height: 48px; color: #fff; text-align: center; font-weight: 600; }
.header { background: #fff; display: flex; justify-content: flex-end; align-items: center; padding-right: 16px; }
</style>
