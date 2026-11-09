# P03 같은 틱 명령 절단점 결과

2026-11-08 KST. 제한 private owner를 실제 전진·복원한 뒤 같은 suffix를 다시 적용했다. 틱 2에서 대기 중인 Q/Q/S와 이미 적용된 I를 구분했고, 같은 틱의 후속 B와 논리 거부 R이 기록되는 순서를 확인했다. 독립 raw BattleSim과 수기 기대값을 함께 비교했다. 동일 Q 두 호출은 둘 다 적용됐고, restore 후에는 packet이 보유한 Q/Q/S를 재주입하지 않았다. [독립 5-b](REVIEW-5B-attempt-05.md)

| K6 시도 | 실제 결과 |
|---|---|
| 01 | Godot exit0, 6명명·91 단언. 엔진 console만 동결하고 실제 본체가 빠져 독립 5-b 반려 |
| 02 | Godot exit0, 6명명·91 단언. console/본체·PID를 확인했다. timeout 시 자식이 로그 pipe를 보유할 경우 회수 제한을 보장하지 못해 5-b 보류 |
| 03 | 실제 timeout. taskkill exit1, 8.35초에 launcher·본체 종료를 확인하지 못했다. 이후 별도 조회에서 두 PID가 사라졌다 |
| 04 | 3초 제한의 실제 probe, launcher exit124, gate exit1. 별도 probe PASS. 전용 Job 2개·active 0과 두 PID의 종료를 약 3.19초에 확인 |
| 05 | 정본 정상. Godot actual exit0, 6명명·91 단언, context 거부 4·구조 거부 2. SCRIPT ERROR/ERROR/WARNING 및 종료 누수 진단 0 |

04/05 각각 실제 사용한 엔진 console과 본체, 정본 class map, 프로젝트·소스·데이터·runner를 포함한 51개 입력이 전후 동일했다. 새 전용 Windows Job의 범위는 각 실행이 시작한 launcher와 본체다. 이 probe는 해당 Windows 환경에서 실제 타임아웃 종료를 검증했다. 다른 OS 장애·전체 실패를 검증하지 않았다. [04 원문](attempt-04/run.json) · [05 원문](attempt-05/run.json)

2026-11-07 사용량 제한으로 독립 5-b 뒤 기록 마감이 중단됐다. 11-08에 기존 실행을 재시도하지 않고 보존과 전달 기록을 재개했다. 시작 분모 5162 재해시는 누락0 및 P02 경로 변경4다. 감사 중 status 변동이 있어 원자 스냅샷으로 취급하지 않는다. P02 viewer-events 변경으로 04/05의 당시 소스 51개 중 현재 owner 한 파일이 다르다. P02 격리 전후 원문에서 당시 `dd47ceeb…a427`과 현재 `c5550999…9a6e`를 각각 재확인했다. 이 결과는 11-07 동결 입력의 역사 실행이고 변경된 현재 owner의 재검증이 아니다. 전체 diff-check는 기존 P2c 체크리스트 33행의 후행 공백으로 actual exit2다. [보존 감사](preservation.json) · [P02 결과](../../docs/battle-core/pc-campaign-design/P02-VIEWER-EVENTS-RESULT-20261108.md)

전체 P03/I01/I01b/A04~A06은 NOT_READY, O07은 OPEN, 외부 저장 스키마는 UNCLASSIFIED다. 전역 cursor/commit, 운영 Cn 전수, 호스트/worker 실패 원자성, 외부 사건 exactly-once 및 모든 활성 모듈은 별도 인수다.
