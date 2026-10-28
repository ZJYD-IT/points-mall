import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/', component: () => import('./views/Dashboard.vue') },
  { path: '/products', component: () => import('./views/Products.vue') },
  { path: '/orders', component: () => import('./views/Orders.vue') },
  { path: '/login', component: () => import('./views/Login.vue') }
]

const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL),
  routes
})

router.beforeEach((to) => {
  const token = localStorage.getItem('admin_token')
  if (!token && to.path !== '/login') return '/login'
  return true
})

export default router
