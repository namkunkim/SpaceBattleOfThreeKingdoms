# C1 되감기 독립 5b

판정: **PASS — 동결된 현재 입력의 제한 메모리 owner 한 사례**. 보존 runner와 기록을 검독했으며 독립 재실행은 하지 않았다.

- 본시험 실제 exit 0, 3명명·87확인·실패 0, 의도된 타입 실패 exit 1 및 marker를 확인했다. 두 Job active 0, timeout·진단 0이며 stderr가 비었다. 초기 및 복원 후 canonical BattleState의 Missile 상수와 실제 Script identity는 true, 중첩 raw path는 빈 값으로 보존됐다.
- runner는 age 100·tick 1 및 즉시 move 적용 직후 P, stop과 한 전진 후 Q, 같은 owner에서 P 복원 시 새 sim/state/fleet/missile과 논리 참조, 동일 suffix 후 Q exact를 확인한다. tick·clock·AI·event ID, log/사건 순서·미사일 age/속도 및 P/Q 보존은 수기 기대값과 비교한다. 좌표는 독립 수기 수치가 아닌 경로 간 exact 비교다.
- manifest SHA `5c609e8c4f4522ead8d2da22ddac67cbf102fe13b282183f7527b5eacbc6fbbe`, 전후 목록 및 현재 49개 입력 SHA가 일치한다. 실행 HEAD는 `0be09755b70378286105972f35ac5b7031715664`이며 Git 상태 변화 8행은 전용 경로다. 전체 dirty/무시 파일 바이트 불변을 보증하지 않는다.
- 이전 상태 세션의 `source-freeze.json`과 이번 manifest의 공통 32개 파일 중 `core/battle/operation_private_state.gd` SHA가 다르다. HEAD도 과거 `fb660...`와 다르므로 과거 fixture가 동일 바이트의 owner에서 실행됐다고 추정하지 않는다. 이번 판정은 이번에 동결된 실제 입력의 결과다.

운영 rewind 허용·오염/과거 packet 정책, 제품 UI, 외부 ack·idempotency 및 저장은 미검증이다. P03 NOT_READY 등 기존 상태를 유지한다.
