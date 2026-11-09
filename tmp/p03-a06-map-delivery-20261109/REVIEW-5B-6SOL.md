# A06 지도 표시 5b 독립 검토 — GPT-6 Sol

판정: **사전등록한 지도 표시 경계 시험 수용**. 기존 구현 및 시험 작성에 참여하지 않았고 공유 코드·원본 증거를 수정하지 않았다.

## 원본 대조

- 승인 `PLAN.md` SHA-256은 `9b3f07115814f7851fd78e369274bb81dffe8e92a60b80de744b4b061e388dd3`로 `REVIEW-PLAN.md` 및 gate 상수와 일치한다. `MANIFEST.json`, `attempt-01/input-before.json`, `input-after.json`의 HEAD·파일 경로·SHA-256·크기가 동일하며 99개 입력이다. runner SHA-256은 `0d1716b23ad7177b5706d0ea825511d028c8a8991c9017864e0c37783c87dcd5`로 manifest와 일치한다. 해당 동결 범위 밖 전체 Git 상태는 감사하지 않았다.
- `command.json`은 전용 user base의 Godot console headless 호출을 담는다. `run.json`이 `subprocess` 본체 종료 코드 0, timeout false, launcher PID 29140, 본체 PID 19760, 본체 경로 `Godot_v4.7.2-stable_win64.exe`, 격리 user_dir, job 총 2·잔여 0·종료 0, 진단 각 0을 기록한다. stdout 원문과 godot.log에는 동일한 단일 `P03_MAP_PASS` payload가 있고 stderr는 비어 있다. 보고 payload는 stdout JSON과 같다. 별도 shell `.exit` 파일은 없으며 종료 코드 0의 직접 기록은 `run.json`의 `proc.returncode`다.
- `RECORD-MANIFEST.json`의 16개 보존 출력은 각 경로의 현재 크기와 SHA-256에 모두 일치한다. 이 목록은 독립 검토 문서 작성 전의 실행 묶음을 고정한 것이며 본 검토 문서 자체는 포함하지 않는다.
- 정본 guard는 runner가 `res://scenes/WorldMap.tscn`, `/root/WorldLink`, screen·canvas script `resource_path` 및 world 경로·매핑을 확인한 뒤 사례를 진행한다. `project.godot`의 WorldLink autoload, WorldMap의 `take_outcome()`·`_show_result()`, 결과 버튼의 `_result_to_world` 연결, `world_208.json`의 `alliance_win`→RGN-02 `wu`, 초기 `contested`를 원문과 대조했다. DTO 두 개는 같은 seed 777 및 전체 `to_dict()` 일치 조건을 만족해야 계속 진행한다.
- `map_delivery.gd`에는 사례별 `_check`가 5/6/4개로 총 15개다. stdout 사례 순서는 `normal_map_effect`, `early_result_exit`, `reentry_after_slot_consumed`이고 failures는 빈 배열이다. 정상은 `contested`→`wu`, 조기 이탈은 `contested` 유지, 재진입은 browse·outcome 없음·slot null·`contested`다.
- 조기 사례의 시간은 open 2353ms, result 관측 2478ms, 연결된 `천하 보기` 버튼 신호 2484ms다. 관측 후 6ms, open 후 131ms이므로 원문의 0.6초 timer 전이다. runner는 버튼 신호 후 같은 SceneTree의 `create_timer(0.7).timeout`과 다음 프레임을 기다린 뒤 3068ms에 소유를 확인했다. 벽시계 tick 차이는 584ms이지만 Godot timer의 경과는 `await`로 직접 확인된다. 원문의 0.6초 timer 역시 같은 기본 SceneTree timer이므로 0.7초 대기 후의 상태 검사로서 타당하다.

이 시험은 정상 유지 시 지도 소유 반영, 조기 버튼 이탈 시 결과 슬롯 소비와 지도 소유 미반영, DTO 재주입 없는 재진입의 초기 상태를 입증한다. 실행은 K3 중 1회다. 운영 A06 수용, 픽셀·애니메이션 완료, 내구 저장·ACK·재전달은 주장하지 않는다.
