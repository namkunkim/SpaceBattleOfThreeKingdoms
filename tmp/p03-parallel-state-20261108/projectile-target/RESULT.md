# P03 미사일 target ID 검증 결과

[attempt-03](attempt-03/suite.json)에서 suite 실제 exit 0. 본시험 Godot 실제 exit 0, 3명명·76 확인. 의도 실패 Godot 실제 exit 1, 실패 marker 1개와 성공 marker 0개. 두 Job 모두 총 2/active 0, SCRIPT ERROR/ERROR/WARNING/ObjectDB 및 리소스 종료 진단 0.

- launch_and_exact_candidate는 미사일 ID 2–7, src 1·target 2, next_event_id 8, launch 사건을 확인했다. 후보는 첫 미사일의 정수 target만 2→999로 바뀌었고 packet 구조 검사를 통과했다.
- positive_rebind는 원본 패킷으로 새 roster/미사일 객체를 만들고 기존 논리 src/target ID를 새 전대 객체로 해석했다. 전체 복원 패킷은 원본과 exact 일치했다.
- atomic_reject_and_advance는 후보를 projectile_reference로 거부하고 기존 sim/state/fleet/missile, warm ID 캐시, ready/busy, packet, queue/log 및 사건을 보존했다. 다음 한 틱에서 age 100ms, 두 걸음 속도 +6/+6, next_event_id 9, 사건 순서가 손계산과 일치했다. 세 전체 패킷도 타입·순서를 포함해 일치했다. 좌표는 세 패킷에서 exact 대조했고 독립 좌표 수치값은 고정하지 않았다.

첫 시도는 nested Missile raw resource_path가 빈 문자열이라 경로 검사 두 건이 실패했다. 두 번째 시도는 변경 기준 독립 수용 전에 시작돼 정식 결과에서 제외한다. 세 번째 시도는 [독립 수용한 guard](REVIEW-GUARD-REVISION.md)의 변경안과 동일 runner SHA256 fba74d68ee04ee73427ca72c01b8145e4859467dd2b17daa2e3e250cb9d11d22로 실행했다. 심사 문서 본문의 runner 해시는 끝에 2가 하나 더 적힌 65자리 표기 오기가 있고, [수용된 변경안](GUARD-REVISION-PROPOSAL.md)과 실제 runner의 64자리 SHA는 일치한다. raw nested path는 초기/복원 후 각각 빈 문자열로 보존했으며 canonical enclosing BattleState의 Missile 상수와 prototype 및 실제 객체 Script의 동일성을 확인했다. [실제 stdout](attempt-03/fixture/stdout.bin)

manifest SHA256 4d6a25031f9c3fd5a88ef57cfc3920814fce99f0628269f73c7be6b6053ac1cf. 승인 계획과 guard 변경안·심사 문서를 포함한 49개 입력 SHA 및 HEAD가 전후 일치했다. Git 상태 차이 8행은 전부 전용 경로이며 외부 동시 경로 차이 0이었다. 전체 dirty 파일 바이트 감사와는 별개다. [manifest](attempt-03/manifest.json) · [Git 상태 비교](attempt-03/git-comparison.json)

K=3 중 3회 사용. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED. src 음성, Swarm, 명중과 제품 발사, 운영 복원은 미검증이다. 독립 사후 5b 대기.
