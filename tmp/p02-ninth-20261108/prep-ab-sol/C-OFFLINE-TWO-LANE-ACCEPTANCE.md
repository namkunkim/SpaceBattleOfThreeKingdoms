# C detection 증거의 오프라인 두 lane 인수

이번 조각의 목표는 C producer v4의 원본 형식으로 만든 자료를 받아, 양쪽 lane의 실제 형태인 평가·복원 흐름을 하나의 오프라인 검증기로 검사하는 것이다. 사용자 제품 목표에서는 어댑터가 잘못된 fixture나 다른 실행의 정상 결과를 섞어 통과시키는 일을 줄인다. 이 작업은 실제 제품·Godot·Job·GUI 또는 새로운 진단 실행 예산을 포함하지 않는다.

## 구현과 인수

c_offline_rehearsal.py는 후보 로그와 별도로 전달받은 approval bytes SHA, fixture source manifest SHA와 실제 파일 bytes, lane별 launcher receipt SHA, raw log SHA 및 20개의 독립 typed case pin을 먼저 확인한다. Before와 after run ID가 같으면 실패다. 실제 launcher와 독립 승인 기록이 입력을 공급해야 한다. 해시 검증은 실행자가 보고한 PID/HANDLE의 진실성이나 중간 파일 불변을 자체 증명하지 않는다.

- 두 lane에서 각각 5,080개 producer 행을 원본 순서로 먼저 검증한다. 20 segments의 초기/위치 이동 전후 평가/alias/5회 복원/scope를 누락 없이 요구한다. Actor별로 v4가 읽는 witness 배열을 만드는 작업은 이 원본 순서 검증 뒤에만 수행하며 original files를 재정렬하거나 수정하지 않는다.
- 평가 직전 raw Variant의 authoritative tick, side, 두 fleet의 실제 타입·ID, formation offsets, ship stages, detect 및 formation 설정을 해석한다. Source 조건인 estimated=15, 거리 단위25, evaluation period1초, view/radar 0, SHP-02 sensor 1, intellect bonus12, stage-live 수와 empty terrain, EW 비음수를 확인해 v4 geometry witness에 넣는다. Geometry가 관측 자료에서 보수적 경계를 만족하지 못하거나, source parser가 필요한 유형을 지원하지 못하면 실패다. 증인이 기록되지 않았는데 빈 contact를 정상으로 채우지 않는다.
- 같은 검증된 원문에서 20×5 restore calls/lane의 request ID와 packet raw-byte SHA, pre/post source _all, target outside와 repeat no-op, 실제 반환 true 및 live receipt ordinal/time을 확인한다. Actual source roster에서 선택 ID를 얻어 외부에서 고정한 v9 pin과 첫/wrong/repaired phase에 결합한다. 이 입력의 독립 pin이 없으면 실행 결과에 맞춰 생성하지 않는다.

합성 스크립트와 로그에서 두 lane 10,160개 원본 행, 8,960개 evaluation witness, 200개 restore call을 한 번의 전체 자료 검증으로 통과시켰다. 외부 approval SHA 변조, case pin 교체, 같은 lane 안의 geometry 변경과 다른 요청 ID, 양쪽 run ID 재사용을 각각 거부했다. 합성 payload는 fixture 의미를 보존하는 입력을 따로 만든 것이며 실제 Godot에서 얻은 자료가 아니다.

## 범위 끝과 다음 의존성

이번 acceptance는 **두 lane 오프라인 join 및 합성 반례**까지다. v7의 실제 Windows process identity/HANDLE과 외부 launcher, actual GDScript producer의 평가 시점, raw payload의 모든 Variant 타입과 시간·파일 크기, alias mutation typed state와 detach·suffix의 전체 원문은 별도 검증이다. Alias 행은 순서를 요구하지만 그 payload 의미까지 검사하지 않는다. Q/B와 GUI per-request 및 OS Job 적합성은 미해결이다. 기존 Python K=3 실패를 보존하고 새 실행을 계획하지 않았다.

제품·Godot·GUI·Job 실행 0회, 제품 P02는 NOT_READY, 마지막 K6 한 회가 남아 있다. 제품/P03/worker와 Git staged 자료를 수정하지 않았다. HEAD 기반 계획은 활성 P03 +9와의 결합 검증이 아니다.
