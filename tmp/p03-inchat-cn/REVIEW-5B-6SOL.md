# Cn 독립 5b 재심 — GPT-6 Sol

판정: **정적 조사 게이트의 기존 attempt-02 증거 수용**. 이 판정은 제품에서 자연적인 동일 owner 경합이 없다는 런타임 증명이 아니다. 원본·공유 코드는 수정하지 않았고 재실행하지 않았다.

## 집계 모순의 출처

`attempt-01/result.json`과 `attempt-02/result.json`은 SHA-256 `fa1ca3eeb7240ae90ea62b50b76331036e809e613f45fcfce7ed1ab6097c4e54`로 바이트가 같고 파일 수정 시각도 같다. 두 폴더의 `omit.json`, `promote.json`, `missing.json`과 각 delta 파일도 각각 동일하다. `RESULT-PROVENANCE-CORRECTION.md`에 기록된 `Copy-Item attempt-01/*.json attempt-02`와 일치하는 보존 흔적이다. 호출 명령 원문은 이 파일 묶음에 독립 보존되어 있지 않으므로 명령 실행 자체는 정정자의 기록에 의존한다. 그러나 두 번째 시도의 개별 stdout/stderr/exit 및 전후 스냅샷과 복사된 `result.json`의 내용이 명백히 구별되어, 후자를 두 번째 시도 집계로 쓰지 않는 정정은 충분하다.

`attempt-01`의 normal/omit/promote/missing 실제 exit는 모두 2이며 stderr는 모두 `source scope drift`다. `attempt-02`의 같은 순서는 **0/1/1/2**다. normal stdout은 `PASS: 6 routes, 4 comparisons, anchored scope`, omit/promote stdout·stderr는 비어 있고 missing stderr는 `missing anchor: missing-evidence.gd: var candidate_sim := BattleSim.new`다. `run_gate.py`의 분기와 부합한다.

두 번째 시도의 before/after stdout SHA-256은 모두 `8f08554ec1b7809f5f5351fb7d39a86608b0381c838c7fea116272f73c287836`이고 JSON 내용도 같다. 각 snapshot exit는 0, HEAD는 `0be09755b70378286105972f35ac5b7031715664`, 생산 파일 95개와 고정 문서 3개를 포함한 해시 항목은 98개, 정렬 검색 결과는 32행이다. `attempt-01`의 전후 snapshot 해시는 달라 실패 보존이 타당하다.

입력 변이는 기본 `ledger.json`에서 각각 제한 worker 행 제거, OWNER_PUBLIC 자기 비교의 `same_owner_product_race`만 false→true, RAW_HOST 첫 anchor 경로만 `missing-evidence.gd`로 치환한 한 가지다. 두 번째 시도의 입력 사본은 첫 시도와 바이트가 같다. 6개 행 ID와 4개 비교쌍, 별개 owner·worker guard 및 취소 mutex 구분은 원장과 원문 정적 범위에 맞는다.

게이트는 anchor 문자열의 존재와 형식을 검사한다. 호출 의미, 동적 별칭, 범위 밖 소비자, 실제 경합의 도달성을 검증하지 않는다. 전체 Git 전후 상태나 범위 밖 파일 불변도 이 증거로 주장하지 않는다. 사용된 시도는 2/3회이며 추가 시도는 필요하지 않다.
