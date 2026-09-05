import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    tailwindcss(),
  ],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        login: resolve(__dirname, 'login.html'),
        register: resolve(__dirname, 'register.html'),
        map: resolve(__dirname, 'map.html'),
        // analytics: resolve(__dirname, 'analytics.html'),
        // citizenDashboard: resolve(__dirname, 'citizen/dashboard.html'),
        // citizenRegister: resolve(__dirname, 'citizen/register-complaint.html'),
        // govDashboard: resolve(__dirname, 'gov/dashboard.html'),
      }
    }
  }
})
