# P09 화공 오디오와 TRACE 비교

Windows 헤드리스 Dummy 오디오에서 같은 적벽 시드 208로 `e3d76788`과 `a2733c8b`를 비교했다. 실제 `FleetBattle3D`와 `BattleTrace`를 사용한 두 실행이 모두 201틱에 도달했다. 기록된 11개 행에서 `wall_time`과 `mono_ms`를 제외한 결과가 일치했다. 수정 전에는 종료 직전까지 재생 중이었고 수정 후에는 201틱에 정지했다. 두 실행에서 모두 장면 해제 뒤 재생 참조가 해제됐다. 실제 장치의 오디오와 전체 게임 TRACE는 이 시험 범위 밖이다.

- `comparison.json`에 실행별 결과가 있다. 기존 장치 절대경로는 이 폴더의 정규화된 TRACE 파일 이름으로 치환했다.
- `before-trace.normalized.json`과 `after-trace.normalized.json`을 비교하면 기록 내용 일치를 확인할 수 있다.
- `p09_trace_parity_probe.gd.txt`는 두 실행에 공통으로 사용한 계측 코드다. 격리 체크아웃에서 `tests/p09_trace_parity_probe.gd`로 복사한 다음 별도의 `APPDATA`를 지정하고 `godot --headless --audio-driver Dummy --path <checkout> --script tests/p09_trace_parity_probe.gd`를 실행한다.
- 현행 회귀 테스트는 `tests/p09_autonomous_fire_audio.gd`에서 확인할 수 있다.
