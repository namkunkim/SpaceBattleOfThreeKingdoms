# P03 격리 호스트 시계·게시 개정 계획

2026-11-09 KST. 독립 계획 심사 대기. 이 단계는 계획 작성만 수행한다. 작성 담당은 상속된 Sol 모델이고 Astra는 사용하지 않는다. 실제 서빙 확인과 다른 모델의 독립 검토는 조율자가 배정·기록한다.

## 기존 증거와 판정

`tmp/p03-product-resume-20261108/HOST-CLOCK.md`는 정적·산술 검증이다. 중지 전 `tmp/p03-host-clock-ui-20261108/`의 `host_clock.gd`, `preserve.log`, `reset.log`, `exits.txt`, `before.json`, `after.json`을 읽었다. 두 Godot 호출 모두 실제 exit 0과 다섯 CHECK true를 출력했다. `preserve`는 1틱·잔여 .25, `reset`은 0틱·잔여 .5였다. 그러나 최초 fingerprint가 각각 `25e0…`와 `a12f…`로 달라 동일 초기 상태 대조가 성립하지 않았다. 두 호출 모두 완료 표식 뒤 `Detection.sensor_of`의 SCRIPT ERROR 4개, ObjectDB 4개와 resource 2개 종료 진단이 있었다. 어느 쪽도 정식 5a PASS로 세지 않는다. `FleetBattle3D._ready()`는 `randomize()`를 호출하고 `_prepare_game()`은 routed brief가 없으면 `randi()`로 seed를 먼저 결정한다. 기존 runner의 profile_patch 내 `seed()`는 그 후보 seed 결정 뒤다.

기존 실제 엔진 호출은 preserve/reset 합계 2회로 이력에 남긴다. 기존 호출의 사전등록 K는 확인하지 못했다. 본 개정에서는 호스트 조각 전체 실제 엔진 호출 상한 K6에 위 두 호출을 포함해 잔여 4회를 상한으로 제안한다. 새 runner는 분기 전체를 한 엔진 호출에서 검증해 호출 수를 낮춘다. 실패를 덮어쓰거나 새 계획으로 횟수를 초기화하지 않는다. 사용량 제한은 즉시 보고하고 반복하지 않는다.

## 승인 요청 범위

현재 `scripts/FleetBattle3D.gd`의 `init_game`은 `_prepare_game` 오류 시 오류 UI를 게시하고 반환한다. `_publish_game`은 정상 새 전장 게시에서 두 clock과 표시 상태를 초기화한다. `_process`는 play 시 clock.advance → sim.step → alpha/pump 경로를 실행한다. 이번에는 정본 바이트의 격리 복제에서 **직접 구성한 phase 분기 및 실제 legacy 재준비 실패**를 확인한다. 제품 운영 복원 호출, 운영 phase 정책 선택, 실제 사용자 화면의 첫 재개, 외부 ACK는 미검증으로 남긴다. P02 기존 준비 실패 시험의 전체 재수용 대신 본 시험은 실제 첫 프레임 이후의 phase와 이전 상태 보존·다음 프레임을 함께 비교한다.

소유 경로는 `tmp/p03-inchat-host-clock/`만이다. 기존 중지 증거와 공유 P02 파일을 읽기만 한다. 새 Git 작업트리나 브랜치·커밋을 만들지 않는다. 승인 후 새 시도별 하위 디렉터리에 격리 프로젝트와 고유 appdata·로그를 예약한다. `.godot` 전역/정본 변경 금지. 격리 캐시의 로컬 resource_path와 원본 `FleetBattle3D`·`TickClock`·`BattleSim`·fixture 의존 파일의 전체 바이트 SHA를 확인한다. 실행 엔진 console·본체 및 runner, 프로젝트·입력·계획 SHA와 Git HEAD/index 및 P02 동시변경을 기록한다. 본체 경로·PID를 직접 기록하고 종료와 제한 시간 회수를 분리한다. 외부 동시 상태 차이는 발생 경로를 분리하며 영향을 받는 보호 입력 차이가 있으면 해당 실행을 실패 처리한다.

## 5a 사전 인수 조건

1. `same_initial_host_state`. branch 별 별도 인스턴스에 같은 시나리오·seed를 공급한다. 우선 정본 `WorldLink.brief.seed`를 같은 값으로 설정하는 격리 autoload 입력을 사용한다. routed 모드의 profile/난이도 차이는 각 분기에 동일하게 고정한다. 엔진 자동 `_process`와 입력을 통제하고 실제 수동 프레임 이전 tick·clock_ms·seed·동일 fingerprint·동일 유효 투영을 강제한다. 동일성 미달은 즉시 실패한다. 첫 probe처럼 profile_patch 안에서 전역 seed를 바꾸는 방식은 쓰지 않는다.
2. `actual_first_frame_phase_fork`. phase만 0/.75로 설정한다. hz=10, speed=1, slow=1, delta=.05, not placing, play 조건에서 실제 호스트 `_process` 뒤 각각 tick 0/1, 논리 시각 0/100ms, `acc` 및 `vm.alpha` .5/.25를 확인한다. 수기 산술과 실제 sim tick을 대조한다. 보조 clock과 분기 간 입력은 명시 기록한다.
3. `prepare_rejection_preserves_prior_host`. 각 phase 분기에 같은 malformed profile 후보를 `init_game()`에 넣고 `invalid_candidate_profile`, `profile.ally`를 확인한다. 기존 sim과 양 clock의 객체 동일성·시계 필드, fingerprint, VM/렌더러/HUD 객체, 전대 ID와 selection/marker 및 표현 데이터의 기존 값이 유지돼야 한다. 오류 UI는 정본이 의도적으로 만드는 부수효과이므로 별도 검사한다. 전체 UI 무변이를 주장하지 않는다. 후보 없는 대조 인스턴스에 같은 다음 delta를 실행해 실패 분기의 sim·clock·표현 진행을 비교한다. 성공한 새 전장 게시의 clock 초기화는 별도 정상 대조로 두며 이를 운영 복원으로 해석하지 않는다.
4. `clean_teardown_and_exact_gate`. 이전 runner는 화면이 살아 있는 동안 module.sim을 null로 바꿔 draw callback이 nil 참조에 도달할 수 있었다. 개정 fixture는 먼저 자동 처리·그리기 경로를 멈추고 장면을 SceneTree에서 제거한다. 분리 이후 fixture가 소유한 sim의 역참조를 해제하고 노드·autoloader 주입 상태를 정리한다. 종료 진단이 생기면 출처를 분리해 기록하고 통과 처리하지 않는다. 사전 지정된 이름 4개 전체와 raw 로그·실제 exit 0이 필요하다. 의도한 profile 오류 로그만 정확한 수/내용으로 허용하고 SCRIPT ERROR, 예기치 않은 오류·누수·남은 프로세스는 실패다. 실행 직후 입력 SHA 재확인 및 이전 증거 불변 확인을 포함한다.

다른 비-Astra 모델이 구현에 참여하지 않고 계획·최종 5b·별도 마감을 심사한다. 반증 대상은 기존 로그의 0 exit 오인, 최초 상태 차이, 유효하지 않은 renderer 확인, teardown 후 지연 오류, 하위 process와 cache, P02 비간섭이다. 마감 뒤 전용 결과와 checklist·handoff·manifest 및 감사 자료를 남긴다. 전체 P03/I01/I01b/A04~A06 NOT_READY, 외부 스키마 UNCLASSIFIED 유지.
