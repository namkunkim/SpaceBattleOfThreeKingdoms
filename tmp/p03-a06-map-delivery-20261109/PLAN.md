# A06 천하 지도 표시 완료 경계 시험 계획

2026-11-09 KST. P03 전용 headless 관측이다. 기준 HEAD `0be09755b70378286105972f35ac5b7031715664`. 기존 하위 채팅 중지는 조율자가 확인했다. 계획 독립 수용 이후에만 runner 작성 및 실행한다.

## 범위와 근거

`WorldLink.take_outcome()`은 DTO 반환 전 슬롯을 비운다(`scripts/world_link.gd:32`). `WorldMapScreen._ready()`는 프레임을 기다린 뒤 DTO를 꺼내 `_show_result()`로 전달한다(`view/world/world_map_screen.gd:98`). 결과 UI는 즉시 게시하고, 0.6초 타이머는 여전히 result 상태일 때만 지도 영역 색의 권위 상태인 `canvas.owners_rgn`을 바꾼다(`world_map_screen.gd:622`, `world_canvas.gd:151`). 실제 화면 픽셀이나 애니메이션 완료 대신 canvas 상태를 관측한다. 기존 `tests/world_link.gd:252`는 정상 복귀·슬롯 소진·RGN-02 변화의 성공 대조이며, 신규 시험은 그 사이에 정상 결과 버튼으로 이탈하고 슬롯을 다시 소비하는 차이를 검증한다. 기존 A06 가상 수신기 결과는 별도 증거다.

## 5a 사전등록

공용 소스 변경 없이 전용 SceneTree runner에서 실제 `res://scenes/WorldMap.tscn` 및 project autoload `/root/WorldLink`를 사용한다. `BattleOutcome`은 기존 fixture에서 검증한 승리 종류 및 고유 seed를 가진 테스트 DTO로 주입한다. 실제 전투 실행을 집계하지 않는다. 로드한 scene·autoload의 canonical resource_path를 검사한다. 완료 조건은 이름 순서 고정 및 전체 3개 사례, 15개 단언, actual exit 0이다. 상황별 timeout을 두고 필수 guard가 실패하면 성공 표식을 출력하지 않는다.

1. `normal_map_effect` (5). 결과 장면에서 (a) result 상태·카드 visible (b) 결과 DTO seed 일치 (c) slot null (d) 즉시 RGN-02 값이 원래 소유 (e) 0.7초 후 RGN-02 값이 승리 결과 소유. 초기·목표 소유의 차이는 world JSON 원문으로 계획 승인 전에 확인한다.
2. `early_result_exit` (6). 별도 fresh 장면에 동등 DTO를 넣고 (a) result 상태 (b) slot null (c) 이탈 전 원래 소유. result 상태를 처음 관측한 직후 정상 결과 버튼의 pressed 신호로 이탈한다. (d) browse 상태 (e) 결과 카드 비표시 (f) 0.7초 뒤에도 원래 소유. 정상 대조의 승리 소유 변경이 없었음을 확인한다.
3. `reentry_after_slot_consumed` (4). 이탈 장면을 해제하고 DTO를 재주입하지 않은 채 지도 장면을 다시 열어 (a) browse (b) 화면 outcome 없음 (c) WorldLink slot null (d) RGN-02 원래 소유를 확인한다.

재실행의 의미는 지도 장면 재진입이다. 패킷 재전달, 실제 권위 있는 지급 완료, ACK, durable commit 또는 재시도 보장은 검증 범위 밖이다. 종료 후 전용 폴더에 명령, stdout/stderr, 실제 종료 코드, 시도별 보고를 남긴다. 재시도 상한 K3, 첫 실패 로그 보존. 승인 후 관련 scene·코드·world 원문, Godot 본체와 console·클래스 맵·runner SHA를 동결하고 실행 전후 비교한다. 별도 Godot user data 및 출력 경로를 쓰고 기존 정본 클래스 등록을 확인한다. editor import와 P02 공용 소스·테스트 변경은 하지 않는다. 런타임과 별도로 `SCRIPT ERROR`, `ERROR`, 기존 종료 진단을 구분한다. 5b는 비참여 다른 비-Astra 모델로 실제 로그와 canonical 입력·통제된 DTO·성공/조기 이탈·재진입을 대조한다. 결과·인계·manifest·독립 마감을 전용 폴더에 기록한다. P03 전체와 운영 A06은 NOT_READY, 외부 저장 스키마는 UNCLASSIFIED.
