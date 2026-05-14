---
name: stock-report
description: Use when the user asks for stock price analysis, ticker report, or "<TICKER> 주가 분석/리포트". Generates a Korean stock report (today/7d/30d/90d/1Y + catalysts/risks) and exports .md/.json/.pdf under reports/<TICKER>/.
---

# Stock Report Skill

한국어 주가 분석 리포트를 생성하고 **.md / .json / .pdf** 세 형식으로 저장한다.

## 트리거

- `<TICKER> 주가 분석해줘`
- `<TICKER> 리포트` / `<TICKER> 시세 분석`
- `/stock <TICKER>` (사용자가 이렇게 입력하면 의도 명확)

대문자 1~5자 ASCII = 티커. 한글 종목명이 함께 오면 그것도 보존.

## 절차 (반드시 순서대로)

### Step 1. 입력 파싱
- 티커를 대문자로 정규화 (예: `asts` → `ASTS`)
- 한글명이 함께 주어졌으면 `company_kr` 로 사용
- 모호하면 1회 확인. 불분명하지 않으면 바로 진행.

### Step 2. 컨텍스트의 currentDate 확인
- 시스템에서 제공하는 `currentDate` 를 KST 기준 오늘로 간주
- 형식: `YYYY-MM-DD`

### Step 3. WebSearch 병렬 수집 (한 번에 4~6개 쿼리)
다음을 모두 영문 쿼리로 검색 (정확도가 더 높음):
1. `<TICKER> stock price today <YYYY>`
2. `<TICKER> stock price history 90 days <YYYY>`
3. `<TICKER> stock price one year ago <YYYY-1>` (52주 변동 확인용)
4. `<TICKER> news catalyst <Month YYYY>` (호재)
5. `<TICKER> bear case risk dilution short` (악재)
6. `<TICKER> analyst price target <YYYY>`

가능하면 한 메시지에서 모든 WebSearch를 병렬 호출. 결과가 불충분하면 추가 검색.

### Step 4. 데이터 정리
- 모든 숫자는 신뢰 가능한 단일 소스로 교차 검증 권장
- 부족한 데이터는 `null` 또는 `"정보 없음"`. 추정값 금지.

### Step 5. JSON 작성
다음 스키마에 맞춘다:
```json
{
  "ticker": "ASTS",
  "company": "AST SpaceMobile",
  "company_kr": "AST스페이스모바일",
  "exchange": "NASDAQ",
  "report_date_kst": "2026-05-14",
  "generated_at": "2026-05-14T15:30:00+09:00",
  "price": {
    "current_usd": 78.42,
    "intraday_low": 75.02,
    "intraday_high": 79.32,
    "market_cap_usd": "29.0B"
  },
  "performance": [
    { "period": "오늘", "value": "$78.42", "note": "장중 $75.02 ~ $79.32" },
    { "period": "지난 7일", "value": "+5.97%", "note": "어닝 미스 직후 반등" },
    { "period": "지난 30일", "value": "-21.4%", "note": "4월 발사 실패 + Q1 미스" },
    { "period": "지난 90일", "value": "-23.1%", "note": "고가 $104.15 / 저가 $63.43 / 평균 $77.93" },
    { "period": "1년", "value": "+168.5%", "note": "52주 $22.47 ~ $129.89" },
    { "period": "사상 최고가", "value": "$129.89 (2026-01-30)", "note": "현재가 ATH 대비 -40%" }
  ],
  "catalysts": [
    "FCC 상업 SCS 서비스 + 248기 컨스텔레이션 승인",
    "AT&T·Verizon 스펙트럼 D2D 파트너십",
    "$1.2B+ 계약 매출 커밋먼트",
    "현금 $3.5B, 2026 가이던스 $150~200M 재확인",
    "피크 데이터 속도 98.9 Mbps 달성 (미개조 스마트폰)",
    "Falcon 9 BlueBird 8/9/10 6월 발사 예정"
  ],
  "risks": [
    "Q1 2026 매출 $14.7M, 컨센서스 $37.5M 대비 -61%",
    "분기 FCF -$427.4M, 순손실 -$191M",
    "BlueBird 7 분실 + 4/20 Blue Origin 위성 궤도 진입 실패",
    "지난 1년간 발행주식 수 +28% (희석)",
    "SpaceX IPO 시 Alphabet 25% 지분 매도 압력",
    "장기차입금 $2.97B, 추가 자금 조달 가능성"
  ],
  "summary": "장기 D2D 위성통신 선도 위치는 FCC 허가와 AT&T·Verizon 파트너십으로 견고. 다만 1월 ATH 이후 -40% 조정, Q1 어닝 미스와 위성 발사 실패 누적으로 단기 리스크 확대. 6월 BlueBird 8/9/10 발사가 단기 최대 분기점. 고변동성 성장주로 분할 매수 권장 구간.",
  "sources": [
    { "title": "Yahoo Finance — ASTS Quote", "url": "https://finance.yahoo.com/quote/ASTS/" }
  ],
  "disclaimer": "본 자료는 정보 제공 목적이며 투자 권유가 아닙니다. 가격은 미국 시장 마감 기준이며 KST 기준 실시간과 차이가 있을 수 있습니다."
}
```

### Step 6. 파일 저장

**경로는 모두 프로젝트 루트(=Claude Code의 CWD) 기준 상대경로**.
절대경로를 박지 말 것 — 다른 사용자가 그대로 복사해 쓸 수 있어야 한다.

- 출력 디렉토리: `reports\<TICKER>\`
- 파일명: `<YYYY-MM-DD>_<TICKER>.md`, `<YYYY-MM-DD>_<TICKER>.json`

저장:
- `.md` : 사용자 화면에 출력하는 본문과 동일한 내용으로 저장 (Write tool)
- `.json` : 위 스키마 그대로 (Write tool, UTF-8)

디렉토리가 없으면 PowerShell로 먼저 생성 (상대경로):
```
New-Item -ItemType Directory -Force -Path 'reports\<TICKER>'
```

Write tool 호출 시에는 Claude Code가 절대경로를 요구하므로, 현재 CWD를
앞에 붙여 절대경로로 변환해 사용한다. 단 **SKILL.md / RULE.md / CLAUDE.md
어디에도 사용자별 절대경로를 박아두지 말 것**.

### Step 7. PDF 생성 (실패해도 스킬은 계속 성공)

이 단계는 **베스트-에포트**다. PDF는 Edge 또는 Chrome 헤드리스에 의존하므로,
실행 환경에 둘 다 없으면 PDF 없이 .md/.json 만 결과로 보고한다.

**파일 구조**:
- `render.ps1` — ASCII-only 스크립트 (한글 텍스트를 포함하지 않음)
- `template.html` — UTF-8, 정적 한글 라벨(섹션 제목, 헤더 등) 포함
- 스크립트는 템플릿을 명시적 UTF-8로 읽고 `{{TOKEN}}` 자리표시자를 JSON 데이터로 치환

이 분리는 Windows PowerShell 5.1이 BOM 없는 .ps1을 시스템 ANSI(CP949 등)로 잘못
해석하는 문제를 구조적으로 회피한다. **render.ps1에는 절대 한글을 직접 작성하지
말 것**. 라벨을 바꾸려면 template.html을 수정한다.

```
powershell -ExecutionPolicy Bypass -File ".claude\skills\stock-report\render.ps1" -JsonPath "reports\<TICKER>\<YYYY-MM-DD>_<TICKER>.json"
```
(CWD가 프로젝트 루트라는 전제. 다른 CWD에서 호출해야 하면 그때만 절대경로 사용.)

`render.ps1` 종료 코드:

| Exit | 의미 | 스킬 동작 |
|---:|---|---|
| 0 | PDF 생성 성공 | 3개 파일 모두 보고 |
| 2 | 헤드리스 브라우저(Edge/Chrome) 없음 | **PDF 없이 .md/.json 만 보고**. 사용자에게 "헤드리스 브라우저 미설치로 PDF 생성을 건너뛰었습니다" 안내 |
| 3 | 브라우저는 있으나 PDF 렌더링 실패 | .md/.json 만 보고. 사용자에게 "PDF 렌더링 실패 (자세한 stderr 첨부 가능)" 안내 |
| 1, 그 외 | 잘못된 입력 또는 예상 외 오류 | 스크립트 출력을 그대로 사용자에게 전달 |

**중요**: PDF 실패는 절대 .md/.json 단계를 되돌리지 않는다. 스킬은 .md/.json 이
생성된 시점에 이미 부분 성공이며, PDF 는 보너스로 처리한다.

### Step 8. 사용자 응답
1. 보고서 본문(.md 내용)을 채팅에 그대로 출력
2. 마지막에 생성된 파일들의 절대경로를 표 또는 리스트로 명시
3. PDF가 생성되지 않은 경우 다음 문구 중 하나로 명확히 안내:
   - exit 2 → "PDF 생성을 건너뛰었습니다 — 시스템에 Microsoft Edge / Chrome 헤드리스가 없습니다. .md, .json 만 저장됐습니다."
   - exit 3 → "PDF 렌더링에 실패했습니다 — .md, .json 은 정상 저장됐습니다. 필요하면 다시 시도해 보세요."

## 콘텐츠 규칙
모든 콘텐츠 규칙은 **`RULE.md`** 참조. 특히:
- 6행 가격 표 필수
- 호재/악재 최소 5개씩
- Sources 최소 5개, 카테고리 다양화
- 이모지 금지
- 한국어
- 면책 문구 고정

## 실패 처리
- WebSearch 결과 부족 → 추가 쿼리 1~2회 시도. 그래도 부족하면 해당 필드 `"정보 없음"` 표기 후 진행 (스킬 자체는 완료).
- `render.ps1` 실패 (exit 2/3) → **에러로 취급하지 말 것**. .md/.json은 이미 저장 완료 상태이며, Step 8의 안내 문구로 사용자에게 PDF 누락을 알리고 스킬은 부분 성공으로 종료.
- 즉, **MD/JSON 생성이 곧 스킬의 핵심 산출물**이고 PDF 는 베스트-에포트 부가 산출물이다.
