# Project: claude-test

이 디렉토리에서 Claude Code가 따라야 할 기본 규칙입니다.

## 기본 동작 (Defaults)

- **답변 언어**: 한국어
- **시간대**: KST (UTC+9) — 사용자가 "오늘"이라고 하면 KST 기준 오늘
- **숫자/통화**: USD 기본, 시가총액에 한해서만 KRW 환산 병기 가능
- **이모지**: 사용 금지 (사용자가 명시적으로 요청한 경우만 예외)

## 주가 분석 요청

티커(예: `ASTS`, `TSLA`, `AAPL` 등 대문자 알파벳 1~5자) + ("주가", "분석", "리포트", "시세", "report") 키워드가 함께 등장하면
**즉시 `stock-report` 스킬을 호출**한다. 모호한 경우 1회만 확인.

스킬 경로: `.claude/skills/stock-report/SKILL.md`
규칙 파일: `RULE.md` (반드시 스킬 실행 시 함께 따른다)

## 파일 맵

| 파일 | 역할 |
|---|---|
| `CLAUDE.md` | 프로젝트 기본 규칙 (이 파일) |
| `RULE.md` | 주가 리포트 형식·콘텐츠 규칙 |
| `.claude/skills/stock-report/SKILL.md` | 주가 리포트 생성 절차 |
| `.claude/skills/stock-report/render.ps1` | JSON → PDF 변환기 (Edge headless 사용) |
| `reports/<TICKER>/YYYY-MM-DD_<TICKER>.{md,json,pdf}` | 출력 파일 |

## 출력 정책

스킬 결과는 항상 다음 세 형식을 동시에 생성한다:
1. `.md` — 사용자 화면에 출력 + 파일 저장
2. `.json` — 구조화 데이터 (스키마는 SKILL.md 참조)
3. `.pdf` — `render.ps1` 호출로 생성 (Edge headless)

저장 경로: `reports/<TICKER>/` (**프로젝트 루트 기준 상대경로** — 이 폴더를 어디로 복사하든 동작)

## 응답 스타일

- 보고서는 표·불릿 활용, 본문은 한국어
- 가격 데이터는 반드시 출처 링크 첨부 (Sources 섹션 필수)
- 짧은 종합 판단 + 면책 문구 필수
