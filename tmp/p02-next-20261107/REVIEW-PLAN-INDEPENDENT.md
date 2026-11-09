# P02 다음 조각 독립 계획 5-b

2026-11-07. 판정: **계획 한정 수용**. 대상 `PLAN.md` SHA256 `868d120de5d6c1de2c66c3bb8268902bde114cfb9948f2cddac9b1c523694c8c`. 이 판정은 구현·제품 WorldMap·전체 P02 완료 판정이 아니다. 심사자는 구현과 계획 작성에 참여하지 않은 `/root/p02_next_review`다. session `01a1b5bf-e9fe-7383-8dc9-aec906ab2995`의 session_meta parent `01a1ac09-125c-71d0-b13b-721727506c85`, agent_path와 turn_context.model `gpt-6.1-terra`를 직접 확인했다.

기존 `AutoResolver`의 main `_prepare`, worker `_loop`, main join 후 `BattleOutcome.from_sim`과 `BattleBrief`/제품 결산, 실제 CLI, adapter의 제한 입력·private owner, `BattleSim.replay`, UI host의 sim/clock/trace 결합을 대조했다. CLI에서 실제 AutoResolver의 opt-in worker를 호출한다는 가치는 제한 실행 경로의 스레드 경계 검증이다. 제품 WorldMap 소비자 연결이나 BattleOutcome 호환의 증거는 아니다. 계획은 이 차이와 기존 legacy를 명시한다.

반증 기준: (1) plain-data 검사와 deep copy가 thread 시작 전에 완료되고 worker만 create/사용/close하는지, 실제 예외와 반환형 오류를 구분하는지; (2) join 전 공개 결과나 mutable owner/sim 참조가 없고 취소 신호만 mutex로 공유하며 join 중 lock을 잡지 않는지; (3) 미게시 완료 취소, 중복 시작, 실패 후 재시작, 반복 poll 사본 및 legacy와의 상호 배제가 실제 상태 전이에서 성립하는지; (4) 입력 바이트 SHA는 실제 파싱한 바이트에 대응하며 출력 기존 파일 보존, 오류 우선순위, sync/legacy bytes가 유지되는지; (5) 동결 fixture의 직접 독립 oracle과 실제 프로세스 exit·로그·순서·타입을 비교하고 실패/timeout/미실증을 숨기지 않는지; (6) 정본과 기존 dirty/untracked 자산의 전수 보존 및 K6 기록이 실제 증거와 일치하는지다.

구현 검토에서 특히 Thread.start 실패 후 이전 완료값과 후보 상태, 종료 직전 cancel과 join, process_frame 중 객체 생명주기, output 오류 시 worker 정리, 기존 입력 옵션의 dispatch 우선순위를 실제 코드와 검증 증거로 확인해야 한다. W1/W2의 사건은 실행 전에 고정한 기대와 실제 관측을 분리하고 관측되지 않은 supply 완료를 성공으로 취급하지 않는다. 시작 전에 취소된 worker는 factory를 호출하지 않을 수 있으므로 “정확히 한 번”은 factory에 도달한 실행에 적용한다. 계획의 반환형 오류 보장은 엔진 예외·강제종료 보장이 아니다. 결과물은 별도 독립 구현 5-b와 마감 심사를 거쳐야 한다.
