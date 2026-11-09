# P03 첫 조각 결과

2026-11-07 KST. **읽기 전용 선언 재고와 변경 감지를 5-a·독립 5-b에서 한정 수용했다.** 정본 소스의 31개 경로에서 294개 script member를 독립 원문 oracle의 identity·순서·raw·행·파일 SHA와 대조했다. 원 관측의 294에는 BundleLayout/PocSetup 정적 4개 누락과 BattleState 지역 변수 4개 혼입이 상쇄돼 있었다. P02 owner는 member 7개 동일/코드 SHA 변경이며 신규 adapter는 member 0개다. 이 차이는 과거 후보의 의도된 drift 검사로 보존했다. [독립 5-b](REVIEW-5B-attempt-03.md)

`inventory.py collect --root <repo>`는 선언과 SHA의 JSON을 stdout에 쓴다. `check --root <repo> --baseline <file>`는 동일 exit0, 선언·파일·코드 SHA 차이 exit1, 지원 밖 구문/읽기·입력 검증 오류 exit2다. 오류의 stdout은 비어 있고 입력·기준선은 읽기 전용이다. Windows에서 실제 권한 변화가 필요한 읽기 실패/중간 읽기 차이는 주입된 I/O 실패와 재독값을 썼다. 중간에 바뀌었다 원복된 파일, 함수 본문 의미·GDScript 전체 구문은 이 감지기의 보장 범위 밖이다. P03 로컬 `.gdignore`로 fixture를 격리했다. Godot 실행, class map 사용·런타임 guard 판정은 없었다.

- 준비 01 scanner exit2는 공급 함수 본문의 기존 역슬래시 줄연결이었다. 독립 수용된 v3의 함수 한정 처리 뒤 준비 02 scanner exit0, 독립 oracle exact 및 입력 SHA 전후 동일로 기준선을 고정했다.
- 명명 runner attempt-01 actual exit1은 기존 출력 충돌 fixture의 Python import 경로 결함이다. attempt-02 actual exit0은 13종/46호출이었으나 독립 5-b가 인라인 접근자 반례로 반려했다. 독립 수용된 v4에서 접근자·동일 행 선언 경계를 보완했다.
- 정본 **attempt-03/K6** 실제 exit0, **13개 명명 검사/51 하위 프로세스**다. 하위 실제 exit는 0이 10개, drift 1이 9개, 계약상 오류 2가 32개다. 기대 밖 exit 0개. 직전·직후 입력 44개 SHA 동일. 각 하위 호출의 argv와 입력 SHA·stdout·stderr·실제 exit가 보존됐다. [정본 실행](attempt-03/run.json) · [명명 및 호출 분모](attempt-03/suite/suite.json)

원 dirty/untracked 동결 3965개 재해시에서 누락 0, P02 변경 4개를 분리했다. P03 재개 이후 공유 통합 체크리스트 한 파일의 관측 SHA가 추가로 달라졌으며 P02 마감 정정 기록에 대응한다. 44개 실행 입력은 최종 보존 확인에서도 동일하다. branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 비어 있음. 전체 `git diff --check` actual exit2는 기존 P2c 체크리스트 33행이고 신규 P03 파일 검사는 별도다. [보존 감사](delivery-audit-final-20261107/preservation.json) · [전체 diff 검사](scope-observation-20261107/3-run.json)

조사 범위와 후속 책임은 상태·명령 원장에 남겼다. 제한 재고는 전체 필드 책임, 실제 Cn과 suffix, 외부 효과 exactly-once 또는 저장 호환을 입증하지 않는다. 전체 P03/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED 및 O07 OPEN을 유지한다. [상태 조사](STATE-AUDIT.md) · [명령 조사](COMMAND-AUDIT.md) · [정본 대조 보충](STATE-REFERENCES-20261107.md)
