# P02 일곱째 조각 독립 구현 5-b

판정: **한정 수용**. 기존 `init_game`의 지정 profile patch 명시 실패를 사용자에게 표시하고 최초 실패에서 종료 또는 결과 없이 천하로 돌아가는 범위다. 전체 P02·제품 operation·적벽 operation·owner restore·Android·성능은 인수하지 않는다. K1~K6을 모두 사용했다. 문서·ZIP 마감은 별도 독립 판정이다.

## 독립 대조

- 제품 코드는 실패 반환/로그를 유지하며 기존 sim에는 비모달 경고, 최초 실패에는 독립 오류 화면과 routed `WorldLink.back_to_world(null)` 또는 단독 종료를 연결한다. 현재 렌더 원본 `k4-current/after-render-routed/initial.png`, `after-render-live/live-warning.png`, `recover.png`를 직접 확인했다. 한국어 이유와 행동이 화면에 읽히고 성공 후 경고가 사라진다. 최초 routed 별도 실제 OS 마우스/Return에서 각 입력과 WorldMap 활성, brief/outcome null 및 표준/auto 보존이 기록됐다. 단독 두 입력은 이전 owner 바이트에서의 역사적 GUI 증거다.
- 기존 03~08 GUI 입력 원문의 대상 좌표·실제 버튼 pressed와 후속 오류 스택이 부합한다. 03/04 사용자 입력 교차와 03/05 off-target 입력은 행위 주체를 확정하지 않고 원문에 보존한다. 여섯 GUI 상태 필드는 sim ID·tick·org·G.state·selected·events뿐이며, 546개 atomic 단언을 GUI 클릭에 직접 적용한 것이 아니다. 그 밖의 clock·trace·카메라 등은 별도 atomic 검사 범위다.
- K4 고정 seed의 별도 `init_game` 시작 한 행은 wall_time/mono_ms만 제외한 전후 동일, control/pos 변조 거절이다. 최초 randomize 시작은 strict 7/8 불일치로 남고 startup 전체 동등성으로 집계하지 않는다. K5 WorldMap 완료/취소는 실제 제품 버튼에 주입한 자동 viewport 입력이며 OS 입력 사례가 아니다. 각 측 완료 14/취소 15단언, 동일 seed 350157 및 완료 fingerprint, 같은 resolver join과 결산 1회/취소 결과 부재를 기록한다. K4 카드 준비 실패 및 K5 하네스의 카드 입력·대기·시드 변경도 보존한다.
- K6의 네 원문은 전후 clean exit 1(기존 서막 기대 단일 실패), returning exit 0, timeout false 및 입력 불변을 기록한다. K4의 before WorldLink timeout을 이 결과로 지우지 않는다. ObjectDB/resource 종료 진단은 각 stderr에 남아 있으며 일부 수치 차이의 원인은 확정하지 않는다. `GUI-RESUME-EVIDENCE.md`, `K4-K5-EVIDENCE.md`, `K4-K5-OBSERVATIONS.json`, `k6-worldlink-retry/processes.json` 참조.
- 이전 owner C555…에서 AC59…로 바뀐 공통 파일은 양쪽 현 동결 사본에 동일 반영됐다. `freeze-complete.json`은 사본 4,228경로 중 FleetBattle3D 한 파일 차이를 기록한다. 독립 시점에 `k4-current/preflight.json`의 현재 입력 4,228개를 다시 SHA-256 비교해 차이 0을 관측했다. 순차 해시 일치는 중간 변경 부재나 주체를 증명하지 않는다. 전역 PNG 13개 drift는 실행 입력과 구분하며 P03 또는 다른 주체의 소유를 추정하거나 복원하지 않는다.
- 세션 권위 원문에서 구현 `/root/p02_seventh_impl`의 turn_context는 gpt-6.1-sol, 독립 심사 `/root/p02_seventh_review`는 gpt-6.1-terra임을 확인했다. 각각 rollout `01a1ba26-a8fe-7931-bf6b-b7da2d0708b0` line 1/10/574/929와 `01a1ba22-7d53-79c3-a9f7-405769386721` line 1/562다. 실제 모델이 다르다.

기존 legacy fallback은 보존된 경로이지 제품 operation 지원 근거가 아니다. 일반적인 자연 발생 오류 빈도, 화면 입력 중 모든 상태의 불변, 실제 최초 randomize trace 완전 일치, 동시 변경 주체는 확인하지 않았다.
