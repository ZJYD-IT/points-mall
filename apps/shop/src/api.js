import axios from 'axios'

// baseURL 用 /api：开发时由 Vite proxy 转发，生产由 nginx 反代
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

export const userLogin = (account, password) =>
  http.post('/auth/user/login', { account, password })
