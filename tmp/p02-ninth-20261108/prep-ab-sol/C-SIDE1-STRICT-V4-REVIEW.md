# C side 1 조건부 판정기 v4

v3와 독립 심사 파일은 보존했다. v4는 증인이 제공될 때 적용할 검토용 오프라인 판정기다. 실제 증인 생성기와 Godot 측정은 미완료다.

- Fixture 입력 정체성은 심사된 source SHA를 외부에서 전달하고 witness의 SHA와 대조한다. 예상 설정은 estimated threshold 15, 거리 단위 25, 10 tick 평가 주기, SHP-02 sensor 1, intellect bonus 12, ship divisor 1이다. 정수는 exact Python int만 허용한다. 좌표와 offset 및 view radius는 int/float의 유한 값만 허용하며 bool, NaN, Inf, 형상 오류와 비정상 범위를 거부한다. 필수 필드의 누락이나 추가도 거부한다.
- 평가 직전 상대 두 fleet의 생존/ID/side, 좌표와 formation offsets, foe 조합·장비·지력·진형과 bonus, EW·은폐 비음수, chain 및 skill reveal 부재를 요구한다. Fleet root 상태나 post-step 샘플은 실제 `Detection._eval`의 동일 시점 증인이 아니다. Source row가 거리 ≥51 및 중심거리 >2×최대 offset +1을 만족하면 score ≤14이고 view radius 0에서 in_view가 false다. 조건을 벗어나거나 실제 producer의 시점·원문이 입증되지 않으면 판정하지 않는다.
- 초기 tick 0의 빈 side 1 contact를 각 fixture 인스턴스에서 요구한다. 이후 10 seeds × (32 estimated + 192 lost evaluations) × 두 lane × 두 인스턴스 = 8,960개 평가 증인, 80개 초기 receipt와 restore phase별 160개 contact capture의 정체성·순서/누락을 검증한다. Restore phase는 estimated/lost 및 각각 repaired다. 입력 SHA 또는 certificate가 동일하다는 사실만으로 raw producer의 신뢰성이나 restore 사이의 상태 변경 부재를 보증하지 않는다. 기존 restore receipt·raw bytes 및 object detach 판정은 계속 필요하다.
- 합성 fixture 1세트를 통과시켰고 반례 31건을 거부했다. ID/seed/tick/side/ship/intellect 타입 위장, 비유한 좌표/offset, 빈/초과 offsets, 초기 contact·누락, EW·은폐, 설정·SHA·lane·instance, 증인/인증서 누락 및 실제 contact 변조를 포함한다. 숫자는 합성 입력의 수이며 실제 fixture에 대한 계측·판정 결과가 아니다.
- B의 독립 label/order는 같은 label의 handler나 action route를 증명하지 못하며 109는 미측정이다. Q의 raw engine Variant, build precision 및 float32 경계는 실측하지 않았다. Watchdog filesystem/Job 및 GUI provenance가 미해결이다. 제품·Godot·GUI·Job을 실행하지 않았으며 K6 한 회가 남아 있다.
