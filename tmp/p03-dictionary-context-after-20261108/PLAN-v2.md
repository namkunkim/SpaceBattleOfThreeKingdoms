# After 회귀·대조 보완

각 실행은 독립 입력 manifest, 기존 canonical class-map SHA와 class/source 원문, console/body/Python/runner SHA 및 Windows Job 30초 상한을 갖는다. 실제 exit0과 정확 마커/분모·종료 진단을 각각 확인한다. K6는 runner 종류마다 별도로 실제 호출을 센다.

| 회귀 | 실행 원본 | 기대 |
|---|---|---|
| P2c fresh | tmp/i01b-active-replace-20261102/regression-i01b_private_state.gd | I01B_P2C_PRIVATE_STATE_PASS, 70/11553/45 |
| active replace | tests/i01b_active_replace.gd | 정본 attempt2와 같은 PASS 마커, 20/20099/8명명·9호출 |
| P02 viewer 접점의 최소 회귀 | tmp/p03-viewer-checkpoint-20261108/viewer_checkpoint.gd | P03_VIEWER_CUT_RESULT, 4/47 |
| 같은 틱 suffix | tmp/p03-command-suffix-20261107/command_suffix.gd | P03_SUFFIX_RESULT, 6/91 |

출력 파일이 있는 회귀는 전용 경로를 향하도록 OUT 선언만 치환한 복사본을 사용하며 역치환 바이트가 원본과 일치해야 한다. 기존 성공 로그를 덮어쓰지 않는다. 실제 runner 출력은 각 시도 아래로 별도 보존한다.

Before의 13개 입력은 case ID·방향·identity 및 prepare 전제를 동일하게 유지하고 immutable before 결과와 행별로 대조한다. 6개 기존 수용이 정확한 원자 거부로 바뀌고 다른 7개 결과는 동일해야 한다. 추가로 동일 데이터의 value typed/untyped 양방향은 명시적으로 int 대 Variant Dictionary를 사용하며 key metadata를 유지한다. 이 두 항목은 이미 격리된 builtin 2개에 포함된다. 완전 untyped Dictionary와 typed-key/value Dictionary 간 양방향도 기존 분모 밖 보완으로 검사한다. P02 관련 공유 실행 입력이 실제 실행 동안 안정하지 않으면 그 실행의 회귀 수용을 보류한다.
