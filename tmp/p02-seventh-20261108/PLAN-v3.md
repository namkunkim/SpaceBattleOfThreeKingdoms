# P02 일곱째 조각 개정 계획 v3 — strict trace 보강 및 실제 입력 판정

PLAN-v2.md의 부속 개정이다. v2의 제품 범위·원본 계획·기존 5-a 분모·실행 원문과 실패 판정을 보존한다. 변경된 인수 기준은 독립 검토 후 적용한다.

## Strict trace 판정

common 8개 trace 중 strict 7개 일치, 비라우팅 fallback 시작 1개 불일치다. 원문 차이는 단독 session_start의 seed 298773128 → 3394180763이다. 기존 _ready의 randomize()를 거친 standalone 시작이므로 프로세스 간 같은 seed를 제공하지 않는다. 이 행은 계속 strict 불일치이며 기존 8/8, startup 동등성 또는 전체 동등성으로 집계하지 않는다. wall_time과 mono_ms 이외에 비교에서 빼는 필드는 없다. control/pos 변조 거절 self-check를 유지한다.

보강 행은 각 동결 before/after 프로젝트에서 동일 실제 FleetBattle3D 제품, 동일 fallback 프로필 입력 및 동일 초기 조건을 사용한다. _ready 이후 동일 고정 seed를 설정하고 실제 init_game을 한 번 호출해 생성된 단일 session_start 원문을 비교한다. 제품에 seed 주입 API를 추가하거나 시동 경로를 변경하지 않는다. 기존 시동 trace와 보강 trace는 출력 파일, 비교 결과 및 분모에서 구분한다. 실제 seed, fallback 진단, start 행 수/seq, profile 및 적용 roster의 동일성과 trace 전체 행 일치를 확인한다. 동결 엔진 wrapper/본체, class cache 및 프로젝트 입력 SHA, 사전·사후 각 원문과 명령·exit를 보존한다. 동일 입력에서 init_game trace 내용이 보존되는지의 보강 근거이며, randomize를 포함한 최초 자동 진입의 일치를 증명하지 않는다. 보강이 실패하면 관련 인수 보류. 기존 실패를 수용 범위에서 어떻게 다룰지는 독립 5-b 판정에 남긴다. K=6 한도에서 시도와 프로세스를 각각 기록한다.

## 실제 GUI 및 atomic 증거의 대응

gui-after-02-buttons-v1의 03 확정·출격, 04 브리핑 자동, 05 편성 복구 열기, 06 결과 화면 다시 출격, 07 타이틀로, 08 legacy 처음부터는 각자의 제품 버튼 경로/좌표·visible/enabled, OS 포인터 입력, 실제 callback, 경고와 여섯 동기 상태 필드(sim identity, tick, org, G.state, selected, events)를 확인한다. 현재 probe는 fixture 준비 중 host process를 멈춘 상태이며 여섯 필드 관측만으로 전체 원자성이나 플레이 중 시간 경과를 주장하지 않는다. 광범위 atomic은 별도 탐침의 직접 init_game 두 오류, deck begin 변경/비브리핑·restart·타이틀, org 복구·자동, legacy restart/최초 ready, 복구 publish 행에서 확인한다. 예를 들어 03 GUI 확정은 atomic의 변경 편성 begin과 하류 동작을 공유하지만 실제 클릭에 모든 546단언을 적용한 것은 아니다. 05 GUI의 repair_errors>0과 atomic의 복구 경로, 04/06/07/08의 각 대응 제품 호출도 같은 한계를 둔다. 01/02/09/12 직접 API·정상 대조는 GUI 버튼 분모에서 분리하고 10/11 각각 실제 GUI 마우스·키보드 및 결과를 별도로 심사한다.

클릭은 ready 행 이후 대상 rect 안의 실제 버튼 입력과 그 뒤 같은 lane의 pressed 경로·실패 표시를 연결한다. 05 준비 뒤 대상 rect 밖의 두 클릭은 x≈1066, x≈1077이며 대상 rect는 x=1166..1366이다. x≈1265 클릭이 실제 대상 좌표다. 두 off-target 행은 보존하고 대상 성공 분모에서 제외하며 사용자 입력 주체를 추정하지 않는다. 03에도 대상 밖 x≈1294 입력이 있었으므로 동일 기준을 적용한다. 다른 컨트롤 작동이나 상태 오염 가능성을 초기/최종 상태 및 원문 진단으로 대조하고 인과가 모호한 행은 격리 재실행 전까지 보류한다. 초기 routed 키보드의 앞선 사용자 입력 교차 실행은 마우스로 복귀했으므로 키보드 성공 분모에서 제외한다. routed-key-v2 등 후속 실행도 실제 대상 포커스와 Return, 실제 WorldMap 전환 및 brief/outcome null을 연결해서 판정한다. standalone은 실제 exit를 확인한다. 합성 pressed/직접 호출은 실제 GUI 성공으로 집계하지 않는다.

전체 P02 NOT_READY, 외부 save schema UNCLASSIFIED. 제품 코드 변경은 이 개정에 포함하지 않는다.
