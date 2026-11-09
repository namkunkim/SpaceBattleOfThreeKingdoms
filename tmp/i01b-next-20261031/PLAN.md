# I01b-P2b 계획 — 탐지·보급 부분 상태 인메모리 복원 구성요소

2026-10-31 KST / 0~3 조사·계획 / 독립 계획 심사 전 코드 작성 금지 / 코드 K6.

## 0. 기준과 보존

- 원본 C:/WorkSpace/SpaceBattleOfThreeKingdoms에서 계속한다. 현재 branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 비어 있음. 새 브랜치/작업트리/커밋/푸시는 이번 범위가 아니다.
- 플레이북, CLAUDE, SESSION-HANDOFF를 읽었다. 저장소 및 상위 경로의 적용 AGENTS.md는 발견하지 못했다. 기존 공유 dirty는 UI·자산·설정 등이며 되돌리거나 포함하지 않는다.
- `tmp/i01b-next-20261031/before.json`: 추적 변경/미추적 3594경로 SHA 동결. 이 증거 폴더 자체만 제외했다. 기존 파일·기존 검사 전체를 보존한다. HEAD의 새 helper/test 경로 미존재도 구현 전에 재확인한다.
- 권위: H0/H1/H2, I01-READINESS K03/06/07/08·S10, D04 ST11/ST14, P0/P1/P2a 결과와 독립 심사, feature 재현 문서. P2a의 B0는 C0가 아니고, 선언 재고/초기 관측은 저장 계약이 아니다.

## 1. 의도와 명시한 가정

기존 비초기 탐지 기억과 보급 작업 진행의 보존 책임을 실제 코드로 좁게 검증한다. 관측만 추가하는 대신, 미래 전체 복원 계층이 호출할 수 있는 **부분 인메모리 capture/preflight/restore helper**를 만든다. 기존 코어의 실행 경로는 연결/수정하지 않는다.

가정은 호출자가 이미 생성하고 필요한 비대상 상태를 맞춘 별도 target을 소유하며, step/issue가 끝난 호출 구간에서만 helper를 사용한다는 것이다. helper는 실제 K07 전체 커밋, command_seq, C0, 외부 저장파일/스키마, 독립 전투 로드·host/replay adapter를 구현하지 않는다. config/hz/seed/tick/clock/roster 가드는 필요한 조건일 뿐, 전체 상태가 같다는 충분조건이 아니다.

특히 sup_*10 외의 ammo/wch/stages/hit_tick/healed_wound/healed_mod/supplied, 위치·이동·무기/사기·다른 모듈/명령·사건은 호출자의 선행 복원 책임이다. 이 helper로 ST11 전체나 A06을 통과했다고 주장하지 않는다. harness에서는 해당 외부 상태가 같은 두 sim을 실제로 함께 전진시킨 뒤 선택 slice만 훼손해 helper의 책임 범위와 suffix 효과를 검증한다.

새 게임 수치/제품 공간/회복·일정 정책은 정하지 않는다. typed Dictionary/Array/Vector2를 가진 내부 packet은 파일 저장 표현이 아니며 O07 wire schema/정규형/버전 호환 정책은 미정으로 남긴다. 내부 helper scope/version 태그는 잘못된 packet을 거부하는 국소 API 식별자다.

## 2. 범위·상태 분류·API 체크리스트

신규 `core/battle/operation_service_state.gd` 하나에 다음 제한된 정적 API를 둔다: `capture_partial(sim)`와 `restore_into_prepared_target(target, packet)`. 성공/오류는 명시한 Dictionary 결과로 반환하고 암묵 기본값/POC fallback을 하지 않는다. capture도 실제 원본 형태가 올바른지 검증한다.

| 상태 | 이번 책임 | 근거/제한 |
|---|---|---|
| Detection.contacts[2]의 실제 int 표적키와 seen/pos/state/conf_bp/err_r | PRESERVE_EXACT: 깊은 사본 capture, 실제 타입/순서 그대로 복원 | detection.gd `_eval/_store`, D04 ST14. 현재 적 위치로 기억을 다시 평가하지 않음 |
| 각 함대의 sup_src/sup_prog/sup_since/sup_still/sup_pos/sup_n/sup_ammo/sup_mat/sup_hold/sup_first | PRESERVE_EXACT: roster 순서와 ID로 묶어 검증 후 동적값 최종 적용 | fleet_state.gd:115~124, supply.step. 이는 ST11의 선택 부분이며 외부 자원/손상/수리누계 복원은 아님 |
| Detection._period/_conf0; Supply.ship/need/light_ticks/still_eps/bases | RECONSTRUCT_THEN_VALIDATE: 생성 완료 target의 실제 값과 원본 capture 값을 정확 대조 | 같은 cfg/hz/rt/roster에 대한 생성자 계산식. live target에 생성자를 다시 실행하지 않음. base 소유 변경 정책/운영 시설 복원은 범위 밖 |
| module.sim / cfg / Detection.terr | REBIND_EXISTING_TARGET: 이미 target 생성자가 가진 참조를 검증·유지 | source 객체 참조를 packet에 넣지 않음. target의 sim/config 참조 소유 확인. sim.terrain이 없는 경우 Detection의 독립 BattleTerrain fallback도 실제 생성자 분기대로 판정 |
| 양 모듈 부재/하나만 활성 | OBSERVED_MODULE_LAYOUT: 존재 여부 명시·동일 layout에만 적용 | 기존 생성자 분기 유지. packet은 비활성을 임의 활성화하지 않음 |
| 나머지 S/ST 상태, 운영 checkpoint, 외부 save/replay | OUT_OF_SCOPE / UNCLASSIFIED | 전체 I01b/A04~A06 NOT_READY 유지 |

구현 성공 체크리스트:

- [ ] packet은 객체/Node/외부 리소스 참조를 포함하지 않고 원본·target과 mutable alias가 없다. 정수/float/Vector2의 실제 타입·값 및 배열/Dictionary 순서를 보존한다. JSON 왕복/사후 반올림을 oracle로 쓰지 않는다.
- [ ] header/scope/version, 모듈 존재 layout, profile/seed/hz/tick/clock_ms, roster ID/side/faction 순서, 실제 cfg(D/S 및 필요한 rt 출처), 재구성된 derived 값이 맞지 않으면 오류로 거부한다. caller가 나머지 상태를 맞췄다는 보장은 별도 선행조건이다.
- [ ] missing/extra 필드·정확 타입·유한 좌표/오차·허용된 접촉 상태·범위·target ID/공급원 key/sup_first 참조를 검사한다. source에 존재하는 실제 값/생성분기만 사용하고 의미상 정수를 절삭하지 않는다.
- [ ] 모든 packet과 target을 preflight한 뒤에만 선택값을 적용한다. 마지막 contact/마지막 fleet가 잘못된 경우에도 앞 항목이 먼저 적용되지 않음을 부정 검사한다. 실패 시 target 전체 관측값·사건·원본 packet 불변.
- [ ] restore는 생성자/step/issue/_eval/_complete/emit를 호출하지 않고 선택값만 적용한다. 기존 target 모듈·fleet 객체와 비대상 상태·명령/사건은 불변, target 참조는 source로 바뀌지 않는다.
- [ ] SupplyCore constructor 완료 → derived/참조 검증 → 동적 sup_* 최종 적용 순서를 API명/주석/검사로 분리한다. 복원 뒤 생성자 재호출은 재고를 초기화하는 잘못된 순서임을 부정 대조로 검출한다.
- [ ] 같은 packet을 다시 적용해도 선택값 외 효과/지출/사건이 추가되지 않는다. 이는 전체 작전 멱등성 보장과 구분한다.

## 3. 구현 조각·harness·5-a·5-b

소유 경로는 신규 helper, 신규 `tests/i01b_service_state.gd`, 신규 `docs/battle-core/pc-campaign-design/I01B-P2B-RESULT-20261031.md` 및 독립 리뷰 파일, CHECKLIST의 좁은 완료행, 이 evidence 폴더뿐이다. 기존 BattleSim/Detection/Supply/FleetState/설정/시나리오/기존 검사는 수정하지 않는다. 기존 검사 allowlist/skip 확장 금지.

의존 순서: 계획 독립 수용 → 신규 helper+검사 → 5-a → 독립 5-b → 결과/체크리스트·최종 SHA 기록. 실패는 같은 조각 최대 K6, 5-b 반려는 스펙으로 되돌아간다.

신규 harness는 기존 SalvoFixture·실제 combat 설정을 재사용한다. 테스트용 편성/위치는 기존 detection_rules/supply_rules fixture에 대응하며 제품 좌표/밸런스를 확정하지 않는다. 기존 P1/P2a 10seed를 기본으로 한다.

1. 탐지 fixture: 실제 step/_eval로 nonempty confirmed→estimated→lost 기록을 만든다. 숨은 적은 실제 위치를 옮긴 뒤 기존 기억 pos/seen이 다른 상태를 확보한다. 평가 주기 경계를 지나는 suffix에서 source와 복원 target의 전체 지문 + 실제 접촉값 + 사건 순서를 직접 비교한다. 복원을 생략하거나 기억을 현재 위치로 바꾸면 대조군이 갈라져야 한다.
2. 보급 fixture: 실제 빈 탄약 손님과 공급원을 두고 실제 배정/진행을 만든다. 완료 전·완료 직후의 선택 slice에 대해 source/target 동일 외부 상태를 선확인하고 target slice만 의도적으로 훼손→restore한다. suffix는 실제 주기 완료/지출/배정 해제 경계를 넘어야 한다. 실제 공급원 재고 변화와 ammo/supplied/사건을 source와 대조한다. 복원 생략·생성자 역순은 차이를 검출한다. 외부 상태 손상은 helper가 복구하는 것처럼 시험하지 않는다.
3. null/단일 활성 모듈 fixture와 잘못된 cfg/시간/seed/ID/layout·malformed late entry·NaN/Infinity·순서/참조 등의 거부 fixture. 각 거부는 mutation 전후 전체 선택값, 명시한 외부 field, 사건/명령 배열을 직접 비교한다.
4. capture snapshot을 바꿔도 원본 불변, 적용 후 packet을 바꿔도 target 불변, target 변경이 source에 전달되지 않음, 모듈 참조 identity가 target 소유임을 검사한다. 실제 비교와 typed 진단 JSON은 구분한다.

5-a는 신규 runner(실제 exit/전체 로그/관측·거부 개수)와 관련 기존 `core_rules`, `data_rules`, `i01_operation_config`, `i01b_logical_clock`, `detection_rules`, `supply_rules`를 실행한다. 신규 class 인식 준비가 필요하면 Godot headless import를 수행하고 실제 exit·권한진단을 구분한다. 일반 권한 실패가 권한 문제면 정식 escalation으로 재시도하며 승인 우회 금지. 각 로그와 code/config/입력 SHA를 기록한다. 코드 정적 검사와 `git diff --check`, before3594의 허용외 SHA/누락 검사를 수행한다. 기존 ObjectDB/resources 진단·TRACE 미검증을 감추지 않는다.

5-b는 독립 검토자가 source/정확 diff, 선택 필드 분류·외부 선행조건, 실패원자성/alias·참조재결합, 실제 활성 trace와 부정 대조의 차이, suffix/events 비교의 oracle 한계, 실제 exit/log SHA 및 기존 변경 보존을 대조한다. 이 helper가 임의 target이나 전체 저장물을 복원하는 것처럼 기록되면 반려한다.

## 완료 경계와 다음 통합

이번 완료는 ST14 기억과 ST11 sup_*10 선택 slice의 부분 인메모리 복원 구성요소 및 그 조건부 suffix 증거다. 전체 C0/Cn/운영 checkpoint/host·headless·replay 공통 어댑터·명령 커서·전체 필드 복원/제품 공간은 계속 미완료다. 화면/Android export/플레이/성능/전체 저장지원 PASS를 주장하지 않는다.

다음 전체 coordinator는 비대상 S/ST의 capture/재구성 계약을 채우고 동일 경계에서 모두 검증한 뒤 private target에 부분 helper를 적용하고 전체 상태 검증 후 원자적으로 게시해야 한다. 공개 host에 이번 helper만 직접 연결하면 안 된다. 새 수치·일정·복원 파일 형식을 이번에 임의 확정하지 않는다. 후속 커밋·푸시도 현재 지시 범위로 자동 실행하지 않는다.