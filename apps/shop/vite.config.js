import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      // 本地开发：/api 转发到本机 Spring Boot
      '/api': { target: 'http://localhost:8080', changeOrigin: true }
    }
  },
  build: { outDir: 'dist' }
})
