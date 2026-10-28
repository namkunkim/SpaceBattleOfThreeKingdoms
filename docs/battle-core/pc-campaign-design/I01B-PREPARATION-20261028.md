# I01b-P0 준비 계약과 소스 재고

2026-10-28 KST / **P0 자동 재고 검사 통과 · 독립 5-b 수용**. [독립 검토](REVIEW-I01B-P0-20261028.md)는 수정된 ST 추적표와 원문·정상/음성 증거를 수용했다. 도구·문서는 아직 staging이며 target 배치와 체크리스트 반영은 미완료다. 전체 I01/I01b 및 원 A04/A05/A06는 NOT_READY다. 준비 재고가 실제 저장·재생이나 제품 공간 검사를 대체하지 않는다.

## 1. 재사용하는 결정과 현재 기준

[H0](H0-DECISION.md)·[H1](H1-DECISION.md)·[H2](H2-DECISION.md)의 확정 방향은 유지한다. 단일 성계 연속작전·보급로 개방·정면/우회·시간 증원, 약20분 비교 방향, 상태+후속명령·동일 규칙 버전 재개와 관람/논리재생 구분을 다시 질문하지 않는다. **20분·지도 치수/속도·회복 비율/시한·전체 동시 순서·저장 스키마는 확정 수치가 아니다.** [시간/공간 D03](D03-SPACE-TIME.md), [상태 D04](D04-STATE.md), [기존 K01~K08/S01~S15](I01-READINESS-DECISION-20261026.md), [원 A04~A06 인수](I01-ACCEPTANCE-PREREG-20261026.md)를 재사용하며 새 계약으로 덮어쓰지 않는다.

관측 HEAD는 `8292805143f4561a4f5258d40b7b94adf4ff5802`다. 직전 기준선 수정의 코드3+문서3 SHA를 검사 전 동결하고 그대로 보존했다. 체크리스트에 이번 결과를 추가하는 변경만 후속 허용 hunk로 분리한다. 원프로젝트 dirty14개와 PC 실험의 소유/통합 상태는 새로 확정하지 않았다. 기존 공유 변경을 가져오지 않고 관리 작업트리의 현재 파일만 조사했다. 커밋·푸시하지 않는다.

## 2. 이번에 채운 입력과 남은 의존성

| 기존 계약 | 이번에 채운 실제 입력 | 여전히 필요한 것 |
|---|---|---|
| S01/S14·ST01 정의/규칙 | BattleSim/RuleSet/RNG 소스·선언과 source SHA, 현재 프로필 참조 경로 | 전체 정규형·규칙 내용 호환·snapshot 헤더의 실행 검증 |
| S02/S04/S05·ST02 시계/ID | BattleState의 tick/clock_ms/next_id/next_event_id, BattleSim의 sub_ms와 실제 하위걸음/양자화 위치 | 실제 부분 걸음 tick2/clock150 검증, 신규 commit_seq/command_seq 정책과 운영 복원 |
| S03·ST02/ST18 명령 커서 | command_log/_queue/_events 및 issue 즉시적용·queue 대기·step 소비의 정확 소스 앵커 | 적용/대기/suffix 원자 커밋과 중복/유실 반례; 기존 로그를 seq 커서로 간주하지 않음 |
| S06~S09·ST03~07 함대/전투 | FleetState 121개 선언 및 사기/지휘/강습/특기 모듈 선언 | Dictionary 내부 스키마·단위·참조·저장/파생 재구성 정책과 활성 runtime 값 |
| S10/S11·ST14 탐지/ST11 보급/ST13 AI·결정/ST08 공격 | 탐지/보급/AI/결정 모듈, Missile 10개·Swarm 8개 선언 | 진행중 공격·접촉·효과 참조와 모든 모듈의 restore·후속 일치 |
| S12·ST09~18 작전 확장 | 탐지·보급·AI 등의 기존 기반 선언은 있으나, 신규 작전 확장 슬롯은 미구현이라는 경계 | 시설/자원/임무/물류/원장 실제 상태, owner_epoch·서비스/일정 정책과 원자 커밋 |
| S13/S15 종료/진단 | 종료 관련 소스와 TickClock 4개 선언 관측 | 진단과 권위 snapshot 필드 분리 검증; 선언만으로 저장 제외를 확정하지 않음 |
| 원 A04 제품 공간 | 기존 FX-G/제품 구분과 product F12 입력 목록 재사용 | 실제 논리 선체 외곽·최대 편성/전환 swept envelope·그룹/서비스/출입 영역. 렌더 표시점으로 대체하지 않음 |

이 재고는 **클래스 선언 목록**이며 전체 O07 필드 사전이 아니다. 타입 표기·초기식은 원문 줄을 그대로 보존했고 초기식을 실행하거나 runtime 기본값·단위·저장 정책으로 추론하지 않았다. 모든 선언의 save_policy는 UNCLASSIFIED다. 함수 local은 제외했고 BattleState의 두 중첩 클래스만 구분한다. 멀티라인 초기식은 첫 선언 줄만 관측하며 동적 Dictionary 내용·엔진 native 상태는 범위 밖이다.

## 3. 재현 도구와 5-a

`tools/scenario/audit_i01b_contract.ps1 -SourceRoot <작업트리> -FreezePath <고정 source-freeze.json> -OutputPath <새 inventory.json>`는 지정한 현재 소스만 읽는다. BattleSim이 참조하는 상태·config·모듈에 RuleSet/RNG/POC AI를 포함한 19개 모듈을 조사하고, 호스트/fingerprint는 소스 앵커로만 읽는다. 독립 freeze의 21소스 SHA가 먼저 일치해야 출력하며 지원하지 않는 선언을 발견하면 명시 보고/실패한다. 범용 GDScript 파서·save serializer가 아니다.

증거는 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01b-p0-20261028-state-inventory`에 있다.

- 정상 child PowerShell exit0: **19모듈·283선언·14앵커·미지원0**. 원문 행 283개를 대조했고 Missile10/Swarm8을 분리했다.
- 독립 source-freeze SHA-256 `423fd845aabf984f977de6da6c204e234a471cdc9844cedd4b084cf8fdcfac55`, inventory SHA-256 `c2500ca2d61b8b08b37c00d36db29684c0cc67f90447b9179f80da1484be30e1`.
- 21파일을 tmp 복제한 뒤 BattleState 복제본만 변조: child exit1 `SOURCE_HASH_MISMATCH core/battle/battle_state.gd`, 출력 없음. 생산 소스·독립 freeze·기존6파일 SHA·HEAD는 불변이다.
- `source-freeze.json`, `inventory.json`, `verify-p0.ps1`, `test-results.json`, `logs/normal.log`, `logs/hash-negative.log`에 원자료를 보존한다. 첫 verify의 `git -C`는 sandbox 읽기 거부로 중단됐고 정식 권한 재실행이 exit0이었다. 자동 재고 검사는 실제 Godot runtime/저장 검사가 아니다.

## 4. 다음 실행 가능한 조각과 완료 경계

**P1은 착수 가능하다:** 새 회귀 runner 하나로 실제 BattleSim.step/_tick/_substep와 TickClock을 호출해 종료 하위걸음 clock150을 검증한다. 시험용 subclass는 실제 super._substep가 끝난 뒤에만 종료를 주입한다. trace=(tick1,50),(tick1,100),(tick2,150), end_tick2/end_ms150을 고정 oracle로 쓰고, 배속1/2/4 및 정지/재개에서도 같은 논리 결과를 비교한다. 새 생산 코드·host opt-in·저장/복원·지형 변경 없이 기존 K07/원 A05의 작은 runtime 기초를 직접 확인할 수 있어 제품 geometry/전체 snapshot 미정과 독립이다. 독립 2/3 검토 뒤 구현한다.

P1의 작은 clock 통과도 원 A05 전체 완료가 아니다. 실제 host/headless/replay 어댑터 연결과 저장 재개는 후속이며 원 A04·A06는 계속 남는다. 전체 I01b는 미완료다. 다음 상태 조각은 이 선언 재고를 토대로 실제 module 값/Dictionary 내부·참조·저장/재구성 분류를 채워야 한다. 값이 없는 product F12·회복 수치·동일 틱 정책을 임의 기본값으로 메우지 않는다.

되먹임: snapshot 준비에서는 선언 재고와 실제 runtime/동적 컨테이너의 전체 상태를 구분하고, 미지원 선언이나 source 변동을 조용히 건너뛰지 않는다. 기존 6파일과 원 검사를 보존한 채 작은 실제 실행 검증부터 추가한다.