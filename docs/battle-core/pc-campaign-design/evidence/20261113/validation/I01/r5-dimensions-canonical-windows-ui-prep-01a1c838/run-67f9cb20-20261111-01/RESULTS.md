# P02 복구 배포본 Windows 전경 검증

**통과.** 2026-11-11 15:13:51 KST 첫 실행, 15:27:15 마지막 창 닫기. 전경 실행 및 입력은 약 13분 24초였다. 실제 클릭과 화면 캡처로 정상 출격·저장·동일 및 새 프로세스 재개·C 점령 자연 종료·지도 결산 및 재시작 후 표시를 확인했다. [실제 클릭 기록(UTC)](captures/input-times.jsonl) · [캡처 보관 시각(UTC)](captures/capture-times.jsonl)

F의 제한 배포 worldlink-only/windows-release에서 버전 0.1.0.0을 인수 없이 순차 실행했다. 매번 EXE SHA-256 67f9cb20d10001bd33aa21c5c316bd4bb80aed9df4a2278a29900e2adb9c3924와 같은 폴더 DLL ebd3b5ce05d43bb89dc2d421047a2ca685a246086bd9298af6ad353760fca9d0을 확인했다. 새 격리 APPDATA·LOCALAPPDATA 한 쌍에 세 실행을 순차 연결했다. 세 검증 창을 닫기 버튼으로 종료했고 해당 PID가 모두 종료된 것을 확인했다. [첫 시작 PID 28676](launch-01.json) · [재개 PID 19480](launch-02.json) · [결산 복원 PID 8020](launch-03.json)

| KST | 실제 관측 |
| --- | --- |
| 15:14:07–15:14:43 | 기본 타이틀의 천하 지도 → 적벽으로 → 표준·직접 지휘 첫 작전 · 정면 → Start operation. 전장 진입 시 Tick 0, A·B 중립, C 적군이었다. [타이틀](captures/01-title.jpeg) · [개요](captures/02-blank-profile-first-map.jpeg) · [출격 카드](captures/03-front-standard-direct.jpeg) · [초기 전장](captures/04-front-tick-0.jpeg) |
| 15:14:49–15:15:00 | Save battle 두 번으로 Tick 64(6.4초), Tick 113(11.3초)을 저장했다. 같은 프로세스에서 더 진행된 뒤 Load battle을 눌러 Tick 113 및 Restored at tick 113을 확인했다. 파일 체크섬과 규칙 지문을 검증했고 주 슬롯 113과 백업 64의 작전 ID가 같았다. [첫 저장](captures/05-first-save.jpeg) · [두 번째 저장](captures/06-second-save.jpeg) · [동일 프로세스 복원](captures/07-in-process-restored-113.jpeg) · [저장 파일 대조](checkpoint-readback.json) |
| 15:15:28–15:16:01 | 정상 종료 후 두 번째 PID에서 기본 타이틀 → 천하 지도 → 적벽으로 → 첫 작전 이어하기. Tick 113(11.3초) 복원 뒤 Resume operation을 눌러 Tick 128(12.8초)로 진행했다. 재개 전후 주 슬롯·백업의 SHA-256 및 파일 목록이 같았다. [이어하기 카드](captures/08-map-resume-card.jpeg) · [새 프로세스 복원](captures/09-new-process-restored-113.jpeg) · [재개 뒤 진행](captures/10-resume-running.jpeg) · [재개 전](state-before-resume.json) · [재개 후](state-after-resume.json) |
| 15:16:07–15:25:41 | Move to waypoint 2로 A에 이동했다. Tick 966(96.6초)에 A 활성화를 보고 Move to waypoint 3을 눌렀다. C 교전 후 Tick 5603(560.3초)에 C: ally와 objective_success / objective_conditions_met를 함께 확인했다. 재개 클릭에서 종료 첫 관측까지 실제 약 9분 42초, 최초 Start operation 클릭부터는 11분이었다. [A 활성화](captures/12-a-active.jpeg) · [C 접근](captures/13-move-to-c.jpeg) · [전장 종료](captures/15-c-ally-objective-success-5603.jpeg) |
| 15:25:57–15:26:07 | Return to map으로 형주 지도에 목표 달성 결산이 표시됐다. 카드의 ID, 사유, 560.3초 및 seed 208이 원장과 일치했다. 천하 보기로 개요에 돌아왔다. [첫 지도 결산](captures/16-first-map-settlement.jpeg) · [천하 개요](captures/17-atlas-after-normal-settlement.jpeg) · [재실행 전 원장](settlement-before-reopen.json) |
| 15:26:29–15:27:10 | 정상 종료 뒤 세 번째 PID의 첫 천하 지도에서 동일 결산을 다시 표시했다. 첫 작전 이어하기 클릭은 checkpoint_already_settled로 거부됐고 결과 카드와 지도는 유지됐다. 같은 PID에서 천하 보기 → 타이틀로 → 천하 지도 왕복 후 결산 카드가 다시 열리지 않았다. [새 프로세스 결산](captures/18-new-process-same-settlement.jpeg) · [완료 슬롯 거부](captures/19-completed-slot-rejected.jpeg) · [같은 PID의 지도 재진입](captures/20-same-process-map-no-repeat.jpeg) |

결산 ID는 red-cliffs-first-operation-dev-v1/d27b6189bcb2e62d02d8d947bd7ed987/settlement이다. 결산 전에는 원장이 없었고 이후 단일 기록의 파일·본문 SHA가 재표시와 재개 거부 전후 동일했다. 진행 주 슬롯과 백업의 SHA 및 길이는 재개·결산·재표시 전후 동일했다. 원장 백업은 처음부터 없었고 재표시 뒤에도 생성되지 않았다. [결산 재실행 전 파일](state-before-settlement-reopen.json) · [검증 종료 후 파일](state-after-settlement-reopen.json) · [최종 원장 대조](settlement-after-reopen.json)

실제 종료 범위는 정상 창 닫기 뒤 새 프로세스의 지도 재표시다. 원장 기록 직후 강제 종료 검증은 별도 채팅의 범위다. [엔진 로그 1](process-01-godot.log) · [엔진 로그 2](process-02-godot.log) · [엔진 로그 3](process-03-godot.log)
