# BGM 누수 다음 진단 — 단일 실제 호스트의 종료 경계

최소 load-only와 실제 재생은 같은 6개 사본 입력과 같은 Godot 4.7.2 Dummy driver에서 각각 별도 프로세스에 실행했다. 둘 다 실제 exit 0, 진단 0, Job active 0, 원본 22개/사본 6개/HEAD·index·status 전후 일치였다. play 분기는 12개 SceneTree frame 뒤 playing 및 has_stream_playback이 참이고 위치도 0보다 컸다. 이 환경에서 단일 플레이어가 12프레임 재생하고 해제되는 것만으로는 누수를 재현하지 못했다. 엔진 책임이나 제품 정상 종료를 확정하지 않는다.

이전 BGM 포함 호스트 04/05는 4개 FleetBattle3D 인스턴스와 정상 새 전장 게시·오류 후 재준비를 같은 동기 실행 구간에 두었다. `battle._process(.05)`의 수동 호출과 실제 SceneTree process_frame은 다르다. attempt-05는 stop/stream 분리 후 바로 tree에서 제거하고 free했으며, 마지막 장면 해제 뒤 250ms를 기다렸다. 최소 플레이어는 실제 12프레임 동안 tree에 부착한 채 재생한 뒤 stop/clear 및 queue_free를 거쳤다. 자원과 엔진은 같지만 호출 수, UI, 믹서 처리 시점과 해제 방식이 다르다.

## 다음 대조에 대한 독립 사전 심사 요청

**단일 호스트 진단**을 우선한다. 실제 production 스크립트와 BGM·import·캐시가 모두 있는 격리 프로젝트에서 `FleetBattle3D.tscn`을 한 번만 instantiate한다. 이전 호스트 fixture와 같은 WorldLink brief seed, play 입력, 수동 _process(.05)와 presentation 수동 갱신을 적용한다. malformed 후보와 정상 재게시·추가 인스턴스는 호출하지 않는다. production src 캐시와 런타임 canonical identity를 전후 확인한다.

UiSound player의 stream resource_path와 Ogg type, `playing`, `has_stream_playback()`를 실제 출력한다. 실제 SceneTree 대기를 넣기 전 이전 05의 동기 teardown 순서인 process disable, 연결 해제, stop/stream=null, tree 제거·free, sim 역참조 해제를 사용한다. 이후 250ms 대기를 거쳐 예상 진단 이외의 SCRIPT ERROR, 남은 프로세스, 시간 초과가 없는지 확인한다. Job active 0과 실제 exit 0, 식별 가능한 engine 본체 PID/path, 원본·복제 입력 SHA 전후 일치를 요구한다. verbose의 Ogg 네 객체·두 자원 종료 진단이 모두 정확히 일치하면 누수 재현으로, 진단이 없으면 단일 호스트에서 미재현으로 기록한다. 엔진 exit 0만으로 제품 PASS를 판단하지 않는다. BGM이 실제 시작하지 않았거나 예상과 다른 누수·오류면 시험 실패다.

단일 호스트에서 정확히 재현하면 **같은 소스·시드·단일 호스트 runner의 ordered 모드**를 별도 프로세스로 한 번 대조한다. 종료 직전 process disable, finished 연결 해제, stop까지 legacy와 같게 한 뒤, tree에 계속 부착된 상태로 실제 `process_frame` 12회 및 250ms를 먼저 기다린다. 이 동안 시뮬레이션 tick과 주 clock이 전진하지 않았는지 확인한다. 이후 stream clear와 tree 제거·free, 모듈 역참조 해제 및 기존과 같은 종료 전 250ms 대기를 실행한다. raw 순서·프레임 수·player attached·playback/stream 상태를 기록한다. legacy와 비교해 실질적으로 변경하는 것은 stop과 clear 사이의 실제 tree 대기뿐이다. 양쪽 엔진/driver·소스·사본·입력 SHA와 종료 조건이 일치해야 하며, ordered에서 누수가 사라지면 해당 격리 종료 순서에 한정한 회피 증거로 판정한다. 둘 모두 깨끗한 경우에도 이전 다중 호스트 누수의 수정 증거가 아니다.

단일 호스트에서 미재현이면 ordered를 실행하지 않고 반복 장면 또는 재게시로 분모를 줄여 두 번째 대조를 별도 제출한다. 수정 hunk와 회귀를 확정하기 전에 정본 재현이 선행되어야 한다. K6 중 이전 2회 사용/4회 잔여이며, 이 계획의 초기 단일 호스트 진단 1회와 정확 재현 때만 후속 대조 1회를 승인 요청한다. 이전 2회는 보존한다.

격리 증거와 fixture는 `tmp/p03-inchat-host-bgm/`만 작성한다. shared 코드, P02 파일, 원본 캐시·음악은 변경하지 않는다. 후보가 host 정상 종료에만 필요하다고 판명되면 P02 소유·실행 창 확인 후 정확한 hunk를 별도 심사한다. 이번 진단은 기존 K6이나 전체 운영 복원·제품 audio 인수를 다시 열지 않는다.
