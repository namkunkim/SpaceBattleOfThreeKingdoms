# 제한 활성 owner의 runtime 교체 — 결과

2026-11-04 KST / **국소 동일-context 구성요소 구현·기능 5a·독립 5b 제한 수용·6 기록 마감**. 전체 `git diff --check`는 기존 문서 CRLF 진단으로 **actual exit2**이며 전체 게이트 PASS라고 표시하지 않는다. 전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다.

## 결과와 수용 범위

원본 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`, branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, 빈 index에서 진행했다. 기존 dirty3879 SHA를 동결했고 P2c 마감 zip·기존 관측을 보존했다. [수용 계획](../../../tmp/i01b-active-replace-20261102/PLAN.md), [계획 보완/수용](../../../tmp/i01b-active-replace-20261102/REVIEW-PLAN-ACCEPT-20261102.md), [독립 리뷰](REVIEW-I01B-ACTIVE-REPLACE-20261104.md), [전용 체크리스트](I01B-ACTIVE-REPLACE-CHECKLIST-20261104.md), [압축 이관](SESSION-HANDOFF-I01B-ACTIVE-REPLACE-20261104.md)을 연결한다. 계획은11월2일, 실제 구현/검사는11월4일이다.

기존 `OperationPrivateState`에 `restore_completed(packet)`와 작은 `_context_same` 비교42행을 추가했고 기존 코드 삭제는0이다. 새 facade는 없다. 기존 owner handle로 명령·진행·사건을 계속 소비하면서, prepare가 완성한 새 private sim을 한 번 이전한다. candidate의 sim 소유권을 비운 뒤 candidate를 닫고 이전 sim의 Salvo/Detection/Supply bindings만 해제한다. 성공 후 owner identity·ready·원 입력은 유지된다. 정상 prepare/context 오류는 현재 sim·모든 상태·packet을 보존하고 busy를 원복하여 다음 public 입력을 허용한다.

교체는 같은 seed/hz/profile/초기controls의 원입력으로 제한한다. Variant 타입/값·Dictionary 키 타입과 삽입 순서·Array 순서와 typed builtin/class/script identity까지 비교한다. `[]` controls와 명시 delegate 배열은 실효 제어가 같더라도 다른 원입력이다. 이것은 해당 메서드의 보수적 국소 지원 범위이며 전역 저장 호환 정책이 아니다. 기존 prepare의 코드 SHA와 설정 파일 읽기를 재사용하고 새 파일쓰기/callback/await/스레드 경로는 추가하지 않았다.

원자성은 단일 동기 소유권 경계다. runtime 예외 복구·스레드 경합·underscore reflection·폐기된 raw sim 참조의 사용은 보장하지 않는다. 기존 create/prepare/명령/진행/close, P2b codec, 기존 BattleSim/검사/데이터/host/HTML은 변경하지 않았다.

## 실제 검증과 한계

신규 `tests/i01b_active_replace.gd`의 최종 attempt2는 **actual exit0, 정상20사례·20099체크·8명명 거부·실제 거부호출9회**, failed=false다. POC10과 services10으로 각 기존10seed를 사용한다. profile metadata-only와 키 순서 두 subcase가 같은 `different_profile` 이름 아래 있어8이름/9호출을 모두 완결 guard로 검사한다. 신규 captured/engine 로그의 SCRIPT ERROR/ERROR/종료 누수 진단은0이다.

각 사례는 실제 capture 뒤 활성 runtime을3step 더 진행하여 다른 현재 상태를 만든 다음 같은 handle로 복원한다. packet codec의 필드목록과 별도로 실제 script property를 열거하는 typed/order oracle과 독립 fresh prepare reference를 비교한다. owner/sim/fleet identity·by_id 재결합, 구 모듈 해제/새 모듈 결합, packet/관측 alias 분리를 확인했다.

POC는 public issue로 실제 missile/swarm·쿨다운을 만들고110step suffix에서 진행 공격을 해소했다. services는 빈 초기 탄약·AI/자동사격 억제·적 위치 이동을 **controlled fixture 준비**로 썼다. 접촉 기억과 보급 효과를 직접 주입하지 않았다. 실제 Detection/Supply step으로 estimated 기억·현재 위치와 차이·미완료 sup_src/sup_prog와 미지출 재고를 만들고70step suffix에서 supplied1·재고 감소·탐지 평가 경계를 확인했다. 이는 제품 편성/밸런스·사람 플레이 검사가 아니다.

pending은 restore 중 미실행이고 다음 advance에서1회 기록된다. 사건은 packet 시점 기준이다. 이미 외부 소비한 예전 timeline의 사건도 더 옛 packet에서는 미소비로 복원될 수 있다. drain 전 packet은 원 순서로1회 drain되고 drain 후 packet은 빈 목록이다. 동일 packet 반복 복원은 준비 자체가 효과를 추가 실행하지 않음을 검사하며 외부 소비자의 전역 중복억제를 뜻하지 않는다.

명명 거부는 busy/closed/unprepared/last empty form/다른 유효 profile/seed/controls/unsupported hz다. 정확한 오류·owner 미반환·현재 sim identity와 직접 상태/packet 불변, prepare/context 실패 뒤 busy 복구와 다음 정상 issue/restore를 확인했다. 다른 context packet은 별도 prepare를 먼저 성공시켜 교체 거부의 원인을 분리했다.

attempt1은 canonical fixture 확인에서 클래스의 resource_path를 직접 읽어 ParseError exit1이었다. 사례는 미실행이고 로그/입력/소스 사본을 보존했다. Script 변수로 접근하는 최소 수정 뒤 attempt2가 통과했다. 새 단계는 K6 중2회이며 이전 P2c5회와 합산하지 않는다.

승인된 최소 회귀는 P2c/core/data3종 모두 실제 exit0·기능 PASS다. P2c는70/11553/45이며 새 OUT-only 복사 runner를 역치환하면 원 test 바이트와 정확히 같다. 기존 P2c observations와 zip은 덮어쓰지 않았다. data의 기존 ObjectDB280/resources18 종료진단은 남고 깨끗한 종료로 확대하지 않는다.

## 공백 게이트·독립 심사·보존

전체 `git diff --check`는 **actual exit2**다. 유일한 공백 진단은 이전 P2c 상위 CHECKLIST33행의 CRLF이며 이번 최초 동결 파일 SHA와 동일했다. 새 helper/test 자체 공백검사는0이다. 마감에서는 기존 행 바이트를 보존하고 새 활성교체 행만 추가했다. 전체 게이트를 PASS로 고치거나 기존 진단을 감추지 않는다.

실행 담당은 gpt-6.1-sol, 구현 비참여 독립 심사자는 gpt-6-astra다. [상세 독립 수용](../../../tmp/i01b-active-replace-20261102/REVIEW-5B-ACCEPT-20261104.md)과 [직접 감사](../../../tmp/i01b-active-replace-20261102/INDEPENDENT-5B-AUDIT-20261104.json)는 실행 전 입력42·pre-review manifest83·baseline3879·source35·격리77·P2c payload254·코드/검사 snapshot을 직접 대조했다. 기능과 제한 스펙을 수용하며 미해결 코드 수정 요구는 없다. 이 분모에 이후 마감 문서를 포함했다고 주장하지 않는다.

최종 helper SHA256 `6be2adeb64bec7c9a89040cab5c9558219e063272df1a9e5fd00cf1dd9111441`, 신규 test SHA256 `e76bc22ef569ccbf969fddc92691f20d1556dab963102a85aec7c4c2d0631759`다. 정본 cache SHA `0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1`은 불변이고 실제 class 경로 및 fixture 경로 guard가 통과했다.

최종 증거 루트는 `tmp/i01b-active-replace-20261102/`다. 최종 문서까지 포함한 `final-delivery-audit.json`, `record-manifest.json`, 외부 `archive-contents.json`/`archive-verification.json`이 포함 목록·각 SHA·CRC·zip SHA를 연결한다. 압축본은 `tmp/i01b-active-replace-delivery-20261104.zip`이다. 엔진 바이너리·.git·전체 저장소/무관 작업 파일은 압축하지 않는다. 기존3879에서 helper와 이번 상위 추가1행만 허용 차이로 분리하고, source35/격리77/HTML/기존 검사와 P2c zip을 보존했다. 상위 추가행을 역제거하면 이번 최초 SHA와 정확히 일치한다.

## 남은 통합과 되먹임

완료는 **같은 원입력의 제한 owner 내부 runtime 교체 구성요소**뿐이다. FleetBattle3D의 UI/시계·AutoResolver 스레드·host/headless/replay 공통 adapter, 전체 캠페인 모듈/ST01~18·운영 Cn/global cursor·외부 저장파일/schema·제품 공간·화면/Android·성능/사람플레이는 미완료다. 다음 조각은 실제 소비자별 바인딩과 완료 경계를 별도1~3/독립 계획 심사로 좁혀야 하며 P2d나 전체 저장 완성을 먼저 가정하지 않는다.

되먹임: 후보를 완성하는 것과 활성 runtime 소유권을 이전하는 것은 다른 책임이다. 성공 시 old/new bindings를 함께 검사하고 실패 때 busy 복구와 다음 정상 호출까지 확인한다. packet 시점의 정확한 사건 복원과 외부 효과의 전역 중복억제를 구분한다. full diff-check 실패가 보존된 기준선이면 원문·SHA·actual exit를 그대로 남기고 기능 제한 수용과 혼동하지 않는다. 커밋·푸시·병합·worktree 생성·HTML/editor import는 하지 않았다.
