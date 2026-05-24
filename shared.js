// ============================================================
// Dutch Agency Portal — Gedeelde configuratie
// ============================================================

const SUPABASE_URL = 'https://agurvyolmndhefsafboi.supabase.co'
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFndXJ2eW9sbW5kaGVmc2FmYm9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MzQ1MzQsImV4cCI6MjA5NTIxMDUzNH0.ZS-btW-HhMj7E8fd-IjeRTkmD20Di2AAnzm1-UNhP24'

const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY)

const NAV_LINKS = [
  { href: 'dashboard.html', label: 'Dashboard',   id: 'dashboard',   icon: '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>' },
  { href: 'labels.html',    label: 'Labels',       id: 'labels',      icon: '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A2 2 0 013 12V7a4 4 0 014-4z"/></svg>' },
  { href: 'artists.html',   label: 'Artiesten',    id: 'artists',     icon: '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3"/></svg>' },
  { href: 'statements.html',label: 'Statements',   id: 'statements',  icon: '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>' },
]

// Controleer auth + render nav. Geeft session terug of null.
async function initPage(activePage) {
  const { data: { session } } = await db.auth.getSession()
  if (!session) {
    window.location.href = 'index.html'
    return null
  }
  renderNav(activePage, session.user.email)
  return session
}

function renderNav(activePage, email) {
  const el = document.getElementById('sidebar')
  if (!el) return
  el.innerHTML = `
    <div class="flex flex-col h-full">
      <div class="p-5 border-b border-[#2a2a2a]">
        <div class="text-[#E8920A] font-bold text-base tracking-widest uppercase">Dutch Agency</div>
        <div class="text-gray-600 text-xs mt-0.5">Rob Boskamp BV</div>
      </div>
      <nav class="flex-1 p-3 space-y-0.5 overflow-y-auto">
        ${NAV_LINKS.map(l => `
          <a href="${l.href}" class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm transition-all ${
            activePage === l.id
              ? 'bg-[#E8920A]/15 text-[#E8920A] font-medium'
              : 'text-gray-500 hover:text-white hover:bg-[#2a2a2a]'
          }">
            ${l.icon}
            <span>${l.label}</span>
          </a>
        `).join('')}
      </nav>
      <div class="p-4 border-t border-[#2a2a2a]">
        <div class="text-gray-600 text-xs truncate mb-3 px-1">${email}</div>
        <button onclick="logout()"
          class="w-full flex items-center gap-2 px-3 py-2 text-gray-500 hover:text-white hover:bg-[#2a2a2a] rounded-lg text-sm transition-all">
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
          </svg>
          Uitloggen
        </button>
      </div>
    </div>
  `
}

async function logout() {
  await db.auth.signOut()
  window.location.href = 'index.html'
}

// Formatteer bedrag als EUR
function fmt(amount) {
  if (amount == null || amount === '') return '—'
  return new Intl.NumberFormat('nl-NL', { style: 'currency', currency: 'EUR' }).format(amount)
}

// Formatteer datum
function fmtDate(dateStr) {
  if (!dateStr) return '—'
  return new Date(dateStr).toLocaleDateString('nl-NL', { day: '2-digit', month: 'short', year: 'numeric' })
}

// Toast-melding rechtsonder
function showToast(msg, type = 'success') {
  const t = document.createElement('div')
  t.className = `fixed bottom-5 right-5 px-5 py-3 rounded-xl text-sm font-medium shadow-xl z-50 transition-all ${
    type === 'success' ? 'bg-[#E8920A] text-white' : 'bg-red-600 text-white'
  }`
  t.textContent = msg
  document.body.appendChild(t)
  setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 300) }, 2700)
}

// Toon/verberg laad-indicator in element
function setLoading(el, loading) {
  if (!el) return
  if (loading) {
    el.dataset.orig = el.innerHTML
    el.innerHTML = '<div class="text-gray-500 text-sm py-4 text-center">Laden...</div>'
  } else if (el.dataset.orig) {
    el.innerHTML = el.dataset.orig
  }
}
