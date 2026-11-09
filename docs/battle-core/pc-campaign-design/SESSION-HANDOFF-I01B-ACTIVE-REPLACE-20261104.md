# 제한 활성 owner 교체 — 압축 이관

2026-11-04 KST / **국소 동일-context 구성요소·독립5b 제한 수용·6 기록 마감**. 이 문서가 이번 조각의 최신 이관이며 P2c 이관은 이전 단계 이력으로 유지한다.

## 실제 상태와 첫 확인

원본 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`, branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 빈 상태다. 작업 시작에는 플레이북·CLAUDE·적용 AGENTS와 [결과](I01B-ACTIVE-REPLACE-RESULT-20261104.md)·[독립 리뷰](REVIEW-I01B-ACTIVE-REPLACE-20261104.md)·[체크리스트](I01B-ACTIVE-REPLACE-CHECKLIST-20261104.md)를 읽고 실제 상태를 다시 확인한다. 새 worktree·커밋·푸시·병합·브랜치 전환·타 작업 폐기·HTML/editor import는 하지 않았다. HTML 기능/다운로드 QA 중지는 계속 유효하다.

계획/독립 계획 수용은 `tmp/i01b-active-replace-20261102/PLAN.md`, `REVIEW-PLAN-ACCEPT-20261102.md`다. 실제 구현/실행은11월4일이다. helper의42행 추가와 신규 `tests/i01b_active_replace.gd`만 생산/검사 변경이다. 문서 마감은 이번 신규 RESULT/CHECKLIST/HANDOFF·reviewer 소유 REVIEW, 상위 활성교체 추가1행이다. 이전 상위P2c CRLF 행은 보존했다.

## 수용한 내용과 실행 증거

기존 owner의 `restore_completed(packet)`는 같은 seed/hz/profile/초기controls에 한정해 candidate를 private 완성하고 기존 handle의 sim을 이전한다. exact context는 타입/값·키 타입/삽입 순서·배열 순서와 typed metadata/script identity를 포함한다. []와 명시 delegate controls는 다르다. 실패는 기존 active sim/상태/packet 보존·busy 복구, 성공은 구 module.sim 해제와 새 bindings 유지다. 동기 경계이며 외부 raw sim 입양·runtime 예외 복구·스레드 안전성·underscore reflection 보장은 아니다.

attempt1은 fixture canonical path 확인의 ParseError exit1로 사례 미실행이다. 수정 뒤 **attempt2 actual exit0 / 정상20·20099체크·명명8·거부호출9 / 신규 SCRIPT ERROR·ERROR·누수0**다. metadata-only/key-order 두 profile subcase가 같은 거부명 아래 있어 실제호출9다. 새 단계2/K6이며 이전 P2c5/K6와 합치지 않는다. 실패 로그/코드/입력과 최종 attempt2 증거를 모두 보존한다.

10seed×POC/services2계열은 실제 공격/쿨다운, 기억·보급진행/완료재고와 public suffix를 포함한다. 빈 초기 탄약·AI/자동사격 억제·적 위치 이동은 controlled fixture 준비이고 실제 기억/보급 효과는 step으로 발생했다. capture 뒤 활성 runtime을 더 전진시킨 다음 같은 handle로 복원하고, 실제 script-property/typed oracle 및 독립 fresh reference와 비교한다. pending은 다음 advance에1회 소비한다. 사건은 packet 시점으로 복원하며 외부 소비자의 전역 dedup을 주장하지 않는다.

최소 회귀 P2c70/11553/45·core/data actual exit0. P2c는 신규 OUT-only 복사이며 역치환 바이트 exact다. data 기존 ObjectDB280/resources18 종료 진단은 남는다. 전체 `git diff --check`는 기존 상위P2c33행 CRLF로 **actual exit2**이고 원문 SHA를 보존했다. 신규 코드 공백은0이다. 전체 게이트 PASS로 표현하지 않는다.

최종 helper SHA `6be2adeb64bec7c9a89040cab5c9558219e063272df1a9e5fd00cf1dd9111441`, 신규 test SHA `e76bc22ef569ccbf969fddc92691f20d1556dab963102a85aec7c4c2d0631759`. 정본 cache SHA `0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1`은 불변이다. 실행 전 입력42와 snapshot, 원문 로그·actual exit는 새 증거 루트에 있다. 기존 오염 cache를 사용한 P2c attempt2/3는 계속 정본 증거에서 제외한다.

## 최종 보존·압축과 남은 통합

독립 gpt-6-astra는 실행 gpt-6.1-sol과 분리되어 [최종5b 수용](../../../tmp/i01b-active-replace-20261102/REVIEW-5B-ACCEPT-20261104.md)·[직접 감사](../../../tmp/i01b-active-replace-20261102/INDEPENDENT-5B-AUDIT-20261104.json)를 남겼다. 최종 문서 뒤의 baseline3879/source35/격리77/HTML/기존 검사/old P2c zip 감사와 허용 helper·상위1행 차이는 `final-delivery-audit.json`을 따른다. 상위 새 행 역제거 SHA는 이번3879의 시작 SHA와 정확히 같다.

증거 루트 `tmp/i01b-active-replace-20261102/`, 압축본 `tmp/i01b-active-replace-delivery-20261104.zip`. 포함 파일·각 SHA는 `record-manifest.json`과 외부 `archive-contents.json`, CRC/entry대조/zip SHA는 외부 `archive-verification.json`에 있다. 이전 P2c zip SHA `99a4a1adca1bdc3bf7e56baa9112c1625ab6c6371bfaafa0482b3471903a2971`은 그대로 보존한다. 엔진 바이너리·.git·전체 저장소·무관 작업 파일을 묶지 않는다.

**전체 I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED**. 실제 FleetBattle3D UI/시계·AutoResolver 스레드·host/headless/replay 공통 연결, 캠페인 모든 활성 모듈/ST01~18·운영 Cn/global cursor·외부 저장파일/schema·제품 공간·화면/Android·성능/사람플레이는 미완료다. 다음은 실제 소비자별 바인딩/완료 경계를 작은1~3로 계획하고 독립 검토한다. P2d 명칭·전체 저장 완성·미정 수치/정책을 먼저 가정하지 않는다. 사용량 제한이 재발하면 반복하지 말고 즉시 보고한다.
