# 첫 전장 준비 실패 뒤 기존 지도 UI 복원

독립 심사용 설계다. 제품 또는 테스트는 실행하거나 변경하지 않았다.

## 확인한 동작과 범위

WorldMapScreen._finish_sortie는 살아 있는 지도에서만 _sortie_origin으로 즉시 scene 거절을 복구한다. 장면 변경이 성공하면 기존 지도 노드와 이미 표시하던 outcome이 사라진다. FleetBattle3D.init_game이 최초에 실패하면 sim 없이 오류 ExitBattlePrepareError를 표시한다. 현재 이 버튼은 back_to_world(null)로 이동한다. 새 WorldMapScreen._ready는 대기 Outcome이 없으면 z0 browse로 들어간다.

최소 복원 대상은 기존 직접 적벽 출격의 최초 준비 실패다. 출격 전 지도 카드/결과 화면, 선택 난이도·모드 및 기존 결과의 표시 데이터와 영역 색을 복원한다. 일반 전장 나가기, 정상 결과, 자동 해결, standalone 종료 및 활성 전장의 재준비 실패는 각각 기존 경로를 유지한다. 지도 제스처·이동 보간·일시 안내·애니메이션 중간 프레임은 재현 범위에서 제외한다. 카드는 해당 레벨의 안정 화면, 결과는 정착한 결과 화면으로 복원한다.

## 최소 설계

1. **WorldMapScreen.** 기존 출격 전 스냅샷에서 browse 카드 또는 result의 논리 UI 상태를 복사하고 난이도·모드, 유효 레벨, 현재 영역 소유 표시 사본을 더한다. result의 기존 outcome은 기존 to_dict() 사본으로 분리한다. 이 사본은 이미 표시된 UI 데이터이며 WorldLink.outcome으로 재큐잉하지 않는다. direct 분기만 선택적 인계 인자를 넘긴다. 즉시 scene 거절의 기존 동일 노드 복원은 그대로 사용한다. 자동 해결은 인계 상태를 만들지 않는다.
2. **WorldLink.** 기존 호출자는 인계 인자를 생략할 수 있게 하고, 이번 출격의 원본 UI 사본을 메모리에 한 건만 유지한다. go_battle 즉시 거절 때 기존 Brief·대기 Outcome·선택과 인계 상태를 함께 돌려놓는다. 최초 준비 오류의 전용 복귀 경로는 새 map 호출이 OK일 때만 UI 복원 사본을 해당 map에 공개한다. 실패하면 기존 전장·Brief·대기 Outcome·복원 사본을 유지해 같은 버튼으로 재시도할 수 있다. 새 지도는 공개된 사본을 한 번 가져가고 폐기한다. 정상 복귀 승인 시에는 출격 UI 사본을 폐기하며 결과는 기존 대기 Outcome 한 건으로 전달한다. 실패한 일반 복귀의 보존 계약은 유지한다. 공개/소비의 순서는 deferred scene 변경과 map _ready 시점에서 검증한다.
3. **FleetBattle3D.** 최초 준비 오류용 ExitBattlePrepareError의 routed 분기만 전용 복귀를 호출한다. 활성 전장 재준비 오류와 일반 back_to_world는 이 분기에 들어오지 않는다. 사본 없는 기존 fixture는 현재 결과 없는 안전 복귀를 사용한다. _prepare_game/_publish_game/_process/update_sim과 P03 owner/adapter는 이 조각에서 수정할 이유가 없다.
4. **WorldMapScreen 결과 표현.** _show_result의 라벨 작성과 결과 카드 가시화 부분을 작은 표시 함수로 분리한다. 정상 _show_result는 기존 sound.play("decision"), 0.6초 타이머와 소유색 애니메이션을 유지한다. 복원은 표시 부분만 호출하고 결정음·타이머·재계산·대기 Outcome 소비를 실행하지 않는다. 결과의 전환 전 영역 애니메이션이 아직 대기 중이었다면 이전 Outcome에서 기존 규칙으로 정착 표시 색을 산출하고 set_region_owners(..., false)를 적용한다. 이미 정착한 경우도 같은 표시 색이 된다. 이 색은 UI 투영이며 새 결산 또는 영토 효과 커밋이 아니다. 카드 화면은 기존 소유 표시의 사본을 정적으로 복구한다. 같은 판 다시는 복구된 결과의 기존 seed를 그대로 사용한다.

원본 쓰기 후보는 view/world/world_map_screen.gd, scripts/world_link.gd, scripts/FleetBattle3D.gd의 초기 오류 버튼 분기다. BattleBrief/BattleOutcome 데이터 형식과 P03, P05, P07에는 변경이 필요 없다. 신규 저장 스키마를 만들지 않는다.

## 독립 시험 명세 초안

| 행 | 격리 fixture와 조작 | 관측 |
|---|---|---|
| L01 | 정착한 결과 카드, 다른 난이도 선택, 같은 판 다시 → 최초 profile_patch 거절 → 천하로 | 새 지도에 동일 fingerprint·seed·mode·난이도·결과 라벨·결과 소유색과 현재 선택. 신규 결과 생성/큐 소비/결정음/소유색 애니메이션 각 0. UI 인계 소비 1. |
| L02 | L01에서 WorldMap scene 첫 로드만 거절하고 복구 후 같은 버튼 재시도 | 첫 거절 전후 동일 전장과 오류 UI, Brief/Outcome·인계 사본 보존, 안내 표시. 두 번째 승인 뒤 L01 충족. 기존 cache를 숨기는 방식은 쓰지 않고 동결된 격리 fixture와 실제 ResourceLoader 상태를 심사한다. |
| L03 | 지도 카드에서 첫 출격 → 최초 준비 거절 → 귀환 → 정상 출격 | 카드·난이도·direct 선택·가시성·레벨·기존 소유 표시 복원, 결과 없음. 오래된 사본을 새 출격에 사용하지 않음. |
| L04 | 결과 표시 뒤 0.6초 소유색 효과가 아직 시작되기 전에 출격하고 최초 준비 거절 → 귀환 | 정착한 결과 소유색이 즉시 보이고 새 결정음·타이머/애니메이션은 0. 정상 결과 화면의 지연/효과 경로는 별도 L06과 비교. |
| L05 | 출격 scene 즉시 거절 | 기존 지도 인스턴스·카드/결과·선택·대기 Outcome·Brief 유지. 전용 복원 요청 공개 0. |
| L06 | 정상 직접 결과 반환 및 진행 중 정상 지도 반환 | 정상 결과의 신규 Outcome 소비와 효과 각각 1. 진행 중 이탈은 기존 browse. 양쪽에서 오래된 UI 인계 미노출. |
| L07 | 자동 해결, standalone 최초 준비 거절, 활성 전장 재준비 실패 | auto 결과·효과 기존과 동일, standalone은 종료 동작, 활성 실패는 기존 sim/seed/G/두 시계/UI·trace 보존. 지도 인계 생성/소비 0. |

제품 후보/시험이 준비되면 L01–L04의 before/after 예상 red와 각 raw ID를 동결한다. 정적 라벨 비교와 단순 효과 계수는 격리 fixture에서만 계측하고 제품에 시험 seam을 추가하지 않는다. 기존 direct scene reject, return reject/notice 및 D08 증거는 회귀 선택의 근거로 읽되 새 복원 통과로 집계하지 않는다. GUI 물리 입력 및 PC0 재실행은 이 시험 밖이다.

## 공유 파일 경계

읽기 관측 HEAD 0be09755b70378286105972f35ac5b7031715664, index SHA 6980bad4df2570c03e76cd964aec5bb0b71ec5cbdef69f4b022e4df1a2aca57a. FleetBattle3D 0be6a03729a0906b6170169e607c0d26cb08ae046f9e31785c8862f372b10e81, WorldLink 1ae03ec0a07c6636c38201279edb64eaad7e2f5ae604a7fd9b5a80fccbdad440, WorldMap e40f0a99954a11942a9256e260b6c40121cac7051ba4db69f33698bbf82b6ba4. P03 PrivateState 46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3, Adapter 0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a. P03의 bridge 검토는 정적 restore 준비이며 공유 쓰기 창이 없다고 기록한다. 이 값들은 쓰기 예약이 아니다. 실제 후보/적용 전 P03의 최신 상태와 hunk를 다시 조율한다.
