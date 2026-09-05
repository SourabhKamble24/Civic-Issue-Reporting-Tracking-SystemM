/**
 * CivicAI Shared Design System Components
 * Implements Vanilla JS / HTML templates based on Stitch DESIGN.md
 */

export const Components = {
    // ==========================================
    // BADGES & INDICATORS
    // ==========================================
    
    StatusBadge: (status) => {
        const statusMap = {
            'open': 'badge-critical',
            'critical': 'badge-critical',
            'in progress': 'badge-medium',
            'high': 'badge-high',
            'medium': 'badge-medium',
            'resolved': 'badge-resolved',
            'low': 'badge-resolved',
            'draft': 'badge-neutral'
        };
        const badgeClass = statusMap[status?.toLowerCase()] || 'badge-neutral';
        return `<span class="badge ${badgeClass} capitalize">${status || 'Unknown'}</span>`;
    },

    PriorityScore: (score) => {
        let colorClass = 'text-status-neutral';
        if (score >= 80) colorClass = 'text-status-critical';
        else if (score >= 60) colorClass = 'text-status-high';
        else if (score >= 40) colorClass = 'text-status-medium';
        else colorClass = 'text-status-resolved';
        
        return `<div class="flex items-center gap-1 font-bold ${colorClass}">
            <span class="material-symbols-outlined text-sm">local_fire_department</span>
            <span>${score}/100</span>
        </div>`;
    },

    // ==========================================
    // CARDS & CONTAINERS
    // ==========================================
    
    KPICard: (title, value, trend, icon) => {
        const trendHTML = trend ? `<div class="text-sm ${trend.startsWith('+') ? 'text-status-resolved' : 'text-status-critical'}">${trend}</div>` : '';
        return `
            <div class="card flex items-center justify-between">
                <div>
                    <h3 class="text-sm font-medium text-slate-500">${title}</h3>
                    <div class="text-2xl font-bold text-navy mt-1">${value}</div>
                    ${trendHTML}
                </div>
                <div class="p-3 bg-surface rounded-lg text-action">
                    <span class="material-symbols-outlined">${icon}</span>
                </div>
            </div>
        `;
    },

    IssueCard: (issue) => {
        // Vertical accent bar color based on status/priority
        const priorityColorMap = {
            'Critical': 'bg-status-critical',
            'High': 'bg-status-high',
            'Medium': 'bg-status-medium',
            'Low': 'bg-status-resolved'
        };
        const accentColor = priorityColorMap[issue.priority] || 'bg-status-neutral';

        return `
            <a href="track.html?id=${issue.rawId}" class="card-interactive block relative overflow-hidden flex flex-col gap-3 transition-transform hover:-translate-y-1">
                <div class="absolute left-0 top-0 bottom-0 w-1.5 ${accentColor}"></div>
                <div class="flex justify-between items-start pl-2">
                    <div>
                        <span class="text-xs font-semibold text-slate-500">${issue.id || 'NEW'}</span>
                        <h4 class="font-bold text-navy text-lg line-clamp-1">${issue.categoryId || 'General Issue'}</h4>
                    </div>
                    ${Components.StatusBadge(issue.status || 'open')}
                </div>
                <p class="text-sm text-slate-600 line-clamp-2 pl-2">${issue.description || ''}</p>
                <div class="flex justify-between items-center mt-2 pl-2">
                    <div class="text-xs text-slate-500 flex items-center gap-1">
                        <span class="material-symbols-outlined text-[14px]">calendar_today</span>
                        ${new Date(issue.dateReported || new Date()).toLocaleDateString()}
                    </div>
                    ${issue.severityScore ? Components.PriorityScore(issue.severityScore) : ''}
                </div>
            </a>
        `;
    },

    // ==========================================
    // NAVIGATION
    // ==========================================
    
    CitizenNavbar: (activeRoute = '') => {
        return `
            <nav class="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-surface-border">
                <div class="w-full mx-auto px-4 sm:px-6 lg:px-8">
                    <div class="flex justify-between h-16">
                        <div class="flex items-center gap-8">
                            <a href="/" class="flex items-center gap-2">
                                <img src="/logo.png" alt="CivicAI Logo" class="w-10 h-10 rounded-full object-cover shadow-sm bg-white">
                                <span class="font-bold text-xl text-navy">CivicAI</span>
                            </a>
                            <div class="hidden md:flex items-center gap-4">
                                <a href="/citizen/dashboard.html" class="px-3 py-2 text-sm font-medium rounded-md ${activeRoute === 'dashboard' ? 'bg-surface text-action' : 'text-navy hover:bg-surface'}">Dashboard</a>
                                <a href="/map.html" class="px-3 py-2 text-sm font-medium rounded-md ${activeRoute === 'map' ? 'bg-surface text-action' : 'text-navy hover:bg-surface'}">Live Map</a>
                            </div>
                        </div>
                        <div class="flex items-center gap-4">
                            <a href="/citizen/register-complaint.html" class="btn-primary py-2 px-4 text-sm">
                                <span class="material-symbols-outlined text-[18px] mr-1">add</span>
                                Report Issue
                            </a>
                            <a href="/profile.html" class="h-8 w-8 rounded-full bg-navy text-white flex items-center justify-center font-bold shadow-sm hover:ring-2 ring-action transition-all" title="Profile">
                                U
                            </a>
                            <button id="logout-btn" class="text-slate-500 hover:text-action transition-colors">
                                <span class="material-symbols-outlined text-[20px]">logout</span>
                            </button>
                        </div>
                    </div>
                </div>
            </nav>
        `;
    },

    GovernmentSidebar: (activeRoute = '') => {
        const navItems = [
            { id: 'dashboard', icon: 'dashboard', label: 'Command Center', href: '/gov/dashboard.html' },
            { id: 'queue', icon: 'list_alt', label: 'Priority Queue', href: '/gov/priority-queue.html' },
            { id: 'map', icon: 'public', label: 'Live Issues', href: '/map.html' },
            { id: 'departments', icon: 'domain', label: 'Departments', href: '/gov/departments.html' },
            { id: 'analytics', icon: 'analytics', label: 'Analytics', href: '/analytics.html' },
            { id: 'profile', icon: 'person', label: 'Profile', href: '/profile.html' }
        ];

        let navHTML = navItems.map(item => `
            <a href="${item.href}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${activeRoute === item.id ? 'bg-action/10 text-action font-semibold' : 'text-slate-600 hover:bg-surface hover:text-navy'}">
                <span class="material-symbols-outlined">${item.icon}</span>
                <span>${item.label}</span>
            </a>
        `).join('');

        return `
            <aside class="w-64 h-full bg-white border-r border-surface-border flex flex-col z-40">
                <div class="h-16 flex items-center px-6 border-b border-surface-border">
                    <span class="material-symbols-outlined text-action text-2xl mr-2">account_balance</span>
                    <span class="font-bold text-lg text-navy">CivicAI Gov</span>
                </div>
                <nav class="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
                    ${navHTML}
                </nav>
                <div class="p-4 border-t border-surface-border">
                    <div class="flex items-center gap-3">
                        <div class="h-10 w-10 rounded-full bg-navy text-white flex items-center justify-center font-bold">G</div>
                        <div>
                            <div class="text-sm font-medium text-navy">Gov Official</div>
                            <div onclick="localStorage.clear(); window.location.href='/login.html';" class="text-xs text-slate-500 cursor-pointer hover:text-action">Sign out</div>
                        </div>
                    </div>
                </div>
            </aside>
        `;
    },

    // ==========================================
    // STATES & FEEDBACK
    // ==========================================
    
    EmptyState: (title, message, icon = 'inbox') => {
        return `
            <div class="flex flex-col items-center justify-center p-12 text-center bg-surface border border-dashed border-surface-border rounded-lg">
                <div class="h-16 w-16 bg-white rounded-full flex items-center justify-center shadow-sm mb-4">
                    <span class="material-symbols-outlined text-3xl text-slate-400">${icon}</span>
                </div>
                <h3 class="text-lg font-semibold text-navy mb-1">${title}</h3>
                <p class="text-sm text-slate-500 max-w-sm">${message}</p>
            </div>
        `;
    },
    
    LoadingState: (message = 'Loading...') => {
        return `
            <div class="flex flex-col items-center justify-center p-12 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-action mb-4 inline-block"></div>
                <p class="text-sm text-slate-500">${message}</p>
            </div>
        `;
    }
};
