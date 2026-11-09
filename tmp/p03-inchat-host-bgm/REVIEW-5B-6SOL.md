# BGM 포함 종료 진단 독립 5b — GPT-6 Sol

판정: **다섯 진단 실행의 관측 수용, 원인·제품 수정 마감 보류**. 구현과 실행에는 참여하지 않았고 각 시도의 원본 `result.json`, stdout/stderr, 입력 manifest, runner 및 이전 누수 시도와의 차이를 읽기 전용 대조했다. 신규 K6은 5/6 사용이며 조건이 성립하지 않은 06 ordered는 실행되지 않았다.

## 시도별 판정

| 시도 | 실제 exit / Job active | 독립 확인 |
|---|---|---|
| 01 load-only | 0 / 0 | 원본 Ogg load, 재생 없음, 진단 0. 유효 CLEAN. |
| 02 play | 0 / 0 | Dummy driver에서 실제 playing·playback true, 12 frame 뒤 위치 >0, 진단 0. 유효 CLEAN. |
| 03 단일 host | 1 / 0 | `PROCESS_MODE_DISABLED` 뒤 playing false를 관측한 오라클 오류. 진단이 없어도 FAIL로 보존. |
| 04 단일 host | 0 / 0 | disable 전 canonical Ogg·playing·playback true, 실제 tick 1/acc .25, 진단 0. 유효 CLEAN. |
| 05 다중 host | 0 / 0 | 네 장면 모두 BGM 시작 확인, 네 호스트 기능 check true, 예상 `profile.ally` 오류 정확히 두 건, 추가 SCRIPT ERROR·Ogg/ObjectDB/resource 진단 0. 유효 CLEAN. |

각 시도의 원본·사본 입력 및 HEAD/index/status 전후 안정 표시를 manifest와 비교했다. 05는 원본 입력 2789개와 사본 입력의 전후 동일, Godot 본체 PID/path 및 Dummy driver를 기록한다. stdout의 `MUSIC` 네 행은 각 phase·reject 분기에서 Ogg/playing/playback true이고, `RETIRE` 네 행은 stop 부착·clear·free 및 clock 불변을 기록한다. `HOST_CLOCK_RESULT`의 네 명명 단언이 true이며 stderr의 예상 두 오류 외 진단은 없다. `diagnostic_gate: PASS`는 이 범위에서의 **유효 CLEAN 관측**이고 과거 누수 수정이나 제품 오디오 인수의 PASS가 아니다.

이전 `p03-inchat-host-clock/attempt-05`와 현재 05의 격리 project manifest를 상대 경로로 독립 재대조했다. 공통 2750개 파일의 크기·SHA는 모두 같다. 이전에만 `.gdignore`와 `host_clock_probe.gd`, 현재에만 `multi_host_probe.gd`가 있다. 실제 runner 차이는 material하다. 이전은 각 player를 순서대로 stop→stream clear하고, 현재는 모든 player를 stop한 뒤 별도 루프에서 모두 clear한다. 현재 runner는 별도 BGM 관측·참조 수명·await 형태도 갖는다. 따라서 05의 CLEAN은 다중 host에서도 이전 누수가 항상 발생한다는 가설을 반박하는 단회 관측이지만 **누수 원인 또는 해결 조작을 특정하지 않는다**. 05가 정확 Ogg 누수를 재현하지 않았으므로 사전 계획의 06 ordered 실행 조건은 충족되지 않았다.

`EVIDENCE.zip`을 독립 검사했다. SHA-256 `1268c29142a3fe1e27eb1ccaf4aa689e405e8c40549e77130e1a365d697092b8`, 100개 ZIP 항목 중 manifest 외 payload 99개다. 중복·누락·추가·원문 바이트 및 `EVIDENCE-SHA256.json` 해시 불일치는 모두 0이다. 전체 격리 project 원본을 ZIP에 담은 것은 아니므로 manifest와 시도 디렉터리의 역할을 구분한다.

공유 `hud/ui_kit/ui_sound.gd`, `scripts/FleetBattle3D.gd`, P02 파일은 이 진단에서 수정되지 않았다. BGM 포함 완전 제품 종료, 자연 장면 전환, 엔진/driver 원인 귀속, 사용자 청취, 운영 복원·외부 ACK는 미수용이다. 남은 stop→clear 순서 가설은 새로운 사전등록과 독립 심사 없이는 마지막 K6 호출에 적용할 수 없다.
