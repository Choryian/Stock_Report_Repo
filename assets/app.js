/* Stock Report Repository — main app */
(function () {
  const grid = document.getElementById('reportGrid');
  const empty = document.getElementById('empty');
  const filters = document.getElementById('filters');
  const search = document.getElementById('search');
  const briefList = document.getElementById('briefList');
  const briefEmpty = document.getElementById('briefEmpty');
  const briefCount = document.getElementById('briefCount');

  // 우측 사이드바로 분리되는 카테고리(시황)와, 별도 페이지가 있어 메인에서 제외할 카테고리(와인)
  const SIDE_CAT = '시황';
  const EXCLUDE_FROM_MAIN = ['와인'];

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

  function matchesQuery(r) {
    if (!query) return true;
    const q = query.toLowerCase();
    const hay = [
      r.title, r.summary, r.category,
      (r.tags || []).join(' ')
    ].join(' ').toLowerCase();
    return hay.includes(q);
  }

  // 메인 그리드용: 시황·와인 제외 + 카테고리/검색 필터
  function matchesMain(r) {
    if (r.category === SIDE_CAT) return false;
    if (EXCLUDE_FROM_MAIN.includes(r.category)) return false;
    if (activeCat !== 'all' && r.category !== activeCat) return false;
    return matchesQuery(r);
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

  function briefItemHtml(r) {
    const isNew = r.date === todayStr();
    const badge = isNew ? '<span class="brief-new">NEW</span>' : '';
    return `
      <a class="brief-item" href="${escapeHtml(r.path)}">
        <div class="brief-date">${escapeHtml(r.date || '')}${badge}</div>
        <div class="brief-title">${escapeHtml(r.title || '제목 없음')}</div>
      </a>`;
  }

  function renderMain() {
    const filtered = reports.filter(matchesMain);
    if (filtered.length === 0) {
      grid.innerHTML = '';
      empty.hidden = false;
      return;
    }
    empty.hidden = true;
    grid.innerHTML = filtered.map(cardHtml).join('');
  }

  function renderBrief() {
    // 시황은 검색어에는 반응하지만 좌측 카테고리 필터에는 영향받지 않음
    const briefs = reports.filter(r => r.category === SIDE_CAT && matchesQuery(r));
    briefCount.textContent = briefs.length ? `${briefs.length}건` : '';
    if (briefs.length === 0) {
      briefList.innerHTML = '';
      briefEmpty.hidden = false;
      return;
    }
    briefEmpty.hidden = true;
    briefList.innerHTML = briefs.map(briefItemHtml).join('');
  }

  function render() {
    renderMain();
    renderBrief();
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
