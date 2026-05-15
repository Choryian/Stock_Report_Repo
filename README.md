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
.\publish_report.ps1 -File "보고서경로.html" -Category "종목분석" -Title "삼성전자 분석" -Summary "..."
```

### 방법 2: 수동

1. HTML 파일을 `reports/` (또는 `wine/`) 에 복사
2. `data/reports.json` 의 `reports` 배열에 항목 추가
3. `git add . && git commit -m "..." && git push`

## 카테고리

- `시황` — 일일 시황, 마감 정리, 야간 브리핑
- `종목분석` — 개별 종목 심층 분석
- `섹터·테마` — 섹터/테마 모니터링, RRG
- `공지` — 사이트 공지
- `와인` — 와인 노트 (wine/ 폴더)
