# I01b-P2c 독립 5-b — 반려 및 2단계 반환

2026-11-01 KST. 판정: **현 P2c 최종 수용 반려**. 정상 70사례의 기존 증거는 유효하지만, malformed packet의 필수 분모 구조가 누락되어 정상 public 작업에서 SCRIPT ERROR를 내는 owner가 게시된다. 스펙 보완→독립 계획 심사→최소 수정→재검증→재심 순서로 돌아간다.

검토자는 `/root/independent_review`, 명시 dispatch 모델 `gpt-6-astra`이며 생산 코드·기존 검사·probe 구현/실행에 참여하지 않았다. 플레이북, CLAUDE, SESSION-HANDOFF, P2c 이관/체크리스트/PLAN, P2b 결과/심사/helper, H2-02, D04 ST01~18, I01 K06~08와 실제 코드를 대조했다. 적용 경로와 상위에서 AGENTS.md를 찾지 못했다. 이전 P2c 구현 모델의 구체 ID는 현재 파일 증거에서 확인되지 않았으므로 다른 모델이라는 사실을 추정으로 확정하지 않는다. 이번 reviewer의 모델과 구현 비참여는 별도 사실이다.

## F01 — 빈 현재 진형을 성공 복원하여 0 나눗셈 발생

대상 `core/battle/operation_private_state.gd:318~320`. `_restore`는 `form/route/form_t`의 배열 원소가 Vector2인지 검사하지만 `form`의 최소 길이를 검사하지 않는다. typed `Array[Vector2]`를 `clear()`하면 `_shape`·원소 검사를 모두 통과한다. 서비스 slice는 이 필드를 검증하지 않고, 마지막 exact 관측 비교는 이미 잘못된 입력과 복원값이 같음을 확인할 뿐이므로 오류를 발견하지 못한다.

`BattleRules.ship_pos` (`core/battle/rules.gd:118`)는 `form[i % form.size()]`를 계산한다. 제한 POC의 정상 public `issue(missile)`는 `_fire_missiles:325`→`_rand_ship:262`→`ship_pos:118`로 이 배열을 소비한다.

실행 담당이 신규 evidence-only `tmp/i01b-p2c-resume-20261101/empty-form-probe2.gd`에서 다음을 실제 재현했고 검토자가 script와 engine log를 원문 확인했다.

1. 명시 정수 편성·reinf=[]의 제한 POC를 create/capture하고 정상 packet prepare는 `ok=true`.
2. 복사 packet의 첫 fleet.form만 clear한 뒤 prepare도 `ok=true`.
3. 복원 owner의 public issue(missile)에서 `Modulo by zero` SCRIPT ERROR 6회. 그 issue도 `{ok:true}` 반환.

이는 단순 미검증 가능성이 아니라 정상 공개 작업을 실행할 수 없는 상태를 성공 반환한 재현 결함이다. 최소 구조·분모 preflight와 실패 시 owner 미게시라는 PLAN의 2·3단계 인수 조건을 만족하지 못한다. 호출자가 새 owner의 underscore 필드를 변경한 사례가 아니며, 공개 prepare 입력 packet만 변경했다.

첫 probe는 stock JSON 편성 숫자의 float 때문에 `fleet_definition_type`으로 생성 거부되어 이 반례에 도달하지 못했다. 두 번째 probe의 exit0은 반례 절차 종료이지 기능 PASS가 아니다. 두 probe는 주 runner 재시도와 구분한다. 기존 주 runner 실행은 K6 중4회이며 통과 검사를 무변경 재실행하지 않았다. editor import도 없었다.

## 최소 스펙 보완과 필요한 검사

- 지원된 복원 packet의 **모든 fleet.form은 nonempty typed Array[Vector2]**여야 하며 기존 유한값·원소 검사도 유지한다. 마지막 fleet의 빈 form도 private 상태 쓰기 전에 명명 오류로 거부하고 owner를 반환하지 않는다.
- `route`와 `form_t`의 빈 배열은 실제 정상 상태가 있으므로 일괄 nonempty 정책을 추가하지 않는다. 임의 기본 진형을 채워 성공시키거나 소비자에서 0 나눗셈만 감추는 복구는 저장 상태 동일성 계약의 해법이 아니다.
- 신규 음성 검사는 첫/마지막 fleet.form의 typed clear를 각각 사용하고 예상 오류명, owner 미반환, source·거부 packet·기존 성공 owner의 typed 값/순서 불변을 확인한다. 정상 packet 복원과 public missile 후속 실행이 SCRIPT ERROR 없이 통과하는 양성 대조를 둔다.
- 같은 배열 소비 계열을 원문으로 점검했다. stages는 길이5 검사, army_ev는 길이2 검사, swarm.pts[0]는 소비자의 size>0 guard가 있다. 현재 확정 반려 항목은 F01 하나이며 다른 기능으로 확장하지 않는다.
- 기존 helper/P2b/BattleSim/rules/allowlist/skip은 수정하지 않고 P2c owner와 신규 전용 검사만 최소 변경한다. 실제 수정 후 필요한 주 runner와 관련 회귀를 실행하고 코드·입력·정본 cache·로그 SHA를 새 증거에 남긴다. 옛 attempt4 기록은 덮어쓰지 않는다.

## 검토한 정상 증거 및 보존 상태

fresh constructor→비대상 복원→P2b slice→exact 검증 순서, 실제 script-variable coverage, source와 선진행하지 않은 target, 독립 property oracle의 typed array metadata, pending 단회 적용, 기억/보급/투사체 suffix, alias/cache 참조 분리는 원문으로 확인했다. damaged fixture는 production damage/removal 직접 호출의 controlled fixture이며 자연 발생 손실 E2E로 확대하지 않는다. canonical class 16개 경로 guard와 오염 cache probe의 fail-closed도 확인했다.

정본 attempt4의 exit0·70사례/11544체크/43거부 원문을 확인했다. attempt2/3와 오염 cache 앞선 회귀는 수용 근거에서 제외한다. 실행 담당의 `tmp/i01b-p2c-resume-20261101/preservation-pre-review.json`은 기존3660 누락0, 알려진 문서2개 차이, source35 변경0, 실행입력7 SHA 일치, 가역격리77 SHA/원경로부재 일치를 기록한다. 허용 문서 역대조와 최종 manifest는 아직 완결 대기이며 이 중간 감사만으로 최종 보존 마감을 선언하지 않는다. F01 반려는 이 보존 감사의 후속 결과와 무관하게 필요하다.

검토자가 직접 재해시한 반려 기준:

| 파일 | SHA-256 |
|---|---|
| operation_private_state.gd | d8f977b7d3a89da3071e8be96d140a44b4db4e89b20944666cb18df294f28074 |
| i01b_private_state.gd | b49662172df74adee0494840cd0a88b42249aabe4d0348e8259fa77421eb9501 |
| empty-form-probe2.gd | b359a0b20e92d8b74de4b733a382542f92a62180070b2eb5355e6806b543ec0f |
| empty-form-probe2-engine.log | 4bf76407919b9b213770608be199e21e666ca80e766c361f6b770ff76fe5423a |

이 보고서만 신규 작성했다. 원본 변경 폐기·브랜치 전환·worktree 생성·commit/push/merge 없음. 전체 I01/I01b/A04~A06는 NOT_READY, 외부 save schema는 UNCLASSIFIED를 유지한다. P2c 수용 전 다음 통합 구현으로 넘어가지 않는다.
