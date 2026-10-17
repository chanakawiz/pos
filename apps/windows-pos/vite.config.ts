import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  base: './',
  plugins: [
    react(),
    tailwindcss(),
    {
      name: 'customer-display-dev-csp',
      apply: 'serve',
      // React's development preamble and Vite HMR need these allowances only in development.
      transformIndexHtml: (html) => html
        .replace("script-src 'self';", "script-src 'self' 'unsafe-inline';")
        .replace("connect-src 'none';", "connect-src 'self' ws:;"),
    },
  ],
  build: {
    rollupOptions: {
      input: { cashier: 'index.html', customer: 'customer-display.html' },
    },
  },
  server: {
    port: 5173,
    host: true,
  },
})
