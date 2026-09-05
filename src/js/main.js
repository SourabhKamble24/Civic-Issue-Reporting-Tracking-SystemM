import { Components } from './components.js';

// Attach components globally for vanilla HTML usage
window.Components = Components;

// Theme Toggle Logic
const themeToggleBtn = document.getElementById('theme-toggle');
const darkIcon = document.getElementById('theme-toggle-dark-icon');
const lightIcon = document.getElementById('theme-toggle-light-icon');

if (themeToggleBtn && darkIcon && lightIcon) {
  // Change the icons inside the button based on previous settings
  if (localStorage.getItem('color-theme') === 'dark' || (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    lightIcon.classList.remove('hidden');
    document.documentElement.classList.add('dark');
  } else {
    darkIcon.classList.remove('hidden');
    document.documentElement.classList.remove('dark');
  }

  themeToggleBtn.addEventListener('click', function() {
    // toggle icons
    darkIcon.classList.toggle('hidden');
    lightIcon.classList.toggle('hidden');

    // if set via local storage previously
    if (localStorage.getItem('color-theme')) {
      if (localStorage.getItem('color-theme') === 'light') {
        document.documentElement.classList.add('dark');
        localStorage.setItem('color-theme', 'dark');
      } else {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('color-theme', 'light');
      }
    } else {
      // if NOT set via local storage previously
      if (document.documentElement.classList.contains('dark')) {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('color-theme', 'light');
      } else {
        document.documentElement.classList.add('dark');
        localStorage.setItem('color-theme', 'dark');
      }
    }
  });
}

// Global Toast Notification System
window.showToast = function(message, type = 'success') {
  // Create toast container if it doesn't exist
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'fixed bottom-4 right-4 z-[9999] flex flex-col gap-2';
    document.body.appendChild(container);
  }

  // Create toast element
  const toast = document.createElement('div');
  const bgColor = type === 'success' ? 'bg-status-resolved' : type === 'error' ? 'bg-status-critical' : 'bg-navy';
  toast.className = `transform transition-all duration-300 translate-y-full opacity-0 ${bgColor} text-white px-4 py-3 rounded-lg shadow-modal flex items-center gap-2 border border-white/10`;
  
  const icon = type === 'success' ? 'check_circle' : type === 'error' ? 'error' : 'info';
  toast.innerHTML = `<span class="material-symbols-outlined text-lg">${icon}</span> <span class="text-sm font-medium">${message}</span>`;
  
  container.appendChild(toast);

  // Animate in
  setTimeout(() => {
    toast.classList.remove('translate-y-full', 'opacity-0');
  }, 10);

  // Remove after 3 seconds
  setTimeout(() => {
    toast.classList.add('translate-y-full', 'opacity-0');
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// User Menu Dropdown Logic
document.addEventListener('DOMContentLoaded', () => {
    const attachMenuLogic = (btnId) => {
        const btn = document.getElementById(btnId);
        const dropdown = document.getElementById('user-menu-dropdown');
        if (btn && dropdown) {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                dropdown.classList.toggle('hidden');
            });
            document.addEventListener('click', (e) => {
                if (!btn.contains(e.target) && !dropdown.contains(e.target)) {
                    dropdown.classList.add('hidden');
                }
            });
        }
    };
    attachMenuLogic('user-menu-button');
    attachMenuLogic('user-menu-button-top');
});;
