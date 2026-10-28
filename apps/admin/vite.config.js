import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  // 生产环境挂在 https://IP/admin/ 下，dev 时也用这个 base（所以本地地址是 http://localhost:5174/admin/）
  base: '/admin/',
  plugins: [vue()],
  server: {
    port: 5174,
    proxy: {
      '/api': { target: 'http://localhost:8080', changeOrigin: true }
    }
  },
  build: { outDir: 'dist' }
})
