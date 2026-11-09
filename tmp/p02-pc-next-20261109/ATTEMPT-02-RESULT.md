# 직접 전환 거절 V5 attempt-02 결과 · 검토용

판정: 2/6 소진. runner exit 1, 전체 인수 실패. 승인된 attempt-02 명령을 한 번 실행했다. 전후 승인 입력 11개, closure 1,480개, 보호 대상 4개 및 HEAD/index를 재검사해 모두 일치했다. PC0 2/2와 기존 여덟째 K6 미사용을 유지한다.

| before lane | 실제 Godot root exit | Job active | 관측 |
|---|---:|---:|---|
| import | 0 | 0 | 보유한 keytool 및 conhost HANDLE 모두 signal 0·exit 0. |
| reject | 1 | 0 | F1/F2/F3 통과. 실제 missing-scene loader 오류 두 종류 각 4회. 45개 행 모두 발생, 17 PASS·28 의도된 FAIL. runner의 baseline negative 검사를 통과했다. |
| direct | 0 | 0 | C1–C4와 왕복 완료 마커가 있으나 예상 밖 엔진 오디오 오류로 lane을 인정하지 않는다. |

거절 lane은 WorldLink 이전 brief·outcome·설정 훼손, 지도 leaving/잠금 및 기존 결과 복구 실패를 원본에서 관측했다. 이 실행은 원본의 void 반환을 R1 실패로 기록하므로 제품 후보가 ERR_CANT_OPEN을 공개 반환한다는 증거는 아직 없다. after는 import부터 시작하지 않았고 before auto/title/restart 역시 미실행이다.

정상 direct 원문에서 C1은 WorldMap이 SceneTree에서 즉시 분리되었음을 확인한 뒤 PASS를 기록했다. 바로 이어 준비 테스트의 두 번째 skip.pressed 신호가 분리된 WorldMap 버튼의 공통 효과음 lambda를 실행했다. 원문 stack은 tests/world_link.gd:255 → view/world/world_map_screen.gd:150 → hud/ui_kit/ui_sound.gd:165이며 메시지는 아래와 같다.

    ERROR: Playback can only happen when a node is inside the scene tree

제품 소리 경고를 허용하거나 runtime을 고치기 전에 검증 자극의 실제 가능성을 구별한다. 보이는 UI의 첫 pressed는 그대로 사용한다. C1에서 기존 씬 분리를 확인한 후 별도 신호로 음향 lambda를 호출하는 대신, 유일하게 중복 검사가 필요한 전환 handler를 같은 frame에서 재진입시키는 시험을 다음 독립 계획에서 검토할 수 있다. 이렇게 하면 두 번째 UI 입력으로 주장할 수 없으므로 handler 재진입 검사라고 명시한다. 거절 A/B에서는 scene이 계속 살아 있으므로 실제 기존 버튼 signal을 유지한다. 이 결과 정리에서 테스트·제품·런처를 수정하거나 재실행하지 않았다.

증거는 Godot --log-file과 C# Job/실제 root 원문이다. PowerShell supervisor 별도 스트림을 엔진 stdout/stderr로 집계하지 않는다. 모든 단명 자손을 확인했다고 주장하지 않는다.

- attempt-02/result-review-only.json에 실제 exit·active 0, 45행, C1–C4와 각 로그 SHA
- attempt-02/before/reject/engine.log와 engine.os.tsv
- attempt-02/before/direct/engine.log와 engine.os.tsv
- attempt-02/before/reject-metadata-review.json과 reject-closure.json
