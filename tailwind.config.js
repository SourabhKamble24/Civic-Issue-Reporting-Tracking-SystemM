/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./login.html",
    "./register.html",
    "./map.html",
    "./analytics.html",
    "./citizen/**/*.html",
    "./gov/**/*.html",
    "./admin/**/*.html",
    "./src/**/*.{js,ts,jsx,tsx,html}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Core Brand
        navy: {
          DEFAULT: '#1A2B47',
          dark: '#031631',
          light: '#2C4368'
        },
        action: {
          DEFAULT: '#2563EB',
          hover: '#1D4ED8'
        },
        // Original Status
        status: {
          critical: '#EF4444',
          high: '#F97316',
          medium: '#EAB308',
          resolved: '#22C55E',
          neutral: '#64748B'
        },
        // MD3 Stitch Theme
        "primary-fixed-dim": "#b6c7ea",
        "surface-tint": "#4e5f7d",
        "on-secondary-fixed-variant": "#003ea8",
        "on-tertiary": "#ffffff",
        "outline-variant": "#c5c6ce",
        "on-primary-fixed": "#081b37",
        "tertiary": "#131718",
        "background": "#f8f9ff",
        "error": "#ba1a1a",
        "on-primary-container": "#8293b4",
        "inverse-surface": "#213145",
        "primary-container": "#1a2b47",
        "primary": "#031631",
        "on-secondary-fixed": "#00174b",
        "tertiary-fixed": "#e0e3e5",
        "error-container": "#ffdad6",
        "secondary-container": "#316bf3",
        "surface-variant": "#d3e4fe",
        "surface-container-high": "#dce9ff",
        "inverse-primary": "#b6c7ea",
        "on-secondary-container": "#fefcff",
        "on-primary-fixed-variant": "#374765",
        "surface-container-lowest": "#ffffff",
        "outline": "#75777e",
        "tertiary-fixed-dim": "#c4c7c9",
        "on-surface-variant": "#44474d",
        surface: {
          DEFAULT: "#f8f9ff",
          border: "#E2E8F0",
          dark: "#1E293B",
          darkBorder: "#334155"
        },
        "on-primary": "#ffffff",
        "surface-container-highest": "#d3e4fe",
        "tertiary-container": "#282b2d",
        "surface-container": "#e5eeff",
        "on-background": "#0b1c30",
        "surface-container-low": "#eff4ff",
        "on-error": "#ffffff",
        "secondary": "#0051d5",
        "primary-fixed": "#d6e3ff",
        "on-secondary": "#ffffff",
        "on-error-container": "#93000a",
        "on-tertiary-fixed-variant": "#444749",
        "secondary-fixed-dim": "#b4c5ff",
        "inverse-on-surface": "#eaf1ff",
        "on-surface": "#0b1c30",
        "secondary-fixed": "#dbe1ff",
        "on-tertiary-fixed": "#191c1e",
        "on-tertiary-container": "#8f9294",
        "surface-bright": "#f8f9ff",
        "surface-dim": "#cbdbf5"
      },
      spacing: {
        "lg": "24px",
        "xs": "4px",
        "container-max": "1200px",
        "unit": "4px",
        "sm": "8px",
        "margin-mobile": "16px",
        "xl": "32px",
        "md": "16px",
        "gutter": "24px"
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        "headline-lg-mobile": ["Inter"],
        "body-md": ["Inter"],
        "display-lg": ["Inter"],
        "label-sm": ["Inter"],
        "headline-lg": ["Inter"],
        "label-md": ["Inter"],
        "body-lg": ["Inter"],
        "headline-md": ["Inter"]
      },
      fontSize: {
        "headline-lg-mobile": ["24px", { "lineHeight": "32px", "fontWeight": "600" }],
        "body-md": ["16px", { "lineHeight": "24px", "fontWeight": "400" }],
        "display-lg": ["48px", { "lineHeight": "56px", "letterSpacing": "-0.02em", "fontWeight": "700" }],
        "label-sm": ["12px", { "lineHeight": "16px", "fontWeight": "600" }],
        "headline-lg": ["32px", { "lineHeight": "40px", "letterSpacing": "-0.01em", "fontWeight": "600" }],
        "label-md": ["14px", { "lineHeight": "20px", "letterSpacing": "0.01em", "fontWeight": "500" }],
        "body-lg": ["18px", { "lineHeight": "28px", "fontWeight": "400" }],
        "headline-md": ["24px", { "lineHeight": "32px", "fontWeight": "600" }]
      },
      boxShadow: {
        'card': '0px 4px 20px rgba(26, 43, 71, 0.08)',
        'modal': '0px 10px 30px rgba(26, 43, 71, 0.12)',
      },
      borderRadius: {
        'base': '12px',
        'lg': '16px',
        'pill': '999px'
      }
    },
  },
  plugins: [],
}
