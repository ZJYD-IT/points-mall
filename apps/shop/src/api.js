import axios from 'axios'

export const http = axios.create({ baseURL: '/api', timeout: 15000 })

http.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('shop_token')
  if (token) cfg.headers.Authorization = `Bearer ${token}`
  return cfg
})

http.interceptors.response.use(
  (res) => res.data,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('shop_token')
      if (location.hash !== '#/login') location.hash = '#/login'
    }
    return Promise.reject(err)
  }
)

/** 后端统一错误体是 { code, message }，这里提取出来给页面用 */
export const errMsg = (e) => e?.response?.data?.message || '请求失败'

/**
 * 幂等键。
 * 注意：crypto.randomUUID() 只在安全上下文（HTTPS / localhost）可用，
 * 我们目前是 http://IP 访问，所以要留降级方案。
 */
export function newIdempotencyKey() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return 'k' + Date.now().toString(36) + Math.random().toString(36).slice(2, 12)
}

export const userLogin = (account, password) => http.post('/auth/user/login', { account, password })
export const getMe = () => http.get('/shop/me')
export const getProducts = () => http.get('/shop/products')
export const redeem = (payload) => http.post('/shop/redeem', payload)
export const getOrders = () => http.get('/shop/orders')
export const getLedger = () => http.get('/shop/ledger')
