# 엑셀 → docx 자동화 퀵스타트

이 폴더에는 다음이 미리 준비되어 있습니다.

- `평가데이터.xlsx` — 직원 5명 분량 샘플 데이터
- `템플릿.docx` — `{{이름}}`, `{{부서}}` 등 자리표시자가 포함된 워드 양식
- `결과/` — 출력 폴더 (비어있음)
- `.claude/skills/excel-to-docx/SKILL.md` — 엑셀 → docx 일괄 변환 스킬

## 사전 준비

Python 라이브러리 두 개가 필요합니다 (한 번만 설치).

**macOS**:

```bash
pip3 install openpyxl python-docx
```

**Windows (PowerShell)**:

```powershell
pip install openpyxl python-docx
```

## 사용법

1. 이 폴더에서 터미널/PowerShell 을 엽니다
2. `claude` 실행
3. 다음 요청 입력:

```
@평가데이터.xlsx 를 @템플릿.docx 에 맞춰서 평가서 일괄 생성해줘
```

4. `결과/` 폴더에 5개 docx 파일이 만들어집니다 (`김철수_템플릿.docx` 등)

## 참고

- 결과 docx 의 한글이 깨져 보이면: 본문 폰트 문제 — `템플릿.docx` 를 열어 본문 폰트를 "맑은 고딕" / "Apple SD Gothic Neo" 로 통일.
- 본인 회사 양식으로 바꾸고 싶다면 `템플릿.docx` 만 본인 양식으로 교체. `{{컬럼명}}` 표기만 유지하면 자동으로 매칭됩니다.
- `.claude/` 가 숨김 처리되어 안 보이면: macOS `Cmd+Shift+.`, Windows 탐색기 보기 메뉴 → "숨긴 항목" 체크.
