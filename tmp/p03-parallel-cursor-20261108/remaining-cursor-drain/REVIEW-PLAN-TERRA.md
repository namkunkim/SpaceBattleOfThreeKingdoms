# P03 잔여 cursor/drain 독립 계획 심사 — 변경 요청

대상 PLAN.md SHA-256 `FEC11FA62DCB7F2725F9E16DEE3EB91E055097A69B540FDCFC15209C262067A9` 확인. 심사자 `/root/remaining_terra`; 구현자와 별개 ID 및 명시 모델 배정은 사용자 인정 근거이며 실제 서빙 모델은 미검증이다. 공유 파일은 읽기만 했고 구현 및 엔진 실행은 하지 않았다.

## 판정: 변경 요청

1. 사전등록 3번의 사건 수기 기대를 분기별로 명시해 달라. 정상 `[stop,move,stop,stop,no_selection]`, 순서 변경 `[stop,move,stop,no_selection,stop]`, 누락 `[stop,move,stop,stop]`이다. 현재 ⑦의 “순서 및 거부 사건 유실 확인”만으로 각 분기에서 무엇을 단언할지와 누락 분기 이외의 거부 보존이 분명하지 않다. say/rejected 선택과 전체 raw 대조는 유지한다.
2. 실행 전 preflight의 실패 처리를 명시해 달라. 실제 실행 파일·canonical resource path·class map의 모든 해석 대상·필요 데이터/설정과 runner의 존재 및 SHA/크기를 실행 전에 확정하고, 누락·해석 실패·불일치 시 엔진 실행 없이 중단하며 기록한다. 종료 후 동일 집합의 누락과 해시 불일치도 실패다. 이것은 “필요 데이터”의 임의 축소나 해시 목록 자체의 변경을 방지한다.
3. 재시도 게이트에서 환경/사용량 제한뿐 아니라 timeout, Job 종료 실패, 입력 해시 불일치, 예상 밖 범위 변경을 코드 K=6 재시도와 구분하고 원인 해소·재심사 전 자동 반복을 금지해 달라. 실행별 원문과 실제 종료 코드, 시작/끝 목록을 보존한다. 기존 동시 작업 및 status 경고는 전체 트리 불변 주장에 쓰지 않는다.

## 확인

- `battle_sim.gd`의 queue는 append, issue와 step은 각 현재 tick을 기록하며 step이 pending을 순서대로 적용한다. `operation_private_state.gd`는 구조 검증 후 detached queue/issue를 수행하고 raw drain은 큐를 소비한다. R은 구조상 허용될 수 있으나 전술상의 no_selection은 별도 사건이다.
- 기존 `command_suffix.gd`의 fixture에서 Q와 S 및 I/R 입력 tick, ids와 point는 서로 구분되며 적용 시 tick 2로 덮인다. P가 이미 보유한 Q를 다시 queue하는 분기는 중복 적용을 실제 실행하는 합당한 대조다. 수신기 Array는 owner 외부의 테스트 수신기만 나타내며 실제 host ack나 지속성은 입증하지 않는다.
- 4개 이름 × 8 Boolean은 32개로 일치한다. 조건 묶음은 실패 시 분기와 세부 조건을 식별할 수 있도록 출력해야 한다. 닫기 성공과 재드레인은 각 항목에 포함되어 있다. 새 restore 분기마다 P 정확 비교 및 각 raw 분기별 독립 접수 순서를 요구하는 점은 적절하다.
- 별도 raw BattleSim과 수기 리터럴을 함께 요구하는 oracle 구조 및 미검증 범위 표기는 적절하다. 원문 로그, 동결 목록과 입력 전후 값, 분모를 독립 5-b에서 다시 대조해야 한다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED 유지.
