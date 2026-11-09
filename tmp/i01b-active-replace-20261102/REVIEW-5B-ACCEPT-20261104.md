# 제한 활성 owner 교체 — 독립 5-b

2026-11-04 KST / **국소 동일-context runtime 교체 구성요소 수용**. 추가 코드 수정을 요구하지 않는다. 결과·체크리스트·최종 문서 보존 및 압축의6단계 마감은 이 심사 뒤 별도 수행한다. 전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다.

## 독립성·검토 범위

검토자는 구현 비참여 `/root/independent_review` (`gpt-6-astra`)다. 실행자 `/root/audit_execution`의 `gpt-6.1-sol`과 다른 모델임을 로컬 rollout source의 agent_path와 turn_context.model에서 직접 확인했다. 근거는 `model-independence-evidence.json`의 원출처와 이 심사의 `INDEPENDENT-5B-AUDIT-20261104.json`이다. 추출 JSON에서 실행 agent_path가 null인 것은 원출처의 중첩 표현을 제대로 추출하지 못한 값이며, 원문 메타를 재귀 확인하면 `/root/audit_execution`이 존재한다.

플레이북·CLAUDE·적용 AGENTS 검색, PLAN·앞선 R1~R4 보완과 계획 수용, 기존 P2c 책임/owner, 실제 diff/신규 검사, 원문 실행/회귀 로그와 코드·입력·보존 SHA를 대조했다. 검토자가 생산 코드·검사를 변경하거나 Godot를 재실행한 횟수는0이다. 읽기·독립 감사·심사 문서만 작성했다.

## 구현과 반증 검토

생산 변경은 기존 owner에 `_context_same`과 `restore_completed`를 더한42행이며 삭제0이다. 기존 create/prepare/issue/queue/advance/drain/close 및 P2b codec을 재작성하지 않았다.

`restore_completed`는 기존 guard를 통과한 뒤 현재 owner를 busy로 표시하고 static prepare로 candidate를 비공개 완성한다. prepare 실패는 기존 오류와 함께 busy를 되돌리고 이전 sim을 유지한다. 완성된 candidate의 맥락이 다르면 candidate만 close하고 이전 sim을 보존한다. 성공은 현재 `_sim`을 한 번 이전하고 candidate._sim을 null로 비운 뒤 candidate를 닫으며, 이전 sim의 Salvo/Detection/Supply module.sim만 해제한다. 새 sim의 bindings를 실수로 close하는 경로가 없다. owner identity·ready·원 입력은 유지되고 정상 오류 뒤 다시 public 입력을 받을 수 있다.

동일 context는 seed/hz와 profile/초기controls의 Variant 타입·값, 사전키 타입·삽입 순서, 배열 순서와 typed builtin/class/script identity를 비교한다. [] controls와 명시 delegate 배열은 다르다. 입력은 prepare의 data 검증을 먼저 통과하므로 comparator가 순환/Object 입력을 그대로 순회하는 경로가 없다. 기존 Service._same만 썼다면 통과할 metadata-only profile 반례와 키 삽입 순서 반례가 실제 검사에 포함된다. 임의 외부 sim 입양이나 다른 작전 전환으로 확대하지 않았다.

신규 경로에 callback/await/스레드 진입점이나 파일 쓰기가 없고 기존 prepare의 readonly 코드SHA/설정읽기를 사용한다. 원자성은 이 동기 소유권 경계다. runtime 예외 복구, 다중 스레드 경합, underscore reflection, 폐기된 raw sim 참조 사용을 보장하지 않는다. 정상 지원 입력의 예외는 검사 실패로 취급했다.

## 실제 통합 검사

최종 attempt2는 **actual exit0, 정상20사례, 20099체크, 명명8개·실제 거부호출9회**, failed=false다. captured/engine 원문과 observations가 일치하며 신규 로그의 SCRIPT ERROR/ERROR/종료 누수 진단은0이다. profile의 metadata-only와 key-order 두 부정대조가 같은 `different_profile` 이름 아래 실행되어8이름/9호출이다. 완결 guard는 두 수를 모두 검사하므로 한 사례를 덮어썼다는 이유로 검사 실행을 생략할 수 없다.

10seed 각각 POC와 Salvo-D/S를 검사한다. POC는 실제 issue로 missile/swarm를 만들고 active cooldown을 확인했다. services는 초기 빈 탄약과 AI/자동사격 억제, 적 위치 이동을 **controlled fixture 준비**로 사용한다. 접촉 기억 자체와 보급 진행/완료·재고 지출은 실제 Detection/Supply step으로 발생하며 직접 기록을 주입하지 않는다. capture 전에 estimated 기억·현재 적위치와 차이, sup_src/sup_prog>0·supplied0·재고 미지출을 확인하고,70step suffix 뒤 supplied1·재고 감소·탐지 평가 경계 통과를 확인한다.

각 사례는 원 owner를 capture 후3step 더 진행하여 실제로 달라진 현재 runtime을 만든 뒤 기존 handle로 복원한다. packet 기반 codec과 별도로 실제 script property를 열거한 checkpoint oracle, 독립 fresh prepare reference와 비교한다. oracle은 typed array metadata와 키/배열 순서, owner 맥락까지 포함한다. 원 owner/sim/fleet identity와 by_id 재결합, 이전 모듈 해제·새 모듈 결합, packet/observe alias 분리를 검사했다. 같은 packet 재복원은 각 복원 직후 상태를 동일하게 유지했다.

packet에 있던 pending은 restore 중 적용하지 않고 다음 advance에1회 기록되며 이후 로그 수가 증가하지 않는다. 사건은 packet 시점에 맞춘다. 예전 timeline에서 이미 drain했어도 더 옛 packet의 미소비 사건은 다시 존재하며 원 순서로1회 drain한다. drain 후 packet으로 복원하면 빈 사건 목록이다. 외부 소비자의 전역 dedup은 구현/주장하지 않는다.

last empty form·다른유효profile/seed/controls·unsupported hz·busy/closed/unprepared 거부는 정확한 오류명과 owner 미반환을 확인한다. 실패 때 sim identity·직접 owner oracle·packet 값/형태가 유지되며 prepare/context 실패 뒤 busy가 풀려 다음 정상 issue와 restore가 가능하다. busy 거부는 기존 busy 상태를 그대로 유지하고 closed/unprepared는 기존 `unprepared_owner`를 반환한다.

## 실행 이력·회귀

attempt1은 fixture class에서 resource_path를 직접 읽은 ParseError로 exit1이며 사례가 실행되지 않았다. attempt2는 Script 변수로 명시해 같은 canonical fixture 검사에 접근했고 OUT만 새 경로로 옮겼다. 실패 로그/입력/코드 사본을 보존했다. 새 단계는 K6 중2회이고 이전 P2c5회와 합치지 않는다. editor import는 실행하지 않았다.

계획한 P2c/core/data3회귀가 실제 exit0·기능 PASS다. P2c는70/11553/45이며 OUT-only 복사본을 직접 역치환하여 원 test 바이트와 정확히 같음을 확인했다. 원 P2c test·observations·ZIP을 덮어쓰지 않았다. data의 기존 ObjectDB280/resources18 종료 진단은 남는다. 기능 PASS를 깨끗한 종료로 표현하지 않는다. source나 미해결 문제가 없는 다른 통과 검사는 재실행하지 않았다.

## 공백 게이트 판정

전체 `git diff --check`는 **실제 exit2**다. exit0 또는 exit1로 기록하지 않는다. 독립 subprocess로 재확인한 유일한 공백 진단은 `docs/battle-core/CHECKLIST-OPEN.md:33`의 이전 P2c 행 CRLF다. 해당 파일 SHA `dda7386c426ebd3a5804e2f5309489a6175f387be827369c781875a8cceabe7b`는 이번3879 baseline과 동일하다. 이번 변경이 만들었다는 증거가 없으며 기존 공유 변경을 고쳐 진단을 숨기지 않았다.

이번 허용 helper/new test의 독립 trailing space/tab 검사는0, 최종 newline은 있다. **전체 게이트 PASS로 승격하지 않고 기존 baseline 진단을 분리한 제한 수용**이다. 저장/복원 동작과 무관한 보존 문서의 CRLF가 새 구성요소 기능 수용을 막을 사유는 아니다. 마감 문서에서도 실제 exit2와 이 원인을 유지해야 한다.

## 독립 SHA·보존 감사

`INDEPENDENT-5B-AUDIT-20261104.json`에 직접 재계산 결과를 남겼다.

| 분모/항목 | 결과 |
|---|---|
| 실행 전 입력42 | 현재 SHA 불일치0; 정본 cache·엔진·소스/데이터·검사 포함 |
| pre-review manifest83 | 누락/SHA 불일치0 |
| baseline3879 | 누락0, 허용 operation_private_state.gd만 변경 |
| 선행 source35 | 변경0 |
| 가역격리77 | SHA/원경로부재 불일치0 |
| 이전 P2c payload254 | 현재 helper1개만 의도된 변경; ZIP 자체 SHA 불변 |
| 최종 helper/test snapshot | 현재 파일과 바이트 exact |
| P2c 회귀 복사 runner | OUT 역치환 후 원문 exact |

최종 helper SHA는 `6be2adeb64bec7c9a89040cab5c9558219e063272df1a9e5fd00cf1dd9111441`, 신규 test는 `e76bc22ef569ccbf969fddc92691f20d1556dab963102a85aec7c4c2d0631759`다. cache SHA `0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1`은 정본 P2c 이후 불변이며 owner의 실제 canonical class guard와 검사 fixture resource_path guard가 통과했다. 이전 P2c ZIP SHA는 `99a4a1adca1bdc3bf7e56baa9112c1625ab6c6371bfaafa0482b3471903a2971` 그대로다.

branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, 빈 index를 직접 확인했다. 기존 source/검사/allowlist/skip/host/HTML/데이터 변경 없음. 신규 test는 기존3879에 없던 자기 산출물이며 baseline 분모에 포함한 것처럼 보고하지 않는다.

## 완료 경계

수용 범위는 같은 원입력의 제한 private owner 안에서 검증된 runtime을 교체하는 구성요소다. 실제 FleetBattle3D UI/시계·AutoResolver 스레드·host/headless/replay 공통 adapter, 전체 캠페인 모듈/ST01~18·운영 Cn/global cursor·외부 저장파일/schema·제품 공간·화면/Android/성능/사람플레이는 미완료다. 기존 handle이라는 좁은 실제 소비자와 통합했다는 사실을 전체 게임 연결로 확대하지 않는다.

이번5-b는 수용이며6단계 결과/체크리스트/최종 감사·압축 기록으로 진행할 수 있다. 후속 코드 변경이 있으면 새 영향에 대한 검증과 독립 재심이 필요하다. 커밋·푸시·병합·브랜치 전환·새worktree 승인은 포함하지 않는다.
