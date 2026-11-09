# P03 첫 조각 — 선언 변경 감지 도구 계획

2026-11-05 KST. **독립 계획 심사 대기, 구현 미착수.** 전체 P03/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED.

## 0. 입력·소유·분모

사용자 P03 지시, 워크플로우-플레이북.md, CLAUDE.md와 정본 H2/D04/I01 readiness/prereg, P2b/P2c/활성교체 결과·리뷰·이관을 읽기 기준으로 삼는다. 부모 경로 및 저장소 AGENTS 검색에서 적용 파일을 발견하지 못했다. 조율·조사/구현·독립 심사를 분리한다. 조사 담당은 상속 세션 모델이며 정확한 모델명을 추정하지 않는다. 조율자가 별도 gpt-6.1-sol 구현 담당과 gpt-6.1-terra 심사 담당의 명시 배정을 기록한다. 배정 문자열은 실행 내부 모델의 자기증명과 구분한다.

P03 쓰기 허용은 `tmp/p03-state-checkpoint-20261105/`뿐이다. OperationPrivateState/BattleSim/공통 adapter/host/headless/replay/공유 체크리스트/기존 검사·데이터는 읽기만 한다. 이 계획의 도구는 신규 `.gd`가 아니며 정본 클래스 등록에 관여하지 않는다. 새 worktree·브랜치 전환·커밋·푸시·병합·HTML·브라우저·localStorage·editor import는 금지한다.

`baseline-files.json`은 시작 dirty/untracked **3965개**의 경로·크기·바이트 SHA256을 기록한다. clean tracked 전체 또는 과거3879 분모가 아니다. 자기 증거 경로를 제외한다. branch=`codex/feature-i01b-not_remove`, HEAD=`fb660cea69207fd332e26128643007694910a253`, index 빈값이다. status는 해시 중 달라져 단일시점 원자 snapshot이라고 주장하지 않는다. `baseline-recheck.json`은 동결된3965 파일 재해시 변경0이다. 최종 감사는 이 고정 분모와 이후 신규 경로를 따로 보고한다.

`source-inventory-observed.json`은 현재 `core/battle/**/*.gd` **30개 파일**을 새로 읽은 SHA와 선언 관측294개다. 관측식은 top-level var와 BattleState의 알려진 inner-class var이며 아직 일반 parser가 아니다. 이는 전체 상태 분모/활성 모듈 수/복원 coverage가 아니다. 새 도구는 별도 알고리즘으로 이 관측을 교차 확인한다. core 밖의 host/clock·상태와 동적 Dictionary 키를 포함하지 않는다. 저장소 전체 `.gd` 경로 목록과 `BattleSim.new`, `TickClock`, module 생성/외부 preload 참조의 읽기 검색 결과를 별도 미분류 목록으로 남겨 누락 범위를 드러낸다. 신규 외부 상태의 자동 직렬화나 불필요 분류 완료를 주장하지 않는다.

## 1. 목적·비대상

첫 조각은 **읽기 전용 선언 재고와 변경 경보**다. 전체 복원 구현에 앞서 필드·모듈이 늘어도 과거 재고를 재사용해 누락하는 실패를 작은 도구로 드러낸다. runtime API/순서/프로필 지원·공개 명령·커서·스키마를 바꾸지 않는다. 선언 감지 성공은 타입의 runtime 값, 갱신/소비 의미, serializer 완전성 또는 suffix 동등성 증명이 아니다.

전체 C0/Cn·global cursor·모든 ST·새 모듈 지원·host 완료·영속화는 비대상이다. 실제 capture→전진→복원→같은 suffix runtime 검사는 기존 활성교체 수용 이력을 참고할 뿐 새 도구의 검사 분모에 넣지 않는다. 새로운 모듈 확장은 별도 작은 계획/독립 심사/정본 runner가 필요하다.

## 2. 도구 계약

- 신규 `inventory.py`: Python 표준 라이브러리만 사용한다. 입력 루트 아래 `core/battle/**/*.gd`를 읽고 파일 목록·SHA 및 class/inner class별 script member 선언을 순서대로 출력한다. 실행 위치가 달라도 명시 `--root`를 사용한다. 경로는 저장소 상대 POSIX로 기록한다. 출력은 stdout이며 임의 입력/기준선을 수정하지 않는다.
- 선언 식별자는 `(path, class scope, member name)`이다. 선언 순서·명시 타입/추론 initializer의 원문을 보존하고 줄번호는 진단용이다. 주석/공백만 바뀌어도 file SHA 변화는 보고하지만 member schema 변화와 나눠 보고한다. Dictionary/Array를 정렬해서 runtime 동등성을 주장하지 않는다.
- class scope와 함수/로컬 변수를 구분한다. 현재 소스가 사용하는 multiline initializer와 주석/문자열을 처리한다. 지원하지 못하는 member 문법은 누락해 통과시키지 말고 명시 오류로 종료한다. annotation/static/export member 등 fixture에서 검증하지 않은 구문은 지원 밖으로 거부하거나 독립 심사 후 명시 지원한다. regex 하나로 모든 GDScript 의미를 보장하지 않는다.
- 신규 `declaration-baseline.json`: 읽은 현재 소스의 schema 관측 기준선. `check --baseline`은 추가/삭제/이름·scope/타입·initializer/순서 변경, 파일 추가/삭제를 구분하고 차이가 있으면 exit1. 파싱/파일읽기/기준선 오류 exit2, 동일 exit0. SHA만 다른 경우도 별도 code drift로 보고하고 정상 동일 exit0로 숨기지 않는다(명시 exit1). 도구에 자동 baseline 갱신 모드는 두지 않는다.
- 신규 `test_inventory.py`: 임시 fixture root에서 동작하고 실제 소스/기존 baseline을 변경하지 않는다. 신규 결과 파일은 P03 전용 경로에만 둔다. 출력은 한국어 요약과 기계 판독 JSON. 모든 판정 이름과 개수를 완결 guard로 확인한다.
- runtime 타입 추론·소유권·capture/재구성/재결합/재계산/비대상 판단은 사람이 근거를 채우는 **별도 미완료 책임 원장**이다. parser가 참조 사용이나 mutable alias를 의미 분석했다고 표현하지 않는다.

## 3. 5-a 인수표·실행 분해

신규 P03 runner의 상한 **K6**, 현재0/K6. 계획 수용 이후에만 구현한다. fixture 검사 이름 **12종**과 실제 소스 교차확인1종, 합계13종을 사전등록한다. seed/runtime 사례 수와 혼용하지 않는다.

| 이름 | 입력·oracle·성공 조건 |
|---|---|
| p03_01_members_and_inner_scope | root/inner class var를 직접 손으로 적은 기대 목록과 비교; 함수 local 제외 |
| p03_02_strings_comments | 주석·문자열 안 가짜 var 제외, 문자열의 # 보존 |
| p03_03_multiline_initializer | 다행 Array/Dictionary와 줄 내부 문자열·주석을 raw declaration로 보존 |
| p03_04_added_member | fixture 필드 추가를 정확히 추가로 보고/exit1 |
| p03_05_removed_member | 삭제를 정확히 삭제로 보고/exit1 |
| p03_06_type_initializer_order | 타입·초기값·순서 각 독립 변이를 탐지/exit1; 세 subcase 수 별도 |
| p03_07_new_removed_file | 신규/삭제 gd와 필드없는 gd도 탐지/exit1 |
| p03_08_local_only_code_drift | local-only 변경은 member 추가0, code SHA drift/exit1 |
| p03_09_unsupported_syntax | 미지원 member 문법을 명명 오류/exit2로 거부, 조용한 누락 금지 |
| p03_10_malformed_baseline | 잘못된 JSON·중복 identity·필수키 누락을 오류/exit2로 거부 |
| p03_11_readonly_failure | 정상/실패 전후 fixture/기준선 byte SHA 동일, 기존 결과 덮어쓰기0 |
| p03_12_deterministic_and_foreign_cwd | 반복 출력 byte 동일, 다른 cwd+명시root 동일 |
| p03_13_current_source_crosscheck | 현재30 gd 파일 목록과 독립 rg/수동 BattleState inner/Fleet121/Sim28 등 대조;294 관측과 다르면 숨기지 않고 원인 보고 |

13종이 정확히 실행되고 실패0이어야 한다. subcase/assert 수는 실제 실행 산출로 추가 기록하며13종과 혼동하지 않는다. 정본 실제 소스는 실행 전 source SHA manifest, Python exe 경로/버전/바이너리 SHA, 도구/입력 SHA를 동결한다. Godot를 실행하지 않으므로 엔진·class map은 **미사용**으로 명시하고 가능하면 현재 SHA를 읽기 동결하되 runtime guard 통과로 표현하지 않는다. 코드 재시도는 실제 runner 호출을1회로 세고 실패 로그를 보존한다. 사용량 제한 시 반복 금지·즉시 보고.

작업 순서: (a) 다른 모델 계획 심사 → (b) 별도 실행 담당 구현 → (c) 입력 동결/runner 실제 exit·stdout/stderr/분모 기록 → (d) 다른 모델 최종5b → (e) 수용 후 P03 결과·체크리스트·인계·manifest/압축·독립 closeout. 반려는 스펙으로 돌아간다. 신규 code만 관련 검사이며 생산/기존 test 변경0이므로 Godot 회귀를 반복하지 않는다.

## 4. 5-b 반증과 최종 보존

심사자는 구현 비참여 다른 모델이다. 파일 선언을 일부러 누락/신규 module 추가/함수 local을 field로 오분류/unsupported syntax 숨김/부분 baseline·순서 변화/파일 읽기 실패/출력 덮어쓰기 반례를 찾는다. 도구의 field coverage와 전체 상태 coverage를 명시 분리하고 cursor·실패 원자성·실제 suffix 미구현 경계를 심사한다. P02 소유파일 무변경을 바이트로 확인한다.

최종3965 고정 분모의 누락·SHA변경을 전부 나열하고, P02 동시 변경은 사유/소유/읽기 관측으로만 분리한다. 미검토 P02 변경을 정본 기준선으로 승격하지 않는다. P03 자기 신규 경로만 허용한다. 공유 체크리스트 갱신은 동시 소유 계약 없으면 의존성으로 남긴다. 기존 전체 diff-check actual exit2(P2c 행 CRLF) 이력을 유지하고 새 경로 공백 검사와 혼용하지 않는다. 기존 실패/입력/관측/ZIP 덮어쓰기0. 압축에는 자기 산출물만 포함하며 manifest/CRC/각 entry SHA를 별도로 감사한다.

## 5. 후속 의존성·미정

`STATE-AUDIT.md`와 `COMMAND-AUDIT.md`가 P03 전체 조사/후속 계약의 근거다. 외부 상태/동적 key/실제 갱신·소비·alias의 필드별 원장은 계속 미완료다. 신규 command seq/commit_seq의 K05~07 권고를 runtime 구현 완료로 취급하지 않는다. 명령 acceptance/apply/완료/사건 drain의 독립 경계와 pending 포함/suffix 절단점은 별도 contract runner로 좁혀야 한다. P02에는 capture 가능 시점, ready/busy, 실패 후 host 보존, 사건 소비 책임을 제안만 한다. 직접 메시지 권한은 없으며 읽기 확인·문서 인계만 한다.
