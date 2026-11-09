# P03 격리 호스트 시계·게시 최종 시도 범위

독립 사전 심사 요청. K6 중 실제 엔진 호출은 5회다. 시작 증거의 2회는 서로 다른 최초 지문과 스크립트 오류·누수로 미수용이다. 개정 runner 03~05의 exit는 0이고 동등 초기 상태·실제 첫 프레임·실패 보존·후속 대조 단언은 각각 4개 모두 참이었지만 최종 게이트는 실패했다.

03에서는 기존 draw nil 오류가 사라졌으나 ObjectDB 4개·resource 2개와 즉시 관측한 Job active 1을 확인했다. 04는 실제 verbose로 네 누수 객체와 두 resource를 모두 선택적 BGM `res://assets/audio/music/stars_stripes.ogg`의 Ogg stream·packet·playback으로 좁혔다. Job의 5초 이내 회수 결과는 active 0, total 3이었다. 05는 fixture 종료 시 AudioStreamPlayer의 finished 연결 해제와 stop/stream 초기화, 250ms 대기를 넣어도 같은 누수 분모를 확인했다. 원 로그와 실행 입출력은 보존한다.

06은 사용자 게임의 음향 경로 대신 **선택적 BGM을 설치하지 않은 격리 호스트**를 명시적으로 사용한다. 격리 사본 준비 단계에서 `assets/audio/music/stars_stripes.ogg`와 옆 `.ogg.import`를 복사하지 않는다. 원본은 동결 분모에 포함하고 수정하지 않는다. 기존 캐시의 해당 음악 import 결과도 격리 프로젝트에 복사하지 않는다. 정본 소스와 나머지 격리 의존성은 그대로 바이트 대조한다. `UiSound._next_music()`의 자산 부재 조건을 이용하며 호스트·표시·tick 경로의 스크립트 패치는 없다. 나머지 실제 첫 프레임 및 실패 원자성 4개 이름/오라클은 유지한다. 실제 종료 코드, 두 개의 예상 profile 오류, 기타 진단/누수 0, Job active 0 및 SHA 안정성의 조건은 유지한다.

캐시 제외 두 파일은 `.godot/imported/stars_stripes.ogg-b59abb1eef986334bd1d3b3ab6e47e07.md5` 및 `.godot/imported/stars_stripes.ogg-b59abb1eef986334bd1d3b3ab6e47e07.oggvorbisstr`다. 정확한 네 원본 경로의 크기·SHA와 사본 미존재를 `approved-source-copy-differences.json`에 기록한다. 엔진에서도 해당 BGM의 ResourceLoader.exists가 false임을 초기 게이트가 확인한다.

승인과 최종 결과에는 BGM 부재를 명시하고 음향 동작, 완전한 제품 자산 환경의 깨끗한 종료, 일반 운영 복원·첫 제품 프레임 정책을 검증한 것으로 집계하지 않는다. 06도 게이트 미통과면 K6 상한을 이유로 멈추고 독립 실패 마감을 받는다.
