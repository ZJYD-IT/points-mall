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
      if (!location.pathname.endsWith('/login')) {
        location.href = `${import.meta.env.BASE_URL}#/login`
      }
    }
    return Promise.reject(err)
  }
)

export const adminLogin = (account, password) =>
  http.post('/auth/admin/login', { account, password })
