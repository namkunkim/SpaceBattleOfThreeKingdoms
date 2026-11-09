# K6 실행 계약 v2 — 행 14·16 개정

독립 판정 REVIEW-INPUT-SEED-INDEPENDENT.md에 따른 재심 입력이다. K6-EXECUTION-CONTRACT.md SHA-256 0e6a6ea344a000832f49d9c2c2300c9e00f73602772a83e4e6db24f6c3455c30을 보존하고 이 문서의 두 행으로 해당 행 및 충돌하는 RESUME-PLAN 문구를 대체한다. 그 밖의 21행 분모, 시간 한도, 동결 및 GUI 소유·귀속 조건은 유지한다.

## 행 14 — 제품 출격 후 seed fixture와 실제 자동 해결 경로

B/A/I 각 lane에서 실제 제품 출격 버튼으로 동일 난이도 표준의 유효 Brief를 만든다. 동일 제품 시점인 출격 버튼 처리 뒤, 실제 skip 입력 전에서 typed Brief 전체를 캡처하고 seed 필드만 -27182818로 교체한다. 교체 직후 전체 typed Brief를 재캡처해 키 집합, 타입 및 값에 대해 전후 차이가 seed 하나뿐임을 단언한다. 이 값은 결정 비교용 fixture이며 UI에서 음수 seed를 선택할 수 있는 기능으로 집계하지 않는다. UI 자연 seed 경로를 별도 관측하는 경우 독립 case_id를 사용한다. 최초 생성 seed를 보관하되, 정규화 후 B/A/I의 전필드 일치가 판정 대상이다. 예상하지 않은 다른 차이는 실패다.

동결된 실제 skip 버튼→_finish_sortie→_start_resolve 호출 순서를 B/A/I에서 제품 이벤트와 별도로 관측한다. B/A는 mode 실패 주입 없이 완료까지 실행한다. I 첫 회는 동일 유효 Brief를 유지하고 실제 factory 인자의 mode만 invalid로 바꾸는 별도 계측이다. seed fixture 실행과 mode 주입을 별도 action_id 및 원문으로 기록한다. 진입1/생성0/thread0/outcome0과 오류 칩/browse를 확인한 후 주입을 해제한다. 같은 UI의 실제 재시도에서 다시 제품 출격 후 동일 시점의 seed fixture와 skip을 적용하고 정상 terminal까지 진행한다. 직접 함수 호출이나 pressed.emit의 보조 결과가 실제 제품 버튼 경로를 대체하지 않는다.

예상 결과는 B/A/I 동일 terminal tick/clock/fingerprint/typed outcome, join 뒤 결산 가시 전환 1회, 반복 poll 불변, 각각 exit 0이다. 600초 내부 만료는 실패로 남기고 취소/join을 요청하며 630초 외부 상한을 적용한다. manifest에 before/after typed Brief 전체와 field_diff.gdvar, 제품 입력과 호출 순서, seed 및 mode 변경 지점과 SHA, failure_ui.gdvar, progress.gdvar, terminal.gdvar, result_visibility.gdvar를 명명한다. 고정 seed signed 계약과 행 9의 직접 경계 사례는 유지한다.

## 행 16 — 실제 OS 키보드 동작과 실제 OS 마우스 경로

B/A 각각에서 실제 OS 키 입력으로 Space 메뉴 전환 등 지원 경로 하나를 실행한다. 고정 fixture와 기대 focus, 전후 메뉴 표시/게임 상태, 수신 키의 종류와 입력 출처를 기록한다. 재시작 및 routed 천하 복귀는 각각 실제 OS 마우스로 해당 제품 버튼을 조작하고, 별도 action_id와 focus·route·입력 로그 및 실제 네이티브 렌더 전후를 남긴다. 최초 재시작과 이후 복귀에서 대상 객체·장면 전환 및 기대 결과를 구분해 판정한다. 키 입력 결과와 마우스 버튼 결과가 각각 성공해야 행을 충족한다.

키보드 전용 재시작/천하 복귀는 인수 범위에서 제외한다. 정적 조사에서 해당 경로는 확인되지 않았고 PauseScreen 버튼은 FOCUS_NONE이다. 이 개정은 키보드 전용 기능 추가나 접근성 인수가 아니다. 각 action의 PID/creation time/image SHA, OS HWND 소유·전경·client rect, Sky 창의 유일 대응 및 연속 전경·입력 귀속 요건은 기존 계약대로 적용한다. 입력 출처 불명·혼재, 대상 불일치, renderer 증거 누락은 해당 행을 미충족으로 남긴다.

이 개정은 계획 문구 재심 요청이다. 완성된 실행 명령, 계측 diff·SHA, 실제 관측 방법 및 기대값의 독립 수용 전 K6은 시작하지 않는다. 기존 K1~K5 및 실패 원문과 K=6 상한을 유지한다.
