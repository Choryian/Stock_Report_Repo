/* Chory & Rochet — 개별 보고서 상단 공통 헤더 바
 * 각 보고서 HTML에 <script defer src="../assets/report-header.js"></script> 한 줄만 추가하면
 * 홈페이지와 동일한 상단 바가 보고서 최상단에 삽입된다.
 * 보고서별 고유 CSS와 충돌하지 않도록 모든 클래스를 cr- 로 네임스페이스. */
(function () {
  if (document.getElementById('cr-site-header')) return; // 중복 삽입 방지

  // 보고서는 reports/ 또는 wine/ 안에 있으므로 사이트 루트는 한 단계 위
  var ROOT = '../';

  var css = '' +
    '#cr-site-header{position:sticky;top:0;z-index:9999;background:#fff;' +
    'border-bottom:1px solid #e6e6e6;font-family:"Pretendard",-apple-system,BlinkMacSystemFont,system-ui,"Noto Sans KR",sans-serif;' +
    '-webkit-font-smoothing:antialiased;}' +
    '#cr-site-header *{box-sizing:border-box;}' +
    '.cr-header-inner{max-width:1180px;margin:0 auto;padding:14px 24px;display:flex;align-items:center;justify-content:space-between;gap:16px;}' +
    '.cr-brand{display:flex;align-items:center;gap:12px;text-decoration:none;}' +
    '.cr-brand-mark{width:38px;height:38px;border-radius:6px;background:#1e3a5f;color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;letter-spacing:.5px;flex:0 0 auto;}' +
    '.cr-brand-title{font-weight:700;font-size:16px;letter-spacing:-.2px;color:#111;line-height:1.2;}' +
    '.cr-brand-sub{font-size:11px;color:#6b6b6b;letter-spacing:.3px;}' +
    '.cr-nav{display:flex;gap:4px;align-items:center;}' +
    '.cr-nav a{padding:8px 14px;border-radius:4px;color:#6b6b6b;font-weight:500;font-size:14px;text-decoration:none;white-space:nowrap;}' +
    '.cr-nav a:hover{background:#f3f3f3;color:#111;}' +
    '.cr-nav a.cr-active{background:#eaf0f7;color:#1e3a5f;}' +
    '@media (max-width:640px){.cr-header-inner{padding:10px 14px;flex-wrap:wrap;gap:8px;}.cr-brand-sub{display:none;}.cr-brand-mark{width:32px;height:32px;font-size:12px;}.cr-brand-title{font-size:15px;}.cr-nav{width:100%;overflow-x:auto;-webkit-overflow-scrolling:touch;gap:2px;}.cr-nav a{padding:6px 9px;font-size:12px;}}';

  var style = document.createElement('style');
  style.textContent = css;
  document.head.appendChild(style);

  var header = document.createElement('header');
  header.id = 'cr-site-header';
  header.innerHTML = '' +
    '<div class="cr-header-inner">' +
      '<a class="cr-brand" href="' + ROOT + '">' +
        '<div class="cr-brand-mark">C&amp;R</div>' +
        '<div>' +
          '<div class="cr-brand-title">Stock Report Repository</div>' +
          '<div class="cr-brand-sub">Chory &amp; Rochet · Research Archive</div>' +
        '</div>' +
      '</a>' +
      '<nav class="cr-nav">' +
        '<a href="' + ROOT + 'roadmap/">한국증시 로드맵</a>' +
        '<a href="' + ROOT + '">Reports</a>' +
        '<a href="' + ROOT + 'wine/">Wine</a>' +
        '<a href="' + ROOT + '#about">About</a>' +
      '</nav>' +
    '</div>';

  document.body.insertBefore(header, document.body.firstChild);
})();
