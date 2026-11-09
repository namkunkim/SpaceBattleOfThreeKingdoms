# 직접 전환 거절 V6 · 정상 전환 중복 호출의 검증 자극 정정

검토용. attempt-01 및 attempt-02의 원문과 승인 입력은 유지한다. 이 조각 2/6 소진, PC0 2/2, 여덟째 K6 미사용. attempt-03 또는 Godot을 실행하지 않았다.

- attempt-02 before reject의 실제 4개 loader 오류 쌍과 45행은 원본 실패 기준 근거로 보존한다. before direct의 실제 exit 0과 C1–C4가 있어도 예상 밖 엔진 오류가 발생해 lane은 실패다. 원문의 tests/world_link.gd:255 → WorldMap 공용 버튼 sound callback → UiSound.play는 성공 뒤 분리된 버튼에 테스트가 인위적으로 보낸 두 번째 pressed signal에서 관측됐다. 제품 입력 재현이나 허용 진단으로 분류하지 않는다. [결과](ATTEMPT-02-RESULT.md) · [독립 판정](REVIEW-ATTEMPT-02-INDEPENDENT.md).
- v6-review.diff의 테스트 변경은 그 한 줄이다. 최초 실제 버튼 pressed signal, C1의 outgoing WorldMap 즉시 분리 및 current_scene null, C2의 FleetBattle3D scene_changed 정확히 1회, C3 전달 identity/seed/settings, C4 기존 결산 한 번은 그대로다. C1 직후 아직 유효한 같은 WorldMap 객체에 실제 _finish_sortie handler를 직접 호출해 같은 frame에서 재진입한다. handler의 state != "sortie" 조기 반환을 대상으로 하며 분리된 버튼에 새 UI 입력을 보냈다는 증거로 사용하지 않는다. 거절 A/B에서는 실제 WorldMap이 tree에 남으므로 기존 실제 버튼 signal 검사 그대로다.
- run-direct-v6.py의 변경은 고정 overlay 파일 경로와 manifest 파일 목록의 경로뿐이다. 제품 후보 두 파일, 원본/after fixture와 remap 차단, F1/F2/F3, 45행, 실제 엔진 로그 두 종류 각 4개, 명명된 baseline 실패, auto/title/restart, 전용 Job, timeout과 기존 오류 거부는 그대로다. 오디오 오류를 허용·숨기지 않는다.
- DIRECT-MANIFEST-V6-REVIEW-ONLY.json SHA-256 8b2b917aa9cf32c7d4aa699c79af5dddad890282c0c74241fa876ba3f5835db6에 attempt-03 14개 명령과 11개 입력 SHA를 고정했다. 검토본 상태값은 runner가 거절한다. 독립 승인본이 나온 경우 그 exact SHA와 source 1,480개/보호 4개 및 P03/HEAD/index/엔진·캐시 경계를 재검증하고 한 회만 실행할 수 있다. 제품 원본 반영은 actual 원문 및 독립 5-b 수용 후 별도 판단한다.
