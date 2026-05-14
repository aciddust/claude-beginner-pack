# Stock Report Rules

`stock-report` 스킬 실행 시 반드시 이 규칙을 따른다.

## 1. 보고서 필수 섹션 (순서 고정)

1. **헤더** — `<한글명> (<TICKER>) 주가 분석 리포트` + 기준일(KST)·거래소·시가총액
2. **가격 스냅샷** — 아래의 표 형식
3. **호재 (Bullish Catalysts)** — 5~10개 불릿
4. **악재 (Bearish Risks)** — 5~10개 불릿
5. **종합 판단** — 3문단 이내 (장기 내러티브 / 단기 리스크 / 포지셔닝)
6. **Sources** — 마크다운 하이퍼링크 리스트 (최소 5개)
7. **면책 문구** — 푸터로 고정

## 2. 가격 스냅샷 표 — 다음 6행 반드시 포함

| 행 | 내용 |
|---|---|
| 오늘 | 현재가 + 장중 저가~고가 |
| 지난 7일 | WoW % 변동 |
| 지난 30일 | MoM % 변동 |
| 지난 90일 | 90일 % 변동 + 고가/저가/평균 |
| 1년 | YoY % 변동 + 52주 고가/저가 |
| 사상 최고가 | 일자 + 현재가 대비 % |

부족한 데이터는 빈칸 대신 `-` 또는 "정보 없음"으로 명시.

## 3. 출처 (Sources) 가이드라인

다음 카테고리에서 **각각 최소 1개**:
- **가격/시세**: Yahoo Finance, StockAnalysis, TradingView, MarketBeat
- **실적/공시**: Stocktitan (SEC filings), Business Wire, 회사 IR
- **뉴스/촉매**: TipRanks, Yahoo Finance News, Reuters
- **애널리스트/타깃**: Public.com, WallStreetZen, StockAnalysis Forecast
- **리스크/약세**: Simply Wall St, Foreign Policy Journal, Stocktwits

링크 형식: `[Title](URL)` (마크다운).

## 4. 포맷 규칙

- 언어: **한국어**
- **이모지 사용 금지**
- 숫자: USD 기본. 시가총액은 `$29.0B` 형식. KRW 환산은 시총에 한해 괄호로 병기 가능.
- 변동률: 소수점 1~2자리 (`+5.97%`, `-21.4%`)
- 표는 GitHub-flavored Markdown
- 가격 단위 명기 ($ vs 달러는 혼용 금지 — $ 통일)

## 5. 출력 파일

- 파일명: `YYYY-MM-DD_<TICKER>.{md,json,pdf}` (날짜는 KST 기준)
- 디렉토리: `reports/<TICKER>/`
- 세 형식 모두 생성. 누락 시 스킬 실패로 간주.

## 6. 면책 문구 (고정)

```
※ 본 자료는 정보 제공 목적이며 투자 권유가 아닙니다.
가격은 미국 시장 마감 기준이며 KST 기준 실시간과 차이가 있을 수 있습니다.
```

## 7. JSON 출력 스키마 (요약)

자세한 스키마는 `SKILL.md` 참조. 최소 필드:
```
ticker, company, company_kr, exchange,
report_date_kst, generated_at,
price{current_usd, intraday_low, intraday_high, market_cap_usd},
performance[{period, value, note}],
catalysts[string], risks[string],
summary, sources[{title, url}], disclaimer
```
