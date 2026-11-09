# BGM 포함 호스트 종료 진단 독립 계획 심사 — GPT-6 Sol

판정: **조건부 수용**. `PLAN.md` SHA-256 `be02fa756d60a0b0bfe4aa296535706c24224f1254ee816fc038b0acdafdb00` 기준이다. 기존 호스트 시계 K6은 6/6으로 닫혔고 이 계획의 K6은 새로운 진단 목적의 총 엔진 호출 상한이다. 기존 04/05의 verbose Ogg 객체 4개·resource 2개 누수, 06의 음악 자산 제외 시 진단 0은 음악 경로와의 상관을 뒷받침한다. host 코드 또는 Godot/driver의 책임은 아직 구분되지 않는다.

최소 load-only와 play 사례를 각각 별도 격리 Godot 프로세스로 실행하는 비교는 적절하다. 각 호출 전에 고정할 조건은 동일 원본 Ogg·`.import`·캐시 SHA, 동일 engine 본체/console·project 입력, 동일 AudioStreamPlayer 생성·tree 부착·해제 순서와 bounded frame 수다. 두 사례의 유일한 조작이 `play()`인지 manifest와 fixture 차이로 드러나야 한다. `ResourceLoader.exists`, stream 종류, 플레이어의 실제 재생 시작 또는 playback 객체 존재를 raw 출력에 기록하고 시작 미확인은 그 실행의 판정 실패로 처리한다. load-only는 `play()` 부재를 확인한다. 두 호출 모두 실제 exit, timeout, Job active, stdout/stderr 및 verbose ObjectDB/resource 진단을 분리 보존한다. 종료 누수를 재현한 호출은 **원인 진단의 관측**이지 제품 PASS가 아니다.

최소 재생 누수가 나타나면 종료 순서를 바꾸는 추가 1회는 사전 범위에 있다. tree 부착 상태에서 stop, bounded frame 대기, stream clear, queue_free 완료를 순서별 raw 이벤트로 기록하고 예상 진단을 미리 고정한다. 깨끗한 최소 재생과 달리 호스트에서만 재현되는 경우, 단일 호스트/장면 교체 중 무엇을 실행할지와 성공·실패 oracle을 다음 실제 호출 전에 독립 재심에 제출해야 한다. 최소 플레이어도 누수면 해당 실행 환경에서 **호스트 없이 재현**이라고 결론 내릴 수 있다. 엔진 자체나 driver 원인 확정은 다른 환경 대조 없이 보류한다.

각 시도의 원본·격리 사본 파일 목록 및 전후 SHA/크기, HEAD/index/status, console·본체 PID/path, 고유 APPDATA·캐시, bounded Job 회수와 잔여 PID를 보존한다. 소스 입력 drift 또는 예상 외 진단은 실패로 두고 기준을 완화하지 않는다. `hud/ui_kit/ui_sound.gd` 또는 `scripts/FleetBattle3D.gd` 공유 변경은 진단 결과와 정확한 hunk·회귀 계획, P02 쓰기 소유권을 조율자가 확인한 후 별도 심사해야 한다. 진단 중 전용 `tmp/p03-inchat-host-bgm/` 밖 편집은 승인하지 않는다. 수정 후 회귀도 이 K6의 호출 수에 포함한다.

이 심사는 계획과 `ui_sound.gd`의 실제 load/play/finished 연결 및 이전 04/05/06 원본 진단의 읽기 전용 확인이다. 구현·실행·제품 수정은 승인하거나 수행하지 않았다. 검토 모델은 사용자 요청에 따른 GPT-6 Sol 배정이며 파일 묶음에 별도 모델 실행 메타데이터는 없다.
