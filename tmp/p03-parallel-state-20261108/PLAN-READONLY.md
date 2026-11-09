# P03 읽기 전용 선언 누락 검증 계획

이 계획은 PLAN.md의 런타임 조각을 보류하고 REVIEW-PLAN.md의 반려를 스펙에 반영한다. 상태는 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED다.

## 고정 범위와 oracle

범위는 BattleState 최상위 28 = scalar 23 + 배열 3 + 캐시 2, Missile 10, Swarm 8, FleetState 121, TickClock 4, BattleRng 1의 총 172개 (파일, 클래스, 이름)이다. STATE-LEDGER-S1.md의 명시 이름 목록을 독립 리뷰어가 동결 원문에서 대조한 뒤 수기 oracle로 수용한다. 검출기는 선언 개수가 아닌 전체 정규 튜플 집합을 비교하고 정확한 차집합을 보고한다. 중첩 클래스와 최상위의 이름이 같아도 서로 다른 튜플이다. 선언 oracle과 capture 목록은 별개다. Clock/RNG 선언은 이 조각에 들어가며 host 복원과 RNG 수치 동등성은 후속이다. 기존 31파일·294개 감사는 별도 역사적 범위다. 이번 결과를 합산하거나 전체 coverage로 확장하지 않는다.

| 사례 | 입력 및 독립 기대 |
|---|---|
| 양성 1 | 동결 원문 네 파일과 승인된 172개 튜플 oracle. 누락 0, 추가 0, 실제 exit 0 |
| 누락 음성 1 | 동결 BattleState를 전용 폴더에 복사한 후보에서 최상위 `var _idx_n := -1` 한 선언만 제거. 누락 튜플 BattleState/_idx_n 1, 추가 0, 실제 exit 1 |
| 동일 수 치환 음성 1 | FleetState 복사본의 `var target_id := -1`을 `var target_id_probe := -1`로 변경. 누락 FleetState/target_id 1, 추가 FleetState/target_id_probe 1, 실제 exit 1 |
| 도구 실패 대조 1 | 후보 manifest에서 FleetState 경로를 존재하지 않는 전용 파일로 가리킨다. 입력 오류, 정상 비교 결과 미발행, 실제 exit 2 |

동결 생산 원문에는 변형을 적용하지 않는다. 승인 후 fixture 변형 지점이 각각 한 번만 맞는지, 원문과 후보의 diff가 지정 1행뿐인지 검사한다. 비교는 이름·클래스·파일의 대소문자를 구분한다. 정적 변수 선언만 대상으로 하며 동적 Dictionary 키·effect의 완전성은 S4 읽기 원장과 후속 계획에 남긴다.

## 5a 계약

조각 소유는 이 전용 폴더의 향후 `readonly_gate.py`, `oracle-approved.json`, `cases/`, `runs/`에 한정한다. Godot, import/cache 및 프로젝트 설정을 사용하지 않는다. 구현/실행 전에 reviewer가 받아들인 oracle, Python executable, runner, four source, case inputs와 manifest를 SHA256으로 동결한다. manifest SHA는 별도 고정 값과 대조하고 manifest의 필수 경로 집합 및 누락·중복을 검사한다. 저장소 상대 경로를 슬래시 정규화하고 Windows의 대소문자 동일 경로를 중복으로 처리한다. 전용 폴더의 후보 경로는 승인된 복사본만 허용한다. 기존 광역 source-freeze.json은 기록으로 보존하며 실행 입력으로 재사용하지 않는다. READONLY-SOURCES.sha256은 조사 근거 및 기존 5개 원장의 해시 목록이며 승인 manifest와 별개다.

실행 계획은 다음과 같다. 파일은 독립 수용 후 작성한다.

```powershell
$ErrorActionPreference = 'Stop'
$d = 'tmp/p03-parallel-state-20261108'
$python = (Get-Command python -CommandType Application).Source
& $python "$d/readonly_gate.py" --manifest "$d/readonly-manifest.json" --manifest-sha256 <approved-hash> --run-cases --out "$d/runs/attempt-01"
$actual = $LASTEXITCODE
if ($actual -ne 0) { exit $actual }
exit 0
```

suite는 4 사례를 별도 자식 프로세스로 실행하고 예상·실제 exit, 정확 차집합, stdout/stderr를 비교한다. 하나라도 불일치하면 suite 자체가 비정상 종료한다. 사전/사후 SHA 및 HEAD가 일치해야 성공이다. 경로 부재와 hashing 오류는 비교 성공으로 전환할 수 없다. 재시도 K=3으로 각 시도의 원문/해시/로그를 보존한다. 사용량 제한이면 즉시 보고하고 반복을 중단한다.

독립 5b는 먼저 원문·oracle·입력·기대값을 심사한다. 수용 전에 runner를 작성하거나 fixture를 실행하지 않는다. 사후 독립 심사는 실제 exit와 지정 mutation이 올바른 누락을 잡았는지 대조한다. S2/S3의 증원·시간·RNG·restore·원자성과 S4 활성 모듈 검증은 미실행이다.
