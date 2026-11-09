# 원본 이관·실제 검사 독립 검토

2026-10-28 KST / data_rules_review / **이관과 P0·P1 성과 수용. P1 전용 clock/core 2종 gate 해소. 원본 확대 7종 전체 gate는 data_rules 실패로 미통과.**

검토자는 구현·복사·검사 실행 및 결과 문서 작성에 참여하지 않았다. 사용자의 “원본에서 작업해” 지시 후 primary 이관 계획을 2/3단계에서 검토하고, 실행자의 실제 증거·원본 diff·보존 SHA와 문서 범위를 대조했다. 검토자는 이 독립 리뷰만 작성했다. 과거 관리 작업트리의 독립 리뷰 원문은 당시 판정으로 보존하며 이 문서가 최신 원본 결과를 구분한다.

## 대상과 보존

작업 대상은 `C:/WorkSpace/SpaceBattleOfThreeKingdoms`다. 실행자 감사의 main/HEAD는 `8292805143f4561a4f5258d40b7b94adf4ff5802`다. 최신 원격 확인이나 깨끗한 checkout이라는 뜻은 아니다. 이관 전 실제 tracked dirty14·untracked946, 총960파일의 경로/상태/SHA가 primary-before.json에 동결됐다. 옛 dirty14라는 숫자만 가정하지 않았다.

port-manifest.json의 정확12경로를 검토했다. 수정 대상은 battle_sim.gd·poc_corridor.json·tests/data_rules.gd·CHECKLIST-OPEN.md 4경로이며 승인 기준 before SHA와 primary 실제 값이 일치했다. 나머지8경로는 기존 부재를 확인했다. source SHA는 앞서 독립 수용한 artifact와 일치한다. before/source/after 가드 복사이며 기존 파일 충돌이나 context merge를 숨기지 않았다. 이후 최신 원본 실행 결과를 반영한 P1 결과/CHECKLIST 2파일 외 10파일은 승인 복사 SHA를 유지한다. 별도 본 리뷰를 추가한 최종 허용 목록은13경로다.

검토자가 frozen960파일의 현재 SHA를 전량 직접 재읽었다. 변경0·누락0이며 bundle_layout도 보존됐다. 실행자의 pre-review-audit.json은 HEAD/branch 불변·status_removed0·예상 외 status 추가0·허용 diff 공백 검사0을 기록한다. tmp의 새로운 증거는 별도 출력으로 구분한다. 검토자가 Git을 변경하거나 커밋·브랜치 전환·푸시를 실행하지 않았다.

## 코드·준비 계약 대조

기존 승인 변경은 fallback 170을 정식 POC rules로 옮긴 생산1줄/데이터1키, 실제 추격10사례 및 부분시계 runner다. 이관 diff를 읽어 숫자 allowlist·skip·별도 hold 경로를 완화하지 않았음을 확인했다. 신규 clock runner와 P0 도구·과거 독립 리뷰는 수용 원문 SHA 그대로다. 기존 무관 bundle_layout 변경을 포함한 원본 환경에서 실행했으며 그 dirty를 승인 코드로 통합했다고 판정하지 않는다.

old P0 source freeze21과 primary 이관 전 차이는 예정된 battle_sim 170 리터럴 한 건뿐이었고 이관 후21소스는 일치했다. P0 도구는 primary에서 실제 exit0, 19모듈·283선언·14앵커를 보고했다. primary-inventory.json SHA는 `03a409ab07a2aeea3272afde67fb441f6ad9bc38e550071f17ce01ed0c75200c`다. 과거 재고와 직접 텍스트 내용 대조상 값/선언 차이는 없고 readiness 키 순서만 달라 동일 바이트 재현성을 주장하지 않는다. 이 재고는 frozen21 범위이며 무관 bundle_layout나 전체 snapshot/O07 완료의 증거가 아니다.

## 실제 원본 검사

증거 루트는 `C:/WorkSpace/SpaceBattleOfThreeKingdoms/tmp/i01b-primary-port-20261028`다. raw-gate-results.json의 각 실제 exit와 전체 출력, test-results.json 및 로그 원문을 직접 읽었다. 검토자가 full captured-output와 engine log의 SHA를 7종 각각 대조했고14건 모두 일치했다. 검사나 Godot를 검토자가 재실행한 것은 아니다.

| 검사 | 원본 실제 결과 |
|---|---|
| core_rules | exit0, CORE_RULES_PASS |
| i01b_logical_clock | exit0, 10seed×3속도×정지유무2=60사례, trace50/100/150·tick2/end150 PASS |
| i01_operation_config | exit0, 설정60·명명거부24·추가17·CHECKS326 및 a01~a06 PASS |
| data_rules | exit1, 첫 core 리터럴 검사에서 bundle_layout.gd 11건 |
| hold_distance | exit0, HOLD_DISTANCE_PASS |
| commander_ai | exit0, COMMANDER_AI_PASS |
| battle_flow | exit0, BATTLE_FLOW_PASS |
| P0 선언 재고 도구 | exit0, 19모듈·283선언·14앵커 |

Godot 버전 표식은 `4.7.2.stable.official.ed1daf0bf`다. 원본 core 종료0과 clock 종료0을 실제로 확보했으므로 이전 P1 전용 2종 gate의 종료 증거 결측은 **현재 원본 실행에서 해소**됐다. 과거 관리 작업트리의 core exit=null 이력은 고쳐 쓰지 않는다.

## data_rules 실패의 범위

11건은 전부 `core/battle/bundle_layout.gd:15~37`이다. 해당 파일은 이관 전부터 tracked dirty였고 before/after SHA가 모두 `52fde94aa9d2cca411ee038856643934990aac7de26ad7141ce3f9e61e379101`로 직접 일치했다. 이관한 battle_sim의170 리터럴은 전체 core 스캔에서 보고되지 않았다. 이 정적 보존 사실은 변경 전 primary에서 data_rules를 실제 실행했다는 뜻은 아니다.

data_rules는 첫 검사에서 반환하므로 이번 원본 실행의 프로필 키/편성·시나리오·추격10사례 등 후속 항목은 미실행이다. 이전 관리 작업트리의 DATA_RULES_PASS와 원본의 이번 FAIL을 구분해야 한다. 해당 bundle 파일을 고치거나 allowlist를 완화해 이관 gate를 초록색으로 만들지 않았다. 그 무관 변경의 정당한 데이터/기하 규칙 정리는 별도 후속이다. 따라서 **확대7종 전체 gate PASS 또는 원본 data_rules 기준선 해소 완료라고 판정하지 않는다.**

## 진단·기록·완료 경계

hold/AI/flow의 도구 전체 출력에는 종료 ObjectDB/resources-in-use 진단이 있고 flow에는 TRACE log-open 경고가 있다. 기능 PASS와 종료0은 확보했지만 깨끗한 종료·trace 파일 기록 성공·누수 회귀 부재를 보장하지 않는다. Godot --log-file 엔진 파일에는 정리 진단 일부가 빠져 있어 원래 엔진 로그를 유지하고 전체 도구 반환 문자열을 별도 *.captured-output.log와 raw JSON에 보존했다. 두 종류의 경로/SHA가 명시돼 진단을 삭제하거나 재실행으로 대체하지 않았다.

최신 P1 결과와 CHECKLIST는 P0 수용·부분시계60 성공·현재 원본 core 종료0을 완료로, 원본 data_rules 전체 gate와 원 I01b 실제 통합은 미완료로 구분한다. 이 기록 범위에 잔여 실질 반려사항은 없다. 실행자는 본 raw 리뷰를13번째 파일로 배치하고 final-delivery-audit.json에 최종13경로·기존960SHA/status 보존 결과를 남긴다.

원 전체 I01/I01b 및 A04/A05/A06는 NOT_READY다. 실제 host/headless/replay 어댑터·checkpoint 복원/suffix·지속 상태·product 공간/선체 외곽·PC 화면·사람 플레이를 완료했다고 표시하지 않는다. 커밋·병합·푸시와 PC 실험 통합은 이번 범위가 아니다.

되먹임: 이관 전 실제 dirty 전량을 동결하고 source/before가 다르면 덮어쓰지 않는다. 수용했던 고립 작업트리 결과와 기존 dirty가 있는 원본 결과를 구분하며 PASS 표식·실제 exit·미실행 후속 항목을 각각 보존한다.