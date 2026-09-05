(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e={StatusBadge:e=>`<span class="badge ${{open:`badge-critical`,critical:`badge-critical`,"in progress":`badge-medium`,high:`badge-high`,medium:`badge-medium`,resolved:`badge-resolved`,low:`badge-resolved`,draft:`badge-neutral`}[e?.toLowerCase()]||`badge-neutral`} capitalize">${e||`Unknown`}</span>`,PriorityScore:e=>{let t=`text-status-neutral`;return t=e>=80?`text-status-critical`:e>=60?`text-status-high`:e>=40?`text-status-medium`:`text-status-resolved`,`<div class="flex items-center gap-1 font-bold ${t}">
            <span class="material-symbols-outlined text-sm">local_fire_department</span>
            <span>${e}/100</span>
        </div>`},KPICard:(e,t,n,r)=>`
            <div class="card flex items-center justify-between">
                <div>
                    <h3 class="text-sm font-medium text-slate-500">${e}</h3>
                    <div class="text-2xl font-bold text-navy mt-1">${t}</div>
                    ${n?`<div class="text-sm ${n.startsWith(`+`)?`text-status-resolved`:`text-status-critical`}">${n}</div>`:``}
                </div>
                <div class="p-3 bg-surface rounded-lg text-action">
                    <span class="material-symbols-outlined">${r}</span>
                </div>
            </div>
        `,IssueCard:t=>{let n={Critical:`bg-status-critical`,High:`bg-status-high`,Medium:`bg-status-medium`,Low:`bg-status-resolved`}[t.priority]||`bg-status-neutral`;return`
            <a href="track.html?id=${t.rawId}" class="card-interactive block relative overflow-hidden flex flex-col gap-3 transition-transform hover:-translate-y-1">
                <div class="absolute left-0 top-0 bottom-0 w-1.5 ${n}"></div>
                <div class="flex justify-between items-start pl-2">
                    <div>
                        <span class="text-xs font-semibold text-slate-500">${t.id||`NEW`}</span>
                        <h4 class="font-bold text-navy text-lg line-clamp-1">${t.categoryId||`General Issue`}</h4>
                    </div>
                    ${e.StatusBadge(t.status||`open`)}
                </div>
                <p class="text-sm text-slate-600 line-clamp-2 pl-2">${t.description||``}</p>
                <div class="flex justify-between items-center mt-2 pl-2">
                    <div class="text-xs text-slate-500 flex items-center gap-1">
                        <span class="material-symbols-outlined text-[14px]">calendar_today</span>
                        ${new Date(t.dateReported||new Date).toLocaleDateString()}
                    </div>
                    ${t.severityScore?e.PriorityScore(t.severityScore):``}
                </div>
            </a>
        `},CitizenNavbar:(e=``)=>`
            <nav class="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-surface-border">
                <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div class="flex justify-between h-16">
                        <div class="flex items-center gap-8">
                            <a href="/" class="flex items-center gap-2">
                                <span class="material-symbols-outlined text-action text-3xl">account_balance</span>
                                <span class="font-bold text-xl text-navy">CivicAI</span>
                            </a>
                            <div class="hidden md:flex items-center gap-4">
                                <a href="/citizen/dashboard.html" class="px-3 py-2 text-sm font-medium rounded-md ${e===`dashboard`?`bg-surface text-action`:`text-navy hover:bg-surface`}">Dashboard</a>
                                <a href="/map.html" class="px-3 py-2 text-sm font-medium rounded-md ${e===`map`?`bg-surface text-action`:`text-navy hover:bg-surface`}">Live Map</a>
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
        `,GovernmentSidebar:(e=``)=>`
            <aside class="w-64 h-full bg-white border-r border-surface-border flex flex-col z-40">
                <div class="h-16 flex items-center px-6 border-b border-surface-border">
                    <span class="material-symbols-outlined text-action text-2xl mr-2">account_balance</span>
                    <span class="font-bold text-lg text-navy">CivicAI Gov</span>
                </div>
                <nav class="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
                    ${[{id:`dashboard`,icon:`dashboard`,label:`Command Center`,href:`/gov/dashboard.html`},{id:`queue`,icon:`list_alt`,label:`Priority Queue`,href:`/gov/priority-queue.html`},{id:`map`,icon:`public`,label:`Live Issues`,href:`/map.html`},{id:`departments`,icon:`domain`,label:`Departments`,href:`/gov/departments.html`},{id:`analytics`,icon:`analytics`,label:`Analytics`,href:`/analytics.html`},{id:`profile`,icon:`person`,label:`Profile`,href:`/profile.html`}].map(t=>`
            <a href="${t.href}" class="flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${e===t.id?`bg-action/10 text-action font-semibold`:`text-slate-600 hover:bg-surface hover:text-navy`}">
                <span class="material-symbols-outlined">${t.icon}</span>
                <span>${t.label}</span>
            </a>
        `).join(``)}
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
        `,EmptyState:(e,t,n=`inbox`)=>`
            <div class="flex flex-col items-center justify-center p-12 text-center bg-surface border border-dashed border-surface-border rounded-lg">
                <div class="h-16 w-16 bg-white rounded-full flex items-center justify-center shadow-sm mb-4">
                    <span class="material-symbols-outlined text-3xl text-slate-400">${n}</span>
                </div>
                <h3 class="text-lg font-semibold text-navy mb-1">${e}</h3>
                <p class="text-sm text-slate-500 max-w-sm">${t}</p>
            </div>
        `,LoadingState:(e=`Loading...`)=>`
            <div class="flex flex-col items-center justify-center p-12 text-center">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-action mb-4 inline-block"></div>
                <p class="text-sm text-slate-500">${e}</p>
            </div>
        `};window.Components=e;var t=document.getElementById(`theme-toggle`),n=document.getElementById(`theme-toggle-dark-icon`),r=document.getElementById(`theme-toggle-light-icon`);t&&n&&r&&(localStorage.getItem(`color-theme`)===`dark`||!(`color-theme`in localStorage)&&window.matchMedia(`(prefers-color-scheme: dark)`).matches?(r.classList.remove(`hidden`),document.documentElement.classList.add(`dark`)):(n.classList.remove(`hidden`),document.documentElement.classList.remove(`dark`)),t.addEventListener(`click`,function(){n.classList.toggle(`hidden`),r.classList.toggle(`hidden`),localStorage.getItem(`color-theme`)?localStorage.getItem(`color-theme`)===`light`?(document.documentElement.classList.add(`dark`),localStorage.setItem(`color-theme`,`dark`)):(document.documentElement.classList.remove(`dark`),localStorage.setItem(`color-theme`,`light`)):document.documentElement.classList.contains(`dark`)?(document.documentElement.classList.remove(`dark`),localStorage.setItem(`color-theme`,`light`)):(document.documentElement.classList.add(`dark`),localStorage.setItem(`color-theme`,`dark`))})),window.showToast=function(e,t=`success`){let n=document.getElementById(`toast-container`);n||(n=document.createElement(`div`),n.id=`toast-container`,n.className=`fixed bottom-4 right-4 z-[9999] flex flex-col gap-2`,document.body.appendChild(n));let r=document.createElement(`div`);r.className=`transform transition-all duration-300 translate-y-full opacity-0 ${t===`success`?`bg-status-resolved`:t===`error`?`bg-status-critical`:`bg-navy`} text-white px-4 py-3 rounded-lg shadow-modal flex items-center gap-2 border border-white/10`,r.innerHTML=`<span class="material-symbols-outlined text-lg">${t===`success`?`check_circle`:t===`error`?`error`:`info`}</span> <span class="text-sm font-medium">${e}</span>`,n.appendChild(r),setTimeout(()=>{r.classList.remove(`translate-y-full`,`opacity-0`)},10),setTimeout(()=>{r.classList.add(`translate-y-full`,`opacity-0`),setTimeout(()=>r.remove(),300)},3e3)};