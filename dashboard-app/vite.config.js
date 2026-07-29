import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [react()],
    server: {
      port: 3000,
      proxy: {
        // All /proxy/* calls are forwarded to Databricks server-side (no CORS)
        '/proxy': {
          target:      env.VITE_DATABRICKS_HOST,
          changeOrigin: true,
          rewrite:     path => path.replace(/^\/proxy/, ''),
        }
      }
    }
  }
})
