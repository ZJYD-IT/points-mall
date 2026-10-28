import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/', component: () => import('./views/Home.vue') },
  { path: '/login', component: () => import('./views/Login.vue') }
]

// 客户端用 hash 路由，避免 nginx 需要额外的 try_files 配置
const router = createRouter({ history: createWebHashHistory(), routes })

router.beforeEach((to) => {
  const token = localStorage.getItem('shop_token')
  if (!token && to.path !== '/login') return '/login'
  return true
})

export default router
