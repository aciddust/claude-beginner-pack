# claude-test — Stock Report Skill Package

특정 티커의 주가 분석 리포트를 한국어로 생성하고 **.md / .json / .pdf** 세
형식으로 저장하는 Claude Code 스킬 패키지.

---

## 사용법

이 디렉토리에서 Claude Code를 실행하고 채팅에 입력:

```
ASTS 주가 분석해줘
TSLA 리포트
```

→ `reports/<TICKER>/<YYYY-MM-DD>_<TICKER>.{md,json,pdf}` 자동 생성.

---

## 파일 구조

```
claude-test/
├─ README.md                            # 이 파일
├─ CLAUDE.md                            # 프로젝트 진입 시 Claude가 자동 로드
├─ RULE.md                              # 리포트 형식 규칙
├─ .claude/
│  └─ skills/
│     └─ stock-report/
│        ├─ SKILL.md                    # 스킬 실행 절차
│        ├─ template.html               # PDF 렌더링용 HTML 템플릿
│        └─ render.ps1                  # JSON → PDF 변환기
└─ reports/
   └─ <TICKER>/                         # 종목별 출력 폴더
```

---

## 각 파일의 역할 — 왜 분리되어 있나?

### `CLAUDE.md` — 프로젝트 자동 컨텍스트
Claude Code가 이 디렉토리에서 시작할 때 **자동으로 시스템 프롬프트에 주입**되는 파일.
응답 언어(한국어), 시간대(KST), 이모지 정책, 스킬 트리거 키워드 등 **항상 적용되는 기본
동작**을 정의. *사용자가 매번 "한국어로 답해줘"라고 쓰지 않아도 되는 이유가 이 파일.*

### `RULE.md` — 리포트 콘텐츠 규칙
주가 리포트의 **형식·콘텐츠 규칙**만 따로 모아둔 파일. 6행 가격표, 호재/악재 최소 개수,
출처 카테고리, 면책 문구 등. 스킬 실행 절차(SKILL.md)와 분리되어 있어서, **규칙만 살짝
바꾸고 싶을 때 SKILL.md를 건드리지 않아도 됨**. 예: "표 행을 7행으로 늘리기" → RULE.md만
수정.

### `.claude/skills/` — Claude Code 스킬 디렉토리
Claude Code가 **사용자 요청에서 트리거를 감지해 자동 호출**하는 스킬들이 사는 폴더.
한 폴더 = 한 스킬. 폴더명이 곧 스킬 이름. CLAUDE.md와 다른 점: CLAUDE.md는 항상
로드되지만, 스킬은 **관련 요청이 들어왔을 때만 호출**됨.

### `.claude/skills/stock-report/SKILL.md` — 스킬 실행 절차
"ASTS 주가 분석해줘" 같은 요청을 받았을 때 Claude가 따라가는 **7단계 절차서**.
WebSearch 쿼리 목록, JSON 스키마, 종료 코드별 동작, 파일 저장 규칙 등 *실행 로직*만 담당.
*무엇을 만들지(RULE.md)*와 *어떻게 만들지(SKILL.md)*가 분리된 형태.

### `.claude/skills/stock-report/template.html` — PDF용 HTML 템플릿
"주가 분석 리포트", "호재", "악재" 같은 **정적 한글 라벨**은 모두 이 템플릿 안에 있음.
`{{TICKER}}`, `{{PERF_ROWS}}` 등 자리표시자는 render.ps1이 JSON 데이터로 치환.
**한글을 .ps1에서 분리한 이유**: Windows PowerShell 5.1은 BOM 없는 .ps1 파일을 시스템
ANSI 코드페이지(CP949)로 해석해 한글이 깨짐. 한글을 외부 HTML(명시적 UTF-8 로드)로
빼서 이 문제를 구조적으로 회피.

### `.claude/skills/stock-report/render.ps1` — PDF 변환기
JSON + HTML 템플릿 → PDF. **의도적으로 ASCII-only**. Microsoft Edge → Chrome 순으로
헤드리스 브라우저를 찾아 PDF로 인쇄. 둘 다 없으면 exit 2로 빠지고, 스킬은 .md/.json만
보고하면서 사용자에게 안내 메시지 출력.

---

## 분리 구조 요약

| 변경 사항 | 수정할 파일 |
|---|---|
| 기본 응답 언어, 트리거 키워드, 이모지 정책 | `CLAUDE.md` |
| 표 행 개수, 필수 섹션, 출처 카테고리 | `RULE.md` |
| WebSearch 쿼리, JSON 스키마, 실행 단계 | `SKILL.md` |
| PDF 디자인(CSS), 정적 한글 라벨 | `template.html` |
| 브라우저 탐색, PDF 옵션 | `render.ps1` |

---

## 다른 환경에서 사용 가능한가?

| 환경 | 지원 | 비고 |
|---|---|---|
| Windows + PowerShell 5.1+ + Edge or Chrome | 정식 지원 | .md / .json / .pdf 모두 생성 |
| Windows, 브라우저 없음 | 부분 지원 | .md / .json만 생성, PDF는 스킵 안내 |
| Windows, 다른 사용자 / 다른 디렉토리에 복사 | 정식 지원 | 모든 경로 상대경로 — 그대로 작동 |
| macOS / Linux | 미지원 | `render.ps1`이 PowerShell·Edge 의존 — Bash/Python 포팅 필요 |

### 다른 위치로 이식하기

이 패키지를 다른 프로젝트로 복사할 때:

1. `CLAUDE.md`, `RULE.md`, `README.md`, `.claude/` 폴더, (선택) `reports/` 폴더를 통째로 복사
2. 그 디렉토리에서 Claude Code 실행
3. 끝.

스킬 안의 경로는 모두 **프로젝트 루트(=Claude Code CWD) 기준 상대경로**.
Edge/Chrome 경로는 Windows 표준 설치 위치를 자동 탐색하므로 사용자 폴더와 무관.

---

## 면책

생성된 리포트는 **정보 제공 목적**이며 투자 권유가 아닙니다. 가격은 미국 시장
마감 기준이며 KST 실시간과 차이가 있을 수 있습니다.
