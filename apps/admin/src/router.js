import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/', component: () => import('./views/Dashboard.vue') },
  { path: '/login', component: () => import('./views/Login.vue') }
]

const router = createRouter({
  // hash 路由 + base，部署到 /admin/ 下不用改 nginx 的 rewrite
  history: createWebHashHistory(import.meta.env.BASE_URL),
  routes
})

router.beforeEach((to) => {
  const token = localStorage.getItem('admin_token')
  if (!token && to.path !== '/login') return '/login'
  return true
})

export default router
