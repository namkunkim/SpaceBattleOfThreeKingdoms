# P03 접촉 만료 사건 좌표 관측

2026-11-08 KST. **CURRENT_POS_OBSERVED.** 제한 fixture의 tick2410에서 side0 공개 projection은 lost 접촉의 마지막 위치 (625,500)만 제공했다. 다음 실제 step의 tick2411에서 접촉이 projection에서 사라졌고, raw와 side0 표시용 `contact` 사건 `{state:"none",was:"lost"}`의 위치는 숨은 현재 위치 (2800,1800)였다. side1에는 그 contact 사건이 없었다. tick2410 packet을 복원하고 같은 advance를 한 번 실행했을 때 raw/side0 payload가 각각 재현됐다. [독립 5-b](REVIEW-5B-attempt-04.md)

최초 confirmed 이후 적의 위치와 home을 통제해 기함이 이전 위치로 귀환하지 않도록 했다. 탐지 책·시계·이벤트는 직접 바꾸지 않았다. 실제 사용자 이동이나 제품 UI에서 사건을 표시하는 흐름은 검증하지 않았다. 현재 좌표를 이 사건에서 공개해도 되는지는 제품 정책·공통 소비자 계약에서 별도 판정한다.

정본 attempt-04/K6 actual Godot exit0, 3명명/2461 단언이다. 반복 drain 상태 확인이 단언 수에 포함된다. 01/03은 위치 precondition 실패, 02는 진단 코드 파싱 실패였고 모두 보존했다. 정본 console·본체, class map, 48개 입력 SHA 전후 동일, 오류/경고/누수0. 시작 16895 전수 재해시 누락0/변경0, 48 실행 입력 drift0이다. P02 화면 초기화 후보의 신규 증거 5개 및 status 비원자, 기존 diff-check exit2를 별도로 기록했다. [실행 원문](attempt-04/run.json) · [보존](preservation.json)

P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. Dictionary value metadata MISMATCH 및 공통 owner 소유권은 별도 열린 항목이다.
