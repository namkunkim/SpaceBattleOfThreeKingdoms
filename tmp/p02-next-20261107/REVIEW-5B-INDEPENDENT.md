# P02 worker 구현 독립 5-b

2026-11-07. **제한 CLI→AutoResolver worker 구현 한정 수용.** 계획 범위의 차단 반례를 발견하지 못했다. 문서·전달물 마감은 아직 심사하지 않았다. 전체 P02/I01/I01b/A04~A06는 NOT_READY, 외부 save schema UNCLASSIFIED다. 제품 WorldMap operation·BattleOutcome, UI host, replay 및 전체 K01~08을 수용한 것이 아니다.

심사 `/root/p02_next_review`, session `01a1b5bf-e9fe-7383-8dc9-aec906ab2995`, 실제 `gpt-6.1-terra`. 구현 `/root/p02_next_impl`, session `01a1b5c4-0cb0-75c3-8287-d0c2646f51f7`, 실제 `gpt-6.1-sol`. 양쪽의 동일 parent `01a1ac09-125c-71d0-b13b-721727506c85`와 agent_path는 session_meta, model은 turn_context에서 직접 확인했다. 심사자는 코드 구현에 참여하지 않았다.

- 실제 source와 owned diff를 검토했다. 메인에서 plain data 검사·deep-copy 후 thread를 시작하고 worker가 제한 factory 생성·advance/drain·close한다. 결과는 is_alive false 후 join하여 복제 공개한다. mutex는 취소 비트만 보호하며 join에서 잡지 않는다. 완료 전 cancel은 join 결과를 폐기한다. 기존 legacy sim과 결과 경로는 별도로 유지하며 서로 join 전 busy/guard다. CLI는 입력 bytes를 한 번 읽고 그 bytes의 SHA를 저장하며 출력 전 경로를 두 번 검사한다. owner 생성 이후 지원밖 정책/controls/ticks 거부도 close한다. 예외·강제종료·OS writer 경합 및 disk fault 주입은 이 보장의 밖이다.
- attempt3 결과 SHA `1078e7b1797e76deb4c00d2fa31c3e92368b605ca9a72e8a406b76867028dad8`. 기록된 실제 프로세스 53개는 exit0 19, exit1 34로 기대에 일치했다. 각 원문 stdout/stderr/engine log SHA와 기록을 재대조했다. 독립 native BattleSim oracle에 대한 API 59 checks, 자연종료 POC/services 및 timeout tick1/clock100/sentinel, cancel·중복·사본 분리 및 3 worker/sync 결과 일치를 확인했다. 서비스 관측은 contact/salvo/ship_lost/battle_end이며 supply 완료 증거가 아니다. 기존 sync POC/services와 통계 JSON의 전후 바이트, WorldLink 결산의 전후 일치를 확인했다. WorldLink 전후는 각 exit0/WORLD_LINK_PASS이지만 기존 종료 진단 154 ObjectDB/20 resources가 있고 stock은 150/18이다. 이 진단을 0으로 기록하면 안 된다.
- attempt1은 API parse 실패 exit1, attempt2는 잘못된 modules 기대와 WorldLink timeout, 동결 입력 변동으로 비정본이다. attempt3의 동결 412개 입력과 구현 manifest 537개 기록을 현재 bytes/SHA로 재검증하여 불일치 0이었다. manifest SHA `d04bd9538021309fe6eb537ea907edf8e33652bd20b3ed9d5d482a7fcec2de11`. cache SHA `0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1`이다.
- baseline 7078개 독립 재해시: 7073개 동일, 변경 5개는 이번 코드 2개와 병행 P03 파일 3개이며 누락 0이다. P03 3개를 이번 작업의 보존 성공으로 취급하지 않는다. 사전 원문 및 역diff 기록을 확인했고 기존 전체 diff-check는 33행 진단으로 실패, 소유 diff는 clean이라는 실행 기록이다. 추후 문서·압축을 만들면 그 시점 별도 보존·manifest·ZIP 심사가 필요하다.

Thread.start OS 실패 주입, 엔진 예외 복구, 동시 writer, 디스크 쓰기 장애, 제품 화면·Android·성능과 진행값 공개는 검증하지 않았다. 해당 API 호출자는 poll 또는 cancel로 join을 완료해야 한다. 이 판정은 배포·커밋·병합 승인이 아니다.
