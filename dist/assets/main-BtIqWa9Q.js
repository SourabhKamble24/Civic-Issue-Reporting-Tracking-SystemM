import"./main-XBK2x3LN.js";(async function(){let e=document.getElementById(`landing-stats`);try{let t=await fetch(`http://localhost:5000/api/complaints`);if(!t.ok)throw Error(`API Error`);let n=await t.json(),r=n.length,i=n.filter(e=>e.status===`resolved`||e.status===`Resolved`).length;e.innerHTML=`
          <div class="card text-center">
            <div class="text-sm font-medium text-slate-500 uppercase tracking-wider mb-2">Total Reports</div>
            <div class="text-4xl font-bold text-navy">${r}</div>
          </div>
          <div class="card text-center">
            <div class="text-sm font-medium text-slate-500 uppercase tracking-wider mb-2">Resolved</div>
            <div class="text-4xl font-bold text-status-resolved">${i}</div>
          </div>
          <div class="card text-center">
            <div class="text-sm font-medium text-slate-500 uppercase tracking-wider mb-2">Active Issues</div>
            <div class="text-4xl font-bold text-status-medium">${n.filter(e=>e.status!==`resolved`&&e.status!==`Resolved`).length}</div>
          </div>
          <div class="card text-center">
            <div class="text-sm font-medium text-slate-500 uppercase tracking-wider mb-2">Response Rate</div>
            <div class="text-4xl font-bold text-action">${r>0?Math.round(i/r*100):100}%</div>
          </div>
        `}catch(e){console.log(`Using fallback statistics`,e)}})();