# A06 지도 표시 시험 인계

`PLAN.md`, `REVIEW-PLAN.md`와 `RESULT.md`를 먼저 본다. `attempt-01/command.json`, `run.json` 및 stdout/stderr가 실제 실행 증거이고 동결 원문과 전후 비교는 `MANIFEST.json`, `attempt-01/input-before.json`, `input-after.json`에 있다. `run_gate.py`와 `map_delivery.gd`는 P03 전용이며 공유 파일 변경이 없다. 확인 기준은 실제 exit 0, 3개 사례·15개 단언, 진단 0, engine 본체와 console 구분, 별도 user data 및 입력 99개 일치다. K3에서 1회만 사용했다.

지도 표시 전 이탈 경계와 슬롯 재소비 여부를 실제 제품 장면에서 대조했다. 같은 DTO를 다시 발행하거나 권위 있는 지급을 수행하지 않았으므로 운영 ACK/재시도나 A06 통합 수용으로 승격하지 않는다.
