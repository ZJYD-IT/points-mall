import axios from 'axios'

export const http = axios.create({ baseURL: '/api', timeout: 15000 })

http.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('admin_token')
  if (token) cfg.headers.Authorization = `Bearer ${token}`
  return cfg
})

http.interceptors.response.use(
  (res) => res.data,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('admin_token')
      if (!location.hash.includes('/login')) {
        location.href = `${import.meta.env.BASE_URL}#/login`
      }
    }
    return Promise.reject(err)
  }
)

export const errMsg = (e) => e?.response?.data?.message || '请求失败'

export const adminLogin = (account, password) => http.post('/auth/admin/login', { account, password })

export const listProducts = () => http.get('/admin/products')
export const createProduct = (payload) => http.post('/admin/products', payload)
export const updateProduct = (id, payload) => http.put(`/admin/products/${id}`, payload)

export const listOrders = () => http.get('/admin/orders')
