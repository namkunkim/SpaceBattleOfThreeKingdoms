# 첫 PC 직접 출격의 난이도 전달

2026-11-09 · P02 한정 계획 · 독립 계획 심사 대기 · 실행 0회.

## 실제 결함

WORLD-MAP-LINK §3은 difficulty를 규칙 입력으로 정의한다. WorldMap `_set_difficulty → make_brief → _finish_sortie`가 선택을 `WorldLink.go_battle`에 전달한다. FleetBattle3D `_prepare_game`은 같은 brief의 seed만 읽고 장면 기본값 표준으로 자동 편성·수동 편성 기반·fallback 프로필을 읽는다. FleetBattle3D.tscn에는 난이도 override가 없다. 반면 BattleOutcome.from_facts는 brief의 선택값을 돌려준다. 따라서 플레이어가 상급을 골라도 전투는 표준 편성을 쓰고 결산은 상급으로 표시할 수 있다. 기존 tests/world_link.gd의 제품 장면 직접 출격은 표준만 고른다. 시나리오 원본의 조조 편성 한도는 입문 9, 표준 10, 상급·극한 14이며 난이도별 AI suspicion_per_s는 0.4, 0.8, 1.5, 2.0이다.

## 작업 경계

- FleetBattle3D의 준비 후보에서 routed일 때 brief의 난이도를 구하고 세 legacy 로드 경로에 같은 값을 사용한다. standalone은 현재 난이도를 사용한다. 성공 후보에 난이도를 담아 기존 publish 지점에서만 반영한다. 편성 화면은 이미 battle.difficulty를 읽는다. 초기/후속 준비 실패는 현재 안내와 기존 상태 보존 규칙을 따른다. 재출격이 같은 brief를 쓰는 동안 동일 난이도를 유지한다.
- 결산 라벨 자체를 수정할 필요는 없다. P03 owner, 복원 및 A06 지도 결산 경계, P05 접근 geometry, P07 목표·철수·보급·증원은 별도 소유다. 이번 변경은 기존 적벽 직접 출격의 규칙 선택을 바로잡는다. 새 캠페인 operation은 P02 host와 P03 신규 owner 계약, P05 제품 기하, P07 작전 규칙 연결에 계속 의존한다.
- 같은 FleetBattle3D 준비 함수에 미적용 여덟째 패치가 있다. 현 원본과 후보 hunk를 대조하고 쓰기 창을 별도 조율한다. 여덟째 패치와 함께 적용하거나 이 조각을 K6 근거로 합산하지 않는다.
- 실제 카드에서 생성 가능한 네 난이도에 한정한다. `profile_def == ""`의 기존 PocSetup 분기와, 임의 invalid brief가 기존에 어떤 경로로 유입되는지를 별도로 조사한다. POC에 시나리오 난이도를 표시할지, 잘못된 라우팅 입력을 어느 경계에서 거부할지는 기존 계약을 확인하기 전 정하지 않는다. 이 정책이 후보에 필요하면 독립 심사로 되돌린다.

## 사전등록 검사 11행

| 행 | 진입과 판정 |
|---|---|
| 1–4 | 실제 WorldMap 직접 출격의 난이도 4종. 같은 고정 seed의 canonical UI 선택 → 출격 → 브리핑 → 시작/배치 확정. 데이터 정본과 실제 sim의 조조 roster ID/수 및 난이도 규칙을 비교한다. 입문·상급·극한의 baseline 불일치와 표준 통과를 기록한다. |
| 5 | 상급 routed 편성 화면에서 기존 UI로 유효한 편성을 확정하고 시작한다. 실제 활성 sim 난이도/roster와 사용자 편성 적용을 확인한다. |
| 6 | 상급 결과의 재출격. 같은 brief·seed·난이도에서 재준비 후 roster, 규칙, 초기 상태를 첫 출격과 비교한다. |
| 7 | 유효 상급 brief의 profile 후보에 기존 profile_patch 실패 seam을 사용한다. 초기 준비 거부에서 실제 천하로 돌아가는 버튼과 결과 없음, last difficulty 보존을 확인한다. |
| 8 | 상급 전투가 게시된 후 기존 profile_patch 실패 seam으로 재준비 실패를 낸다. 동일 sim identity·seed·난이도·G·편성·선택·카메라·시계·trace 및 기존 screen을 보존하고 안내만 더한다. 실패 주입을 제거한 뒤 정상 재준비를 확인한다. |
| 9 | standalone 직접 장면의 표준 동등성. 같은 fixture seed의 roster·규칙·controls와 title 경로를 전후 대조한다. |
| 10 | 상급 WorldMap 자동 해결 대조. 제품 worker가 사용하는 profile과 결산 난이도를 확인한다. 기존 정상 종료 경로를 사용하고 timeout을 성공으로 세지 않는다. |
| 11 | 격리 fixture에서 상급 사용자 편성 적용 거절과 기존 자동 편성 대체 경로를 유도한다. 동일 상급 규칙으로 fallback을 준비하며 기존 편성 오류와 시작 차단을 관측한다. fallback 후보까지 유효하지 않은 경우는 행 8의 hard-failure 판정과 구분한다. |

독립 오라클은 원본 시나리오 JSON의 difficulty_order, difficulty_profiles 및 출전 순서/지연에서 기대 roster와 구별 가능한 규칙 값을 계산한다. 후보의 loader나 결과 라벨을 기대값 생산에 재사용하지 않는다. 실제 초기 sim의 전체/즉시 전대와 양측 초기 제어, brief 및 결산을 동일 실행의 별도 raw 증거로 남긴다. 결산 DTO 경계를 빠르게 대조할 종료 fixture는 독립적으로 표기하며 자연 종결로 세지 않는다. 서막은 의도된 분기를 별도로 기록한다. clean 설정으로 서막 건너뛰기까지 직접 진행하고 returning 설정에서는 브리핑 직행을 확인한다. 표준 가정의 기존 테스트 실패를 UI 결함으로 분류하지 않는다.

행 3의 GUI 입력은 canonical 시작점, Windows 격리 사용자 경로, 제품 PID·HWND·전경 일치가 실행 전에 증명될 때 실제 마우스 또는 키보드로 수행한다. 선택·출격·서막 건너뛰기·브리핑·배치 확정의 각 단계에서 입력과 화면 전이를 같이 기록한다. signal 호출과 viewport 합성 입력은 자동 행에만 귀속한다. 물리 입력 조건 불충족은 해당 행 미수용이다. 브라우저·HTML을 쓰지 않는다. 11행 분모와 baseline 예상 실패를 사전 고정하고 실제 exit, timeout, 신규 오류/기존 종료 진단을 원문과 함께 분리한다.

## 게이트와 자원

1. 독립 비-Astra 심사에서 실제 원본 결함, hunk 충돌, 데이터 독립 오라클, 11행 판정 및 Windows 입력 사전조건을 먼저 확인한다. 반려 시 스펙을 고친다.
2. 현재 baseline.json은 필수 경로 SHA-256, HEAD blob, HEAD/index, staged와 tracked 상태의 읽기 스냅숏이다. 실행 전 정확한 import/런타임 closure 및 엔진과 파일 SHA를 동결하고 drift를 대조한다. 미승인 공유 파일 원본과 P03 변경을 보호한다. 약 3.26 GB 여유에서 단일 격리 프로젝트와 순차 전후 실행을 우선 검토한다. 필요한 peak 용량과 기존 캐시 재사용 또는 정리 대상의 경로·인벤토리·보존 범위 증명 전에는 복사/삭제/실행을 시작하지 않는다.
3. 계획·공유 창 승인 뒤에도 실행 시도 예산을 별도로 확정한다. PC0 2/2 소진과 여덟째 K6 미사용을 유지한다. 이번 계획에는 코드, 엔진, OS 입력, 커밋, 푸시, 브랜치 또는 worktree 작업이 없다. 5-a 후 별도 비-Astra 5-b에서 원시 증거와 실제 차이를 확인한다.
