# 단일 호스트 재생 관측 보완 독립 심사 — GPT-6 Sol

판정: **조건부 수용**. `PLAN-HOST-PLAYBACK-GUARD.md` SHA-256 `667e7f33d90ea1322c7594ef36ab2982efb79663af5cc84f9c289bc730660020` 기준이다. attempt-03은 실제 exit 1, diagnostic gate FAIL, `playing: false`로 시작 조건을 충족하지 못했다. 누수 진단이 없더라도 유효한 단일 host 무누수 대조가 아니다. 신규 K6은 3/6 사용했다.

04에서 실제 `FleetBattle3D.tscn`을 tree에 붙이고 정본 `_ready`가 반환한 직후, `PROCESS_MODE_DISABLED`를 적용하기 전에 음악 player의 canonical Ogg 경로·`playing`·`has_stream_playback`을 읽고 기록하는 변경은 관측 시점 보완으로 수용한다. 그 이후 disable 상태는 별도 출력하고 같은 수동 `_process(.05)`·fingerprint·tick/clock·legacy teardown을 유지한다. 재생 재시작, 정본/공유 코드 또는 BGM 변경, 종료 진단·actual exit·Job active·입력 SHA 기준 완화는 허용하지 않는다. 03의 runner·결과는 보존한다.

04에서 정확한 Ogg 네 객체·두 resource 누수를 재현하고 나머지 gate가 유효할 때에만 05 ordered 대조를 허용한다. 그 전에 runner 번호와 대조 참조를 04 legacy/05 ordered로 고치고, 05의 source/project baseline이 **수정된 04 runner 및 사본**과 비교되도록 한다. 03의 실패 runner manifest를 05의 동일 입력 기준으로 사용할 수 없다. 04가 유효 CLEAN이면 ordered를 실행하지 않고 다중 host 차이의 별도 계획을 심사한다. 04도 재생 시작 미입증이면 실패로 보존한다. 제품 종료·엔진 원인 귀속은 이 계획으로 확정하지 않는다.
