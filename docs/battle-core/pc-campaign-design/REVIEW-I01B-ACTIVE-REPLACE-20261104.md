# 제한 활성 owner 교체 — 독립 5-b

2026-11-04 KST / **국소 동일-context runtime 교체 구성요소 수용**. 전체 I01/I01b/A04~A06는 NOT_READY, 외부 save schema는 UNCLASSIFIED다.

검토자는 구현 비참여 `/root/independent_review` (`gpt-6-astra`)이며 실행자 `/root/audit_execution` (`gpt-6.1-sol`)과 다른 모델임을 로컬 agent_path/model 원문에서 확인했다. 생산 코드·검사·실행에 참여하지 않고 계획·실제 source/diff·원문 로그/관측·입력 및 보존 SHA를 독립 대조했다. [상세 수용](../../../tmp/i01b-active-replace-20261102/REVIEW-5B-ACCEPT-20261104.md)과 [독립 재해시](../../../tmp/i01b-active-replace-20261102/INDEPENDENT-5B-AUDIT-20261104.json)가 판정 근거다.

## 수용한 계약과 구현

[계획](../../../tmp/i01b-active-replace-20261102/PLAN.md)은 [R1~R4 보완](../../../tmp/i01b-active-replace-20261102/REVIEW-PLAN-REVISION-20261102.md) 후 [독립 계획 수용](../../../tmp/i01b-active-replace-20261102/REVIEW-PLAN-ACCEPT-20261102.md)을 거쳤다. readonly I/O 사실, busy·candidate 소유권, typed context, packet 시점 사건과 실제 활성 전제를 명확히 했다.

`OperationPrivateState.restore_completed`는 현재 owner를 busy로 표시하고 private candidate를 완전히 prepare한 뒤 같은 원입력인지 확인한다. 실패는 현재 runtime을 보존하고 candidate만 정리한다. 성공은 sim을 한 번 이전하고 candidate의 sim 소유권을 비운 뒤 이전 Salvo/Detection/Supply bindings를 해제한다. 기존 owner identity와 원 입력은 유지한다. 기존 create/prepare/close 등의 구현과 P2b를 재작성하지 않은42행 추가다.

동일 context는 seed/hz와 profile/initial_controls의 타입·값·키/삽입 순서·배열 순서 및 typed builtin/class/script identity까지 비교한다. [] controls와 명시 delegate 배열은 다르다. 이것은 국소 제한이며 전역 저장 호환이나 다른 작전 전환 정책이 아니다. 단일 동기 호출의 소유권 경계로서 멀티스레드/외부 raw sim·underscore reflection 또는 runtime 예외 복구까지 보장하지 않는다.

## 실제 실행·반례

최종 attempt2는 **actual exit0, 정상20사례·20099체크·8명명 거부·9거부호출**, failed=false다. 신규 captured/engine 로그에 SCRIPT ERROR/ERROR/누수 진단0이다. 10seed마다 POC 실제 투사체/cooldown과 Salvo-D/S 기억·진행보급/완료재고·탐지 평가 경계를 독립 property oracle로 비교한다. 빈 초기 탄약·AI 억제·적 재배치는 controlled fixture 준비이며 실제 기억/보급 효과는 코어 step으로 발생했다.

capture 후 원 owner를 더 진행시켜 실제로 달라진 runtime을 만든 뒤 같은 handle로 되감는다. 직접 checkpoint oracle와 fresh reference, sim/fleet identity·by_id·old/new module 참조, 반복 복원·alias 불간섭을 검사했다. pending은 다음 advance에 한 번 적용된다. 사건은 packet 시점의 소비 상태를 정확히 복원하므로 옛 timeline에서 이미 소비한 사건이라도 packet에 미소비로 남아 있으면 다시 drain된다. 외부 효과의 전역 dedup은 범위 밖이다.

late 빈 form·다른 유효 context·unsupported hz·busy/closed/unprepared는 정확한 오류와 기존 sim/owner/packet 불변을 확인했다. 다른 profile의 metadata-only와 키순서 두 반례 때문에8명명에9호출이며 완결 guard가 둘 다 검사한다.

attempt1은 fixture resource_path 직접 접근 ParseError로 exit1·사례미실행이다. 실패를 보존하고 Script 변수로 명시한 attempt2를 최종으로 사용한다. 새 단계 K6 중2회이며 이전 P2c5회와 구별한다. editor import는 없었다.

P2c/core/data3회귀도 actual exit0·기능 PASS. P2c는70/11553/45이고 OUT-only 복사 runner를 직접 역치환하여 기존 test와 바이트가 정확히 같았다. data의 기존 ObjectDB280/resources18 종료 진단은 남는다. 이를 깨끗한 종료로 표현하지 않는다.

## 보존·공백 게이트·한계

입력42·pre-review manifest83 SHA 불일치0, baseline3879 누락0·허용helper1개만 변경, 원 source35 변경0, 격리77 SHA/원경로부재 정합을 독립 전량 확인했다. 이전 P2c payload254 중 현재 helper만 의도된 차이가 있고 이전 ZIP SHA는 그대로다. 현재 helper/test는 실행 snapshot과 바이트 exact다.

전체 `git diff --check`는 **실제 exit2**이며 전체 PASS가 아니다. 진단은 baseline SHA와 동일한 `CHECKLIST-OPEN.md:33`의 이전 P2c CRLF 행이다. 이번 허용 helper/new test의 trailing space/tab은0이고 최종 newline도 있다. 기존 공유 파일을 수정해 진단을 감추지 않고 **보존된 기존 진단을 분리한 제한 수용**으로 판정했다. 후속 마감에서도 실제 exit2를 유지해 보고한다.

helper SHA `6be2adeb64bec7c9a89040cab5c9558219e063272df1a9e5fd00cf1dd9111441`, 신규 test SHA `e76bc22ef569ccbf969fddc92691f20d1556dab963102a85aec7c4c2d0631759`. branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, 빈 index를 확인했다. 신규 테스트는 baseline3879 밖의 자기 산출물이다.

수용 범위는 이미 공개 작업 경계를 가진 제한 owner 안의 실제 sim 교체다. FleetBattle3D의 UI/시계·AutoResolver 스레드·host/headless/replay 공통 adapter·전체 캠페인/ST01~18·운영 Cn/global cursor·외부 파일/schema·제품 공간·화면/Android·성능/사람플레이는 미완료다. 추가 코드 수정 요구는 없으며6단계 결과/체크리스트/최종 감사·압축 마감으로 진행할 수 있다. 마감 파일과 ZIP의 독립 사실 확인은 이후 별도 기록한다. 커밋/푸시/병합/브랜치 전환은 승인하지 않는다.
