# P02 attempt1 반례 보완 — 독립 계획 수용

검토일 2026-11-07 KST. 판정: **최소 보완계획 수용, 지정 hunk 구현과 attempt2/K6 실행 가능.** 실제 수정·검사 통과·최종5b 수용은 아직 아니다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다.

검토 대상은 PLAN-ATTEMPT1-REVISION.md SHA256 `d33a68ae61890ef01ff3d0d041713c3b7fa9e65e3914eb4502aa43b190f50244`다. 계획 안의 2026-11-05는 작성 기록이며 이 독립 재심일과 구분한다. 기존 PLAN v2·REVIEW-PLAN/V2·실패 시도 원문은 변경하지 않았다. 심사자 `/root/independent_review`는 계획 작성·구현·Godot 실행에 참여하지 않고 이 새 판정만 작성했다. 요청 심사 모델과 실제 runtime 모델 메타 확인은 이전 심사의 구분을 유지한다.

## 실패 증거와 현재 원문 대조

attempt1-exit.json은 actual_exit1/attempt1/limit6이다. captured log를 직접 읽고 SHA256 `8aaa1cb043f763b3ad730c8b2b507ee3d23dcef3a5e946950e6c9dda1217571b`를 재계산했다. SCRIPT ERROR 8112개는 모두 Dictionary의 dead 접근 오류이며, 별도 assertion은 `P02_ADAPTER_FAIL timeout retains actual clock/end` 1개다. cases8/checks16804/rejections32/natural6/timeout2는 실패 시도 관측이고 인수 성공 분모가 아니다.

현재 detection.gd, battle_projection.gd, battle_sim.gd, autoresolve.gd, p02_headless_adapter.gd의 SHA를 attempt1-inputs.json과 직접 비교하여5개 모두 일치함을 확인했다. 따라서 아래 원인 분석은 실패 당시 동결 소스와 같은 코드에 근거한다. 이 확인은 전체 보존감사나 회귀 실행을 대신하지 않는다.

`BattleProjection.contact`는 적 접촉의 dead를 제공하지 않으나 기존 policy_commands는 모든 squadron에서 먼저 s.dead를 읽는다. run_operation은 none에도 이 정책을 호출하므로 같은 오류에 노출된다. 기존 runner의 정책 기대 경로도 같은 생산 함수를 호출하며 일부 구간에서는 한 명령 배열을 두 runtime에 모두 넣었으므로, 상태가 같다는 검사만으로 이 정책 오류를 검출할 수 없다. 계획이 이를 공통 원인으로 분리한 판단을 수용한다.

## 공개 탐지 의미·정보 경계

Detection.foes는 contacts를 ID 순서로 열거할 때 매 조회 실제 t.dead를 제외한다. 따라서 **현재 공개 projection에 존재하는 contact**를 정책뷰 내부에서 dead=false로 취급하는 것은 현 공개 목록 생성 계약에서 도출된다. 새 helper가 private 상태를 읽는 것이 아니며 모든 과거 기억 DTO에 생존을 일반 보장하는 계약도 아니다. 이 근거는 현 소스에 한정한다.

Detection.can_target은 confirmed/estimated만 허용한다. lost는 공개될 수 있어도 표적 지정 가능한 접촉이 아니므로 먼저 제외해야 한다. 이는 PocEnemyAi._foes의 기존 lost 제외 의미와도 일치한다. confirmed의 현재 공개 위치와 estimated의 공개 기억 위치를 그대로 사용하고, 실제 비공개 좌표·건강·정확척수 등으로 보충하지 않는다. 여기서 표적 지정 가능은 실제 사거리·탄약·명령 수용까지 보장한다는 뜻이 아니다.

따라서 신규 opt-in helper에서 none 즉시 반환, attack5용 deep detached 정책뷰 작성, confirmed/estimated contact에만 dead=false 보완, lost 제외 후 기존 정책을 재사용하는 좁은 수정을 수용한다. 공개 projection/owner/출력/저장 packet은 변경하지 않는다. full squadron의 기존 dead 및 순서를 유지하며 5초 경계·strict-less 거리 tie·attack 후 missile/fighter 순서도 보존한다. legacy 정책 본문이나 탐지 모듈을 수정할 이유가 없다.

## 독립 정책 oracle·timeout 수용

P01~P09의 수제 public DTO와 하드코딩 기대명령은 none, full dead 필터, confirmed/estimated, 가까운 lost 제외, lost만 존재, 비주기, 동일거리 순서, 생존아군 없음의 의미를 직접 구분한다. 생산 정책으로 기대명령을 생성하지 않고 입력 typed bytes 불변을 검사하므로 이번 오류를 단순 양쪽 동일 실행으로 숨기는 반례를 보강한다.

정상8의 구현 해석은 명확히 다음과 같다. 실제 소비자/owner 쪽은 생산 opt-in helper의 명령을 queue하고, raw BattleSim 쪽은 공개 raw projection에서 **독립 reference가 따로 만든 명령**을 queue한다. 한 번 만든 생산 또는 reference 명령을 양쪽에 모두 넣는 방식은 정책의 독립 oracle이 아니다. reference 자체도 수제 P01~P09 정답과 대조한다. 기존 issue/queue·상태/시계/이벤트 비교는 유지한다.

모든 조합의 max_ticks1을 timeout으로 단언한 것은 타당하지 않다. 실제 첫 tick 자연종료를 인정하고 실제 end/clock을 raw oracle과 비교하는 수정은 기대값 완화가 아니라 잘못된 전제의 제거다. timeout 보장은 별도 명시 입력 T01/T02로 유지하므로 검증 책임을 삭제하지 않는다.

제안된 timeout 입력은 POC world3400×2300 안의 (500,500)/(2500,500), 양측30척·flag=true, reinf=[]이며 거리2000은 기본 사거리300/미사일480/함재기380보다 크다. 실제 core의 하위걸음 시계와 승패 조건, POC AI를 읽어 한 tick 생존·비종료 예상의 근거를 확인했다. **direct controls가 PocEnemyAi를 비활성화한다고 해석하지 않는다.** 현재 POC AI는 별도 control 비활성 조건이 없으므로 이 fixture의 근거는 거리·초기 생존 상태이며 raw1step도 같은 AI를 실행한다. commands0은 외부 명령 log의 수이며 모든 내부 AI 동작이나 사건0을 뜻하지 않는다.

T01/T02에서 실제 tick1/clock100/over=false/end_tick=-1/end_ms=-1/timeout을 consumer와 raw 양쪽으로 확인하고, 어긋나면 expected를 억지 변경하지 않는 계약을 수용한다. fixture 수치는 검사용 authoring이며 제품 수치·runtime 변환이 아니다.

## 허용 범위와 다음 게이트

추가 변경은 autoresolve의 신규 opt-in helper와 해당 호출, 신규 p02 runner의 독립 정책 oracle/P9/T2/출력경로, timeout fixture·provenance뿐이다. adapter의 입력계약, private owner/restore/context, legacy policy/play/play_rc/통계, 기존 data·allowlist/skip·HTML·cache는 보존한다.

attempt1 소스/입력/원문 로그/exit/관측을 남기고 attempt2 입력·코드·엔진/cache SHA를 별도 동결한다. 보고 분모는 정상matrix8·정책micro9·timeout2·APInegative32를 분리하고, 기존 CLInegative14/성공2/legacy1쌍과 회귀는 별도로 유지한다. attempt2 actual exit0과 SCRIPT ERROR0/assertion ERROR0, 정확 분모 완결이 모두 필요하다. 자연종료/timeout 관측 수는 결과를 보기 전에 성공 기준에 맞춰 고정하지 않는다.

CLI services 성공의 새 helper 사용, legacy 전후 exact 비교, 최소 회귀와 독립 최종5b, 최종 보존감사·기록·압축/closeout은 후속이다. 이 재심으로 통과 처리하지 않는다. K6·사용량 제한 즉시보고/반복중단과 전체 미완료 경계는 계속 적용한다.
