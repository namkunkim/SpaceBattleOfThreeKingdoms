# I01b-P2c 전용 이관 — 2026-11-01 KST

## 현재 상태 — 재개 후 최종 수용·기록 마감

**제한 private runtime 구성요소는 정본 attempt5와 다른 모델 최종5b 수용을 완료했다.** [최종 결과](I01B-P2C-RESULT-20261101.md), [전용 체크리스트](I01B-P2C-CHECKLIST-20261101.md), [정본 독립 리뷰](REVIEW-I01B-P2C-20261101.md)가 최신 판정이다. 아래의 최초 중단/미완료 설명은 재개 전 이력이다.

branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 빈 상태를 재확인하고 시작 dirty3823 SHA를 `tmp/i01b-p2c-resume-20261101/dirty-before.json`에 동결했다. 새 worktree·커밋·푸시·병합·브랜치 전환·editor import는 하지 않았다. HTML 기능/다운로드 QA는 계속 중지이며 HTML 자체를 이번에는 수정하지 않았다.

독립 gpt-6-astra 심사는 빈 fleet.form 복원을 반려했다. 별도 probe2는 공개 missile에서 modulo by zero 6회를 재현했고 exit0을 PASS로 세지 않았다. 2단계 보완 계획 독립 수용 뒤 gpt-6.1-sol 실행 담당이 nonempty guard 한 행과 첫/마지막 함대 명명 거부·예상 오류·packet/source/기존 성공 owner 불변 검사를 보강했다. **attempt5 실제 exit0 / 70사례·11553체크·45명명 거부 / 신규로그 SCRIPT ERROR·ERROR·누수0**다. 코드 K6 중5회 사용, 별도 probe2회다. 기존43거부·allowlist·skip은 완화하지 않았다.

변경 후 core/data/service 최소3회귀 exit0이며 service는 신규 OUT-only 복사본의 역치환 SHA로 원문 불변을 증명했다. 나머지4 정본 회귀는 clean tracked HEAD/blob·runtime source35·입력/cache 연속성으로 유지했다. data의 기존 ObjectDB280/resources18 종료진단과 detection/supply 기존 진단은 남는다. attempt2/3 및 앞선 오염 회귀는 계속 정본 성공 증거에서 제외한다.

기존3660/선행source35/격리77와 새 세션3823의 최종 보존 감사, 문서 허용 diff/SHA, 결과 manifest와 압축본/포함목록/zip SHA 검증은 새 증거 루트의 `final-delivery-audit.json`, `record-manifest.json`, `archive-contents.json`, `archive-verification.json`을 따른다. 압축본은 `tmp/i01b-p2c-delivery-20261101.zip`이다. 최초 이관의 상위1행/HTML 상태변경은 별도 증거로 분리하고 이번 문서 마감 차이도 기록한다.

다음 미완료는 상위 체크리스트의 **I01b 실제 통합**이다. 제한 owner의 활성 교체와 실패 시 기존 owner 보존을 작은 후보로 별도1~3/독립 계획 검토한다. P2d라는 정해진 다음 단계나 전체 host/save 완성을 가정하지 않는다. **전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED**. stock POC/적벽 전체, 전체 ST01~18, 운영 Cn·전역 cursor·host/headless/replay 공통 연결·외부 저장파일/schema·제품 공간·화면/Android/성능/사람 플레이는 미완료다.

## 최초 중단 시점 이력 — 아래 미완료 표기는 재개 전 상태

**사용자가 작업 정리·체크리스트·새 세션 이관을 요청하여 신규 구현/검사/HTML 기능 작업을 중지했다. 최종 독립 5-b와 최종 마감은 미완료다.** 사용량 한도를 고려한 중단/이관이며, 다음 세션에서도 usage-limit 실패가 발생하면 즉시 보고하고 반복하지 않는다. 이 파일은 기존 SESSION-HANDOFF.md를 덮어쓰지 않는 보충 자료다.

## 다음 세션의 첫 작업

새 코드를 추가하거나 검사를 다시 돌리기 전에 아래 실제 파일을 읽고, 원본 feature/HEAD/index와 활성 작업을 확인한다. **첫 남은 일은 부수파일 가역 이동 이후의 최종 보존 감사와 코드·입력·정본 class map·엔진·로그 SHA 결과 묶음을 완성하여 구현 비참여 다른 모델의 최종 5-b에 넘기는 것**이다. 현재 실행 검사 결과를 새 기능이나 캠페인 전체 완료로 승격하지 않는다. 새 변경/실패가 없으면 Godot 재실행은 불필요하다.

- [전용 체크리스트](I01B-P2C-CHECKLIST-20261101.md), [계획](../../../tmp/i01b-p2c-20261101/PLAN.md).
- [P2b 결과](I01B-P2B-RESULT-20261031.md), [독립 P2b](REVIEW-I01B-P2B-20261031.md), H2-DECISION.md, D04-STATE.md, I01-READINESS-DECISION-20261026.md.
- 플레이북·CLAUDE·적용 AGENTS 지침을 우선한다. 조율자와 구현자, 구현과 다른 모델의 독립 검토를 분리한다.

## 원본과 소유 경계

원본 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`, branch `codex/feature-i01b-not_remove`, 마지막 확인 HEAD `fb660cea69207fd332e26128643007694910a253`, index 비어 있음. 새 worktree/브랜치 전환/커밋/푸시는 하지 않았다. 공유 dirty가 많으며 원본을 되돌리거나 타 작업을 포함하지 않는다. 기존 BattleSim·검사·P2b helper·데이터는 수정하지 않았다.

기존 `fb660ce`까지의 feature 원격 반영 완료 이력과 이번 미커밋 P2b/P2c 작업을 구분하며, 이번 작업에서 main은 변경하지 않았다.

신규 생산 파일은 `core/battle/operation_private_state.gd`, 신규 검사는 `tests/i01b_private_state.gd`다. 두 신규 UID는 자기 소유로 분리했다. 증거는 `tmp/i01b-p2c-20261101/` 아래다. 이번 문서 마감은 본 이관 자료·전용 체크리스트·상위 CHECKLIST-OPEN의 이관 한 행뿐이며, HTML은 담당 root가 진행 상태만 조율한다. 사용자 “HTML 작업은 중지해” 지시가 계속 유효하다. HTML 기능 작업을 재개하지 않는다.

## 구현 범위와 남은 의미

HTML 기능 작업은 중지 상태다. 이번 사용자 요청의 진행상태 문서 갱신만 root가 담당하며 기존41개 요구 ID와 전체 NOT_READY를 유지한다. P01의 정식1~3/독립 계획 심사는 완료지만 P2c 최종5-b/감사/마감은 미완료다. 개인 브라우저에 저장된 HTML 진행상태가 소스 inline JSON 기본값을 덮어 보일 수 있다. 기존 개인 편집/localStorage를 삭제하지 않았고 이번에는 브라우저 상태에도 접근하지 않았다. 코드·Git refs는 문서 마감에서 변경하지 않았으며 통합 준비가 완결된 상태가 아니다.

신규 owner가 복사한 제한 프로필로 private BattleSim을 생성하고 초기 controls/관측 준비 후 반환한다. busy/미준비 상태를 거부하며 issue/queue/advance/drain/capture 경계를 소유한다. 외부 임의 sim을 입양하지 않는다. 공개 결과는 깊은 사본이며 underscore에 대한 악의적 reflection/thread 접근 보장은 아니다.

비대상 BattleState/FleetState·missile/swarm·명령 로그/대기열/사건·타이머·자원·손상·효과 필드를 보존하고, 생성자 재구성/참조 검증 → 비대상 복원 → 기존 P2b contacts/sup_* slice → exact 검증 후 새 owner만 반환한다. by_id 객체 캐시는 clear/-1로 새 fleet에 재결합한다. 필드 allowlist/실제 script-variable coverage, 형식/유한값/중첩 필수키/ID·분모 guard를 둔다. wmax는 플랫폼 손실에 따라 바뀌는 동적값이며 초기 상수로 고정하지 않는다.

지원은 **현재 신뢰된 규칙 내용과 명시 편성에 대한 제한 POC 또는 Salvo/terrain/Detection/Supply 구성**이다. combat 내용은 현재 정본 내용과 비교하며 임의 config를 지원하지 않는다. `reinf=[]`만 허용한다. Morale/Victory/CommanderAI/DecisionBoard/Chain/Command/Assault/Skills 활성은 지원하지 않는다. public 명령 subset은 stop/move/attack/formation/missile/fighter/volley/def/supply_first/supply_hold이며 구조·kind별 args를 호출 전에 검사하고 deep detach한다. malformed 무변이 거부와 정상 구조 명령의 코어 논리 rejected 사건은 구분한다.

**stock POC 전체·적벽 전체·운영 checkpoint Cn·전역 command cursor·전체 ST01~18·host/headless/replay 공통 연결/활성 교체·외부 save 파일/schema·제품 공간·화면·Android·성능·사람플레이는 완료하지 않았다. 전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다.**

## 실제 실행 결과와 증거 무효화

주 runner 코드 재시도 상한 K6 중 실제 실행4회다. 중간에 중단된 첫 escalation 요청은 로그/프로세스가 없어 미실행이며 횟수에 합치지 않는다. 승인 대기는 한 차례 오래 지속됐고 root가 중단·재개했다. 사용자 취소로 해석하지 않는다.

| 실행 | 사실과 판정 |
|---|---|
| import | DONE/exit0이나 editor-settings 빈 저장경로 ERROR와 기존 tmp snapshot 등록 부작용이 발생. 정상 준비 완료로 인정하지 않음 |
| attempt1 | exit1. harness177/225 Variant 추론 warning-as-error ParseError. user://C: 경로 진단도 별도 존재. Variant 명시와 절대 log-file 경로로 수정 |
| attempt2 | 실제 exit0·50/8511/43 PASS이나 오염 class-cache 사용. **정본 성공 증거에서 제외** |
| attempt3 | 실제 exit0·70/11544/43 PASS이나 같은 오염 cache 사용. **정본 성공 증거에서 제외**. observations는 attempt3-observations.json에 보존 |
| 앞선 회귀 | 정본 실행 증거에서 제외. data_rules는 신규 리터럴2개를 검출해 exit1. TICK_HZ와 기존 OperationProfile과 동일한32bit seed 상한식을 재사용하도록 수정; 검사/allowlist/skip 변경 없음. i01_operation_config는 중복 전역 class ParseError 후 quit하지 못해 해당 세션만 Ctrl-C 종료(exit1) |
| **attempt4** | **정본 class-cache에서 실제 exit0·70사례·11544체크·43명명 거부 PASS**. 신규 captured/engine 로그에 SCRIPT ERROR/ERROR/누수 진단 없음 |
| 정본 관련7회귀 | core_rules/data_rules/i01_operation_config/i01b_logical_clock/i01b_service_state/detection_rules/supply_rules 모두 실제 exit0·기능 PASS. data/detection/supply의 기존 ObjectDB/resources 종료 진단은 남음 |

각 seed10개에 projectile/resource/memory/pending/post/damaged/terrain 7종으로70사례다. source와 함께 전진시키지 않은 fresh target을 복원하고 별도 script-property oracle로 값·순서와 typed Array builtin/class/script metadata까지 비교한다. 실제 missile/swarm·자원 지출/피해·진형 전환·과거 접촉·보급 진행/지출 후 상태와 suffix를 검사한다. queue는 복원 중 실행하지 않고 후속 step에 한 번 소비한다. 실패 원자성·alias/cache·busy/malformed·P2b-alone 불충분·누락 필드 부정 대조를 포함한다.

damaged 사례의 apply_hull/remove_fleet는 생산 코어를 직접 호출하는 **controlled fixture**다. 동적 wmax의 정상 손실 복원 반례이며 public owner 명령만으로 자연 발생한 전체 손실 E2E 증거로 표현하지 않는다.

P2b 회귀의 기존 OUT은 옛 observations를 덮으므로, `regression-i01b_service_state.gd` 복사본에서 OUT 경로 한 줄만 P2c 증거로 바꿨다. `p2b-regression-copy-proof.json`에 원문 SHA/복사 SHA/역치환 원문 정확 동일을 기록했다. 로직·allowlist·skip은 바꾸지 않았다. 원본 검사 실행과 OUT-only 복사 실행을 구별한다.

## class-cache 복구와 생성 부수파일

첫 import가 `.godot/global_script_class_cache.cfg`의21개 core class 경로를 기존 tmp snapshot으로 등록했다. BattleState의 cached/canonical SHA는 실제 다르며 차이는 `# hash-negative fixture` 주석이다. 기능 차이가 없어 보인다는 이유로 정본 실행 증거로 인정하지 않았다.

생성 cache의 잘못된 tmp/core 경로21개만 canonical core 경로로 복구했다. 기존 source·snapshot은 변경하지 않았다. 신규 owner는 생성자 전과 bindings 검증에서16개 핵심 class의 실제 `resource_path`를 확인해 오염된 런타임을 fail closed 거부한다. 옛 cache를 재주입한 별도 probe는 생성자 전에 `noncanonical_runtime_class`로 거부하여 exit0, 이후 canonical cache SHA를 복원했다. **새 import를 무분별하게 반복하면 같은 오염이 재발할 수 있다.**

`class-cache-contaminated.cfg`, `class-cache-canonical.cfg`, `class-cache-repair.json`, `noncanonical-probe-result.json`과 원문 로그가 증거다. `attempt4-inputs.json`에는 최종 helper/test·입력·엔진·canonical cache SHA가 실행 전에 동결돼 있다.

첫 import가 자기 신규 UID2개 외의 .uid/.import77개를 생성했다. 기존 baseline에 없고 git??인 개별파일만 `import-side-effects/` 아래 원경로를 보존해 Move-Item -LiteralPath로 가역 이동했다. 삭제/recursive move/동명 덮어쓰기는 하지 않았다.77개 SHA 일치·원경로 없음, CreationTime 전부 import 시작06:27:43.764Z~종료06:28:09.234Z 안이며 범위밖0이다. `import-side-effects-manifest.json`, `import-side-effects-time-proof.json`이 절대경로/시각/SHA를 기록한다.

## 보존 감사 상태와 미완료

첫 baseline3543은 Git quoted 비ASCII경로를 놓쳤다. 불완전 원본은 `before-incomplete-quoted-paths.json`에 남겼고, core.quotepath=false로 보정한 **before.json의3660개 모두 존재/SHA 동결**을 정식 분모로 삼는다. P2b 과거3594와 다른 시점이다. `source-before.json`의 **원 source35개**는 별도 분모다.

`preservation-audit.json`은 **부수파일 이동 전** 기준으로 기존3660 변경0·누락0, 원 source35 변경0을 확인했다. `.godot` 생성cache21경로 수정은 별도 기록이다. **77개 이동 뒤 최종 재감사는 아직 하지 않았다.** `test-results.json`/최종 regression·record manifest와 최종5-b·최종 결과 문서도 아직 완결하지 않았다. 사용자 요청으로 지금은 문서 마감만 하고 남은 검사를 시작하지 않는다.

이전 감사 뒤의 사용자 허용 문서 변경은 상위 CHECKLIST-OPEN의 이관1행과 root가 담당한 정본 HTML의 진행상태 갱신이다. HTML은 baseline3660 안의 기존 파일이므로 다음 감사에서 이를 무단 변경과 섞지 말고 명시적으로 분리한다. 상위 체크리스트는 추가한 한 행을 역제거했을 때 원문 바이트 SHA가 일치하는 별도 증거를 남긴다. HTML 기능 JS/CSS 변경이나 개인 브라우저 편집 삭제의 승인이 아니다.

다음 세션은 최종 보존·SHA 묶음 → 구현 비참여 다른 모델5-b → 수용 뒤 결과/체크리스트6 마감을 진행한다. 반려 시2단계 스펙으로 되돌아가고 코드 재시도 K6 및 실제 실패 이력을 유지한다. P2d나 새 기능/HTML 기능 작업은 이번 이관 요청만으로 착수하지 않는다.
