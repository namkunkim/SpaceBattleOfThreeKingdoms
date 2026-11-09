# P03 단일 증원 시각 변이 검증 결과

attempt-02 실제 suite exit 0. 본시험 실제 Godot exit 0, 명명 3개·45 확인 전부 통과. 강제 실패 대조 실제 Godot exit 1, 정확한 실패 marker 하나와 성공 marker 0개, 의도 단언 1개를 확인했다. 두 Windows Job은 각각 총 2 프로세스, 종료 후 active 0이었다. 스크립트 오류, 엔진 오류, 경고, ObjectDB/리소스 종료 진단은 각 0이었다. [suite](attempt-02/suite.json) · [본시험](attempt-02/fixture/run.json) · [실패 대조](attempt-02/forced_failure/run.json)

- `setup_and_exact_input`은 seed 41, hz 10의 POC 두 전대, 초기 spawn 두 건, queued stop 하나를 고정했다. 원본 P와 후보 M은 int `view.state.reinf_ms` -1→0 한 경로만 달랐고, 구조 검사는 통과했다.
- `positive_replacement`는 원본 P의 same-context restore가 성공하고, sim·state·두 fleet 객체가 교체되며 by_id가 새 fleet을 가리키고, capture가 P와 정확히 일치하는 것을 확인했다.
- `reject_is_atomic_and_can_advance`는 M이 공개 restore에서 정확히 `unsupported_reinforcement`로 거부되고, 활성 객체·따뜻한 캐시 identity/매핑·ready/busy·packet·입력 M·pending·raw events가 보존되는 것을 확인했다. 다음 틱은 수기 기대값 tick 1, clock 100ms, sub 50ms, 종료·증원 false, 시각 -1 및 spawn→spawn→say 순서와 일치했다. A/B의 전체 capture가 무처리 대조 C와 일치했다.

attempt-01은 suite exit 1이었다. Godot이 본시험의 기대값에서 5개 불일치를 보고했다. 정적 배열을 untyped로 작성한 fixture 오류였다. attempt-02는 기대 이벤트, 대기, 적용 log 배열을 Array[Dictionary]로 선언했다. 원래 case, 생산 원문, 변이, 오라클 값과 비교 강도는 그대로였다. [첫 시도](attempt-01/suite.json) · [첫 runner](attempt-01/runner.gd.txt) · [두 번째 runner](attempt-02/runner.gd.txt)

동결 manifest SHA256 b3f03eddfdec45f09c0cb253a4f9e2398cb2331da8877450c5ad797d258c70ae. 실행 전후 47개 입력 SHA와 HEAD가 일치했다. 동일한 옵션의 Git 전후 상태 비교에서 달라진 8개 상태 행은 전부 전용 폴더 아래다. 상태 출력 비교는 전체 dirty 파일의 바이트 감사와 별개다. P02와 다른 세션에서 이미 존재한 변경은 이번 결과의 소유 범위에서 분리했다. [manifest](attempt-02/manifest.json) · [전후 상태 비교](attempt-02/git-comparison.json)

이 결과는 S1 원장의 읽기 검증과 별도다. raw 증원 생성, 다른 변이, 실제 제품·P02, 활성 서비스, 전체 clock/RNG 및 운영 Cn은 미검증이다. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 독립 사후 5b를 요청했다.
