# BGM 단일 호스트의 재생 관측 시점 보완

attempt-03은 실제 Godot exit 1, 진단 시험 FAIL이다. 정본 단일 호스트의 BGM Ogg를 로드했고 playback 객체가 있었으나 `playing`을 `PROCESS_MODE_DISABLED` 뒤에 읽으므로 false였다. 종료 로그에 누수는 없지만 유효 재현 분모가 아니며 제품이나 단일 호스트 일반의 깨끗한 종료로 판정하지 않는다. 이 실행과 최소 01/02를 합해 신규 K6 중 3회를 사용했다.

다음 04는 동일 단일 호스트 legacy teardown의 **관측 위치만** 보완한다. SceneTree에 부착하고 정본 _ready가 반환한 직후, 자동 프레임을 제어하기 위해 호스트를 disable하기 직전에 canonical BGM 경로·Ogg type과 실제 `playing`·`has_stream_playback`을 함께 읽고 출력한다. 여기서 둘 다 참이어야 한다. 그 뒤 기존대로 process를 disable하고 별도 필드로 이후의 상태를 출력한다. 플레이어의 재생을 다시 시작하거나 host 코드·mode 정책·teardown 순서를 변경하지 않는다. 기존 예상 논리 tick/acc 및 fingerprint, 실제 종료/Job active/예상 오류·누수/전후 SHA 기준을 유지한다. 정본 소스·BGM을 수정하지 않고 이전 runner와 결과를 보존한다.

04에서 정확한 Ogg 누수가 재현되면 05로 승인된 ordered 대조를 진행한다. 진단이 깨끗하면 ordered는 실행하지 않고 이전 다중 호스트 fixture와의 차이를 분리할 계획을 별도 사전 심사에 올린다. 04에서도 재생 시작을 입증하지 못하면 실행 근거 실패로 보고하며 이를 누수 부재로 해석하지 않는다.
