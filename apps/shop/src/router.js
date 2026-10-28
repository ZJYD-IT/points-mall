import { createRouter, createWebHashHistory } from 'vue-router'

const routes = [
  { path: '/', component: () => import('./views/Home.vue') },
  { path: '/orders', component: () => import('./views/Orders.vue') },
  { path: '/ledger', component: () => import('./views/Ledger.vue') },
  { path: '/login', component: () => import('./views/Login.vue') }
]

const router = createRouter({ history: createWebHashHistory(), routes })

router.beforeEach((to) => {
  const token = localStorage.getItem('shop_token')
  if (!token && to.path !== '/login') return '/login'
  return true
})

export default router
