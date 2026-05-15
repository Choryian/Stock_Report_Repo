# Stock Report Repository

**Chory & Rochet**이 발행하는 한국 주식 리서치 보고서 아카이브.

🔗 **사이트:** https://choryian.github.io/Stock_Report_Repo/

## 구조

```
.
├── index.html          # 메인 페이지 (보고서 카드 리스트)
├── assets/
│   ├── style.css       # 사이트 공통 스타일
│   └── app.js          # 카드 렌더링·검색·필터
├── data/
│   └── reports.json    # 보고서 메타데이터 (제목/날짜/카테고리/경로/태그)
├── reports/            # 주식 보고서 HTML 원본
├── wine/               # 와인 글
├── images/             # 첨부 이미지
└── publish_report.ps1  # 보고서 발행 자동화 스크립트
```

## 보고서 추가하는 법

### 방법 1: 자동 스크립트 (권장)

```powershell
.\publish_report.ps1 `
  -File    "C:\Users\USER\Documents\daily_close_report_20260516.html" `
  -Title   "2026-05-16 일일 마감 정리" `
  -Summary "KOSPI +0.8%, 외인 코스피 +5,200억. 반도체·2차전지 주도." `
  -Category "시황" `
  -Slug    "kr-daily-close" `
  -Tags    "마감,반도체,Tier1"
```

스크립트가 자동으로 처리:
1. HTML 파일을 `reports/{YYYY-MM-DD-Slug}.html`로 복사 (또는 `wine/` for `-Category "와인"`)
2. `data/reports.json`에 메타데이터 추가 (같은 id 있으면 덮어씀)
3. `git add` + `commit` + `push origin main`
4. 사이트 URL을 stdout 출력 + 클립보드 복사
5. URL을 반환값으로 전달 → 텔레그램 메시지 본문에 첨부 가능

**파라미터:**
- `-File` (필수): HTML 보고서 절대/상대 경로
- `-Title` (필수): 카드 제목
- `-Summary` (필수): 카드 요약 (2-3줄)
- `-Category` (필수): `시황` / `종목분석` / `섹터·테마` / `공지` / `와인`
- `-Slug` (선택): 깔끔한 파일명용 stem. 없으면 원본 파일명 유지
- `-Tags` (선택): 콤마 구분 태그
- `-Date` (선택): YYYY-MM-DD, 기본값 오늘
- `-NoPush` (선택): commit까지만, push 생략 (배치 발행용)

### 방법 2: 수동

1. HTML 파일을 `reports/` (또는 `wine/`) 에 복사
2. `data/reports.json` 의 `reports` 배열에 항목 추가
3. `git add . && git commit -m "..." && git push`

## 일일 루틴 통합

다음 3개 정기 루틴이 보고서 생성 직후 자동으로 사이트에 발행:

- **07:30 KST** `us-overnight-kr-open` — 미국 야간 시황 + 한국 개장 대응
- **12:00 KST** `kr-midday-pivot` — KR 오전 정리 + 오후 대응
- **15:35 KST** `kr-daily-close-next-day` — KR 마감 정리 + 익일 준비

각 루틴은 텔레그램 요약 마지막 줄에 `📄 전체 보고서: {URL}`을 첨부.

## 카테고리

- `시황` — 일일 시황, 마감 정리, 야간 브리핑
- `종목분석` — 개별 종목 심층 분석
- `섹터·테마` — 섹터/테마 모니터링, RRG
- `공지` — 사이트 공지
- `와인` — 와인 노트 (wine/ 폴더)
