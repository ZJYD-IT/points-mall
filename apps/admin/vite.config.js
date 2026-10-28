import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

/** 本地开发时后端地址，可用环境变量覆盖：
 *    VITE_API_TARGET=http://149.28.133.245 npm run dev
 * 这样就能用本地热更新直接连线上 API，不用等 CI 部署。
 */
const API_TARGET = process.env.VITE_API_TARGET || 'http://localhost:8080'

export default defineConfig({
  // 生产环境挂在 https://IP/admin/ 下，dev 时也用这个 base（所以本地地址是 http://localhost:5174/admin/）
  base: '/admin/',
  plugins: [vue()],
  server: {
    port: 5174,
    proxy: {
      '/api': { target: API_TARGET, changeOrigin: true }
    }
  },
  build: { outDir: 'dist' }
})
