# P03 BGM 포함 호스트 종료 누수 진단 계획

이 조각은 이전 호스트 시계 K6 완료 기록과 독립이다. 기존 `p03-inchat-host-clock`의 attempt-04/05는 OggPacketSequence, AudioStreamOggVorbis, 두 playback 객체가 종료 시 남고 `stars_stripes.ogg`와 그 packet resource가 사용 중임을 보여 준다. attempt-05의 fixture stop·stream=null·250ms 대기로 해소되지 않았고 음악 자산을 격리본에서 빼자 06의 진단이 사라졌다. 이 근거는 Ogg BGM 경로와의 상관을 입증하며 호스트 또는 엔진 중 책임을 아직 특정하지 않는다.

`hud/ui_kit/ui_sound.gd`는 _ready에서 음악 player를 만들고 finished에 _next_music을 연결한다. _next_music은 실제 Ogg를 load하고 play하며 combat 분기도 Ogg의 stream을 교체한다. 스크립트에 종료 훅이 없지만 기존 fixture 수동 해제 역시 실패했으므로 종료 훅만 추가하는 해법은 재현 대조 전 확정하지 않는다.

## 독립 사전 심사 후 허용되는 진단

정본으로부터 바이트를 동결한 독립 격리 프로젝트와 고유 APPDATA를 사용한다. 원본 BGM, import 설명과 대응 cache는 모두 포함하고 ResourceLoader.exists·실제 stream 종류·playback 시작을 런타임에서 기록한다. engine console/본체 및 runner, 원본 BGM/설명자/캐시와 복제 전체 입력의 SHA·HEAD·index·status를 전후 기록한다. 전용 Windows Job과 bounded wait, 본체 PID/path, stdout/stderr/actual exit, leftover PID 회수를 기존 방식대로 검증한다.

1. **최소 Ogg 재생.** 제품 UI나 sim 없이 SceneTree에 plain AudioStreamPlayer 하나를 추가한다. 같은 실제 BGM을 재생하는 분기와 같은 stream을 로드만 하는 대조를 별도 Godot 프로세스에서 실행한다. 각 분기에서 별도의 이벤트·재생 여부·정상 종료 경계를 기록하고 verbose ObjectDB와 resource 진단을 비교한다.
2. **종료 순서 진단.** 최소 재생에서 같은 누수가 나면 `stop()` 뒤 player를 tree에 붙인 상태로 bounded process frames를 기다리고, stream을 clear한 후 queue_free 완료 프레임을 기다린다. 기존 fixture는 stop 직후 장면을 분리·free하고 그 뒤 기다렸으므로 순서가 다르다. 한 번의 추가 실제 프로세스로 이 순서의 효과를 확인한다. 비정상 종료는 actual exit와 별개로 실패다.
3. **호스트 경계 진단.** 최소 재생에서 누수가 없으면 기존 네 호스트의 BGM 포함 원문을 참조해 단일 호스트 준비·종료 또는 BGM 재시작·재생 중 장면 교체 중 가장 작은 차이를 선택한다. 실행 전 분기·오라클을 독립 심사에 다시 제출한다. 최소 재현에서 누수가 남으면 제품 source를 고치기 전에 동일 runtime/driver 특이성으로 분류하고 별도 환경 대조 또는 호스트 수준 수정의 필요성부터 정리한다.

기존 K6=6은 닫는다. 신규 진단 K6는 엔진 실행마다 1회를 소비한다. 첫 두 호출과 필요시 종료 순서 대조 1회 외의 진단은 사전 범위 재심을 받는다. 수정·회귀의 호출 분모도 이 K6에 포함하며 잔여 호출이 부족하면 미완료로 보고한다. 사용량 한도는 즉시 보고하고 반복하지 않는다.

## 수정 후보와 P02 소유 경계

- 최소 플레이어가 깨끗하고 host에서만 재현되며 정상 종료 순서를 적용해 해결된다면, 후보는 `hud/ui_kit/ui_sound.gd`의 _music 수명 관리 한 hunk다. 재생 재시작 방지, 기존 finished 연결 정리, player의 stop·stream 해제 시점을 근거와 함께 제안한다. host 전환 호출이 필수면 `scripts/FleetBattle3D.gd`의 정확한 전환/종료 진입점 하나를 별도 승인한다. 정상 메뉴·전투 음악 동작을 보존한다.
- plain player에서 동일 진단이 재현되면 이 결과만으로 host hunk를 승인하지 않는다. fixture가 프로세스 종료 직전 mixer를 비정상적으로 정리하는 문제라면 전용 harness만 수정한다. 엔진·driver 문제라면 현재 실행 환경을 정확히 적고 Ogg를 제거하거나 누수 진단을 무시해 제품 PASS를 만들지 않는다. 엔진 교체·자산 포맷 변환은 별도 범위다.

P02와 공유되는 수정은 조율자가 쓰기 소유권과 실행 창을 확인한 뒤, 확인된 원인과 정확한 hunk 및 회귀를 별도 독립 수용받아야 한다. 진단 단계는 `tmp/p03-inchat-host-bgm/` 외 편집 금지다. 승인된 경우에만 BGM 포함 격리 호스트의 동일 초기 fingerprint·실제 0/1 tick·후보 거부 보존 4명명과 실제 음악 시작/정지 및 진단 0을 함께 검증한다. 예상 profile 오류 두 건과 기타 오류, ObjectDB/resource 누수, Job active를 분리한다. 실제 제품 오디오의 사용자 청취나 운영 복원은 별도 인수다. Sol 구현과 구현 비참여 GPT-6 Sol 독립 계획·5b·closeout을 분리하며 Astra는 쓰지 않는다.
