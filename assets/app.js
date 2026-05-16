/* Stock Report Repository — main app */
(function () {
  const grid = document.getElementById('reportGrid');
  const empty = document.getElementById('empty');
  const filters = document.getElementById('filters');
  const search = document.getElementById('search');

  let reports = [];
  let activeCat = 'all';
  let query = '';

  async function loadReports() {
    try {
      const res = await fetch('data/reports.json', { cache: 'no-store' });
      const json = await res.json();
      reports = (json.reports || []).slice().sort((a, b) => (b.date || '').localeCompare(a.date || ''));
      render();
    } catch (e) {
      console.error('Failed to load reports.json', e);
      grid.innerHTML = '';
      empty.hidden = false;
      empty.innerHTML = '<p>보고서 목록을 불러올 수 없습니다. data/reports.json 파일을 확인해주세요.</p>';
    }
  }

  function escapeHtml(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  function matches(r) {
    if (activeCat !== 'all' && r.category !== activeCat) return false;
    if (!query) return true;
    const q = query.toLowerCase();
    const hay = [
      r.title, r.summary, r.category,
      (r.tags || []).join(' ')
    ].join(' ').toLowerCase();
    return hay.includes(q);
  }

  function todayStr() {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  function cardHtml(r) {
    const tags = (r.tags || []).slice(0, 5).map(t =>
      `<span class="card-tag">#${escapeHtml(t)}</span>`).join('');
    const isNew = r.date === todayStr();
    const cls = isNew ? 'card is-new' : 'card';
    const badge = isNew ? '<span class="new-badge">NEW</span>' : '';
    return `
      <article class="${cls}" data-href="${escapeHtml(r.path)}">
        ${badge}
        <div class="card-meta">
          <span class="card-cat">${escapeHtml(r.category || '기타')}</span>
          <span class="card-date">${escapeHtml(r.date || '')}</span>
        </div>
        <h3 class="card-title">${escapeHtml(r.title || '제목 없음')}</h3>
        <p class="card-summary">${escapeHtml(r.summary || '')}</p>
        ${tags ? `<div class="card-tags">${tags}</div>` : ''}
      </article>`;
  }

  function render() {
    const filtered = reports.filter(matches);
    if (filtered.length === 0) {
      grid.innerHTML = '';
      empty.hidden = false;
      return;
    }
    empty.hidden = true;
    grid.innerHTML = filtered.map(cardHtml).join('');
  }

  filters.addEventListener('click', (e) => {
    const btn = e.target.closest('.chip');
    if (!btn) return;
    filters.querySelectorAll('.chip').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    activeCat = btn.dataset.cat;
    render();
  });

  search.addEventListener('input', (e) => {
    query = e.target.value.trim();
    render();
  });

  grid.addEventListener('click', (e) => {
    const card = e.target.closest('.card');
    if (!card) return;
    const href = card.dataset.href;
    if (href) window.location.href = href;
  });

  loadReports();
})();
