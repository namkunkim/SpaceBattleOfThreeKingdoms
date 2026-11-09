# I01b-P2c attempt5 독립 5-b 재심

2026-11-01 KST / **제한 private runtime 구성요소 수용**. F01 반례는 보완 계획과 최소 수정으로 해소됐다. 전체 I01/I01b/A04~A06는 NOT_READY이며 외부 save schema는 UNCLASSIFIED다. 이 판정 뒤 결과·체크리스트·최종 문서 보존 감사의 6단계 마감이 남는다.

## 독립성과 판정 대상

검토자는 `/root/independent_review`, `gpt-6-astra`다. 생산 코드·검사·반증 probe 작성/실행에 참여하지 않았다. 원문 읽기·독립 해시 대조·심사 기록만 수행했다. 원래 P2c와 이번 수정은 각각 `/root/p2c_continue`, `/root/audit_execution`의 `gpt-6.1-sol`이 수행했음을 로컬 rollout의 session_meta agent_path와 turn_context.model에서 직접 확인했다.

메타 출처는 `tmp/i01b-p2c-resume-20261101/model-independence-evidence.json`에 적힌 세 jsonl이다. 원 구현은 turn_context5개, 현재 실행은 심사 시3개, 심사자는1개의 모델값이 각각 일치했다. 현재 실행 rollout의 agent_path도 심사 시 `/root/audit_execution`으로 확인됐다. 추출 JSON 작성 당시 null이었다는 메모와 시간 차이를 구분한다. 앞선 반려 보고서의 모델 미확인 상태는 이 후속 확인으로 해소하며 이전 기록을 덮어쓰지 않는다.

원래 계획/이관/P2b 및 실제 소스 검토는 `REVIEW-5B-REJECT-EMPTY-FORM-20261101.md`, 보완 계획 수용은 `REVIEW-PLAN-AMENDMENT-EMPTY-FORM-20261101.md`를 따른다. 이번 재심은 그 스펙을 바탕으로 실제 최소 diff·최종 source·원문 로그·관측·실행 전 입력·모델·보존 증거를 대조했다.

## F01 해결

기존 `_restore`의 Vector2 배열 검사 직후 `if fleet.form.is_empty(): return "fleet_empty_form"` 한 행이 추가됐다. 모든 fleet를 순회하며 private 쓰기 전 실패한다. route/form_t가 빈 정상 상태는 계속 허용되고, 기존 typed array·유한값·원소 검사는 유지된다. 잘못된 form을 기본 진형으로 대체하지 않는다. BattleSim/rules/P2b helper는 불변이다.

신규 검사는 정상 packet으로 기존 성공 owner를 만든 뒤 첫/마지막 fleet의 typed form을 각각 clear한다. 기존 `_reject`는 실패·owner 미반환, source와 거부 packet의 typed stamp 불변을 확인한다. 추가 검사는 두 오류가 정확히 `fleet_empty_form`인지와 별도 성공 owner의 독립 oracle 불변을 확인한다. 첫 항목만 우연히 차단하는 검사가 아니며 뒤늦은 실패도 포함한다. 정상 packet 준비 및 기존70사례·공격/후속 진행 검사를 유지했다.

변경 hunk는 helper1행, test의 새 OUT·두 반례와 기존 owner 불변·45개 완결 guard뿐이다. 기존43명명 거부·allowlist·skip을 삭제하거나 완화하지 않았다. 기존 attempt4와 observations를 덮어쓰지 않았다.

## 실행 증거

`tmp/i01b-p2c-resume-20261101/attempt5-{captured,engine}.log`, `attempt5-exit.json`, `attempt5-observations.json` 원문은 **actual exit0, 70사례, 11553체크, 45명명 거부, failed=false**로 일치한다. first/last empty form 모두 `fleet_empty_form`. 신규 주 runner 로그에 SCRIPT ERROR/ERROR/누수 진단0이다. 이전11544보다 추가9체크는 정상 prepare1과 두 반례 각각 거부/불변2·오류명1·기존owner1에 대응한다.

10seed 각각 projectile/resource/memory/pending/post/damaged/terrain 7종은 그대로다. 독립 oracle은 실제 script property를 열거하고 typed array metadata·사전 키/순서·모든 동적 값을 비교한다. source와 선진행하지 않은 fresh target에 생성자→비대상 상태→P2b contacts/supply slice→exact 검증을 적용한다. pending 미실행 및 다음 step 단회 소비, 과거 기억과 실제 보급 완료/재고 지출, 진행 공격 수명과 진형 타이머 suffix, alias/cache 객체 분리의 기존 증거를 유지한다. damaged는 controlled fixture라는 한계도 유지한다.

코드 변경 후 core_rules/data_rules/i01b_service_state 3종을 재실행하여 actual exit0와 기능 PASS를 확인했다. service는 신규 OUT만 바꾼 복사 runner이며 역치환 SHA가 원 검사와 같다는 증거를 확인했다. data_rules captured log에는 기존 ObjectDB280/resources18 종료 진단이 남는다. 기능 PASS를 깨끗한 종료로 확대하지 않는다.

i01_operation_config/i01b_logical_clock/detection_rules/supply_rules 4종은 이전 canonical actual exit0 증거를 사용한다. 이 네 검사 경로는 dirty3660/새 세션dirty3823/source35에 포함된 항목이 아니므로 해당 분모에서 직접 해시 동결했다고 주장하지 않는다. 시작 dirty목록 부재, 동일 HEAD, 현재 네 경로 git status 빈값과 runtime source35/데이터/cache 불변, 신규 helper만을 바꾼 diff가 회귀 연속성 근거다. detection/supply의 기존 종료 누수 진단도 그대로 남는다.

attempt2/3와 오염 class-cache의 앞선 회귀는 계속 수용 증거에서 제외한다. 반증 probe1은 float 편성 때문에 반례 미도달, probe2는 빈 form 성공 복원 뒤 public missile에서 실제 Modulo by zero 6회를 낸 결함 증거다. probe2 exit0를 PASS로 세지 않는다. 주 runner는 K6 중5회, 별도 probe는2회다. 이번에 editor import를 실행하지 않았다.

## SHA·보존 독립 확인

- attempt5 실행 전 입력7항(최종 helper/test, 데이터3, 정본 cache, 엔진)을 직접 재해시해 불일치0. helper SHA `a1376b70c22dcf371120d44999a38b68d141bc2306d9339f1e2294e6744196ca`, test SHA `bd12cdad427ec672373ab844329bd6846e109f4d088ae007181eb24f4489403b`.
- `record-manifest-pre-review.json` 236항을 직접 재해시해 누락/불일치0. 그 파일은 최종 문서 추가 전 시점 manifest이며 이후 마감 파일까지 포함했다고 주장하지 않는다.
- `independent-preservation-rehash-20261101.json`에서 기존3660 전량 직접 재해시: 누락0, 알려진 CHECKLIST-OPEN/HTML2개만 차이. 원 source35 변경0, 가역격리77 SHA 불일치0·원경로 잔존0. 실행 담당의 수정 후 pre-final-review 감사도 같은 결과이며 새 세션3823 중 소유 helper/test2개만 변경했다.
- CHECKLIST-OPEN의 이관 한 행을 역제거한 바이트 SHA를 직접 계산해 baseline과 정확히 일치했다. HTML의 기능 JS와 CSS도 직접 문자열 비교하여 불변을 확인했다. `allowed-document-changes.json`의41개 요구 ID 보존·P01 상태/인수설명만 변경 및 진행 문구/이관 링크 차이는 해당 허용 범위다. 개인 브라우저 저장값은 건드리지 않았다.
- 격리77 CreationTime은 실행 담당의 현재 재감사와 import window 증거에서 범위밖0. 같은 원본과 보관본의 SHA 및 원경로부재를 별도 대조했다.
- git diff --check exit0(기존 LF/CRLF 경고 별도), index 비어 있음, branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`를 직접 확인했다.

attempt5-inputs 원문의 `created`는 복사된 attempt4 시각 `2026-11-01T15:43:43.9854192+09:00`이고, 실제 새 동결 시각 `created_utc`는 `2026-11-01T12:13:28.729025+00:00`이다. 초판 심사에서 PowerShell JSON 재출력이 같은 시각을 +09:00으로 변환한 것을 원문 문자열로 오인했던 설명을 원문 재확인 후 정정했다. 입력 증거 파일·SHA·실행 시각 자체를 변경한 것은 아니다.

## 수용 경계와 다음 단계

이번 수용은 신뢰된 규칙 내용·명시 편성과 reinf=[]를 쓰는 제한 POC 또는 Salvo/terrain/Detection/Supply 구성의 private fresh runtime 복원 구성요소다. 악의적 underscore reflection/thread 접근이나 임의 live sim 입양을 보장하지 않는다. 다른 활성 모듈은 명명 거부한다.

stock POC 전체/적벽 전체·전체ST01~18·운영 Cn/전역command cursor·host/headless/replay 공통 연결/활성 교체·외부 저장파일/schema·제품 공간·화면/Android·성능/사람플레이는 미완료다. 전체 NOT_READY와 UNCLASSIFIED를 유지한다. 다음 작은 통합 조각은 별도1~3 및 독립 계획 심사를 거쳐야 한다. 이 판정은 commit/push/merge 승인이 아니다.

F01의 반려→스펙 보완→독립 계획 수용→최소 구현→5-a→독립 재심 루프가 닫혔다. 추가 코드 수정을 요구하지 않으며 6단계 결과·체크리스트·문서 보존 마감으로 진행할 수 있다.
