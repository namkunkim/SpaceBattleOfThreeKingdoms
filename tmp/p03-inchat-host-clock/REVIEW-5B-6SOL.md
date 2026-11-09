# 호스트 시계·게시 최종 5b 독립 검토 — GPT-6 Sol

판정: **선택적 BGM을 제외한 격리 호스트의 사전등록 시험 수용**. 구현·실행에 참여하지 않고 attempt-03~06의 원본 증거와 runner·정본 경로를 읽기 전용 대조했다. 원본 증거와 공유 P02 소스는 수정하지 않았다.

## 실패 보존과 최종 실행

기존 두 호출과 attempt-03~06으로 K6을 모두 사용했다. `attempt-03/result.json`은 실제 exit 0 및 네 자체 check true이나 ObjectDB 4·resource 2 종료 누수와 즉시 관측 Job active 1로 전체 실패다. `attempt-04`와 `attempt-05`는 Job active 0이지만 같은 Ogg 누수로 실패다. `attempt-04`의 verbose 원문은 선택적 `stars_stripes.ogg`의 OggPacketSequence, AudioStreamOggVorbis, 두 playback 객체와 resource 2개를 특정한다. `attempt-05`에서 격리 fixture의 재생 정리 뒤에도 누수가 남은 원본을 보존했다. 과거 실패를 PASS로 승격하지 않는다.

마지막 계획 개정 `PLAN-AMENDMENT-ATTEMPT-06.md` SHA-256은 `8107787dfb19b23acf32e8e005b8444300e698de4bfb12ee1ade93582c57bbe5`이며 실행 전 조건부 독립 심사를 기록했다. `attempt-06/approved-source-copy-differences.json`은 `stars_stripes.ogg`, 옆 `.ogg.import`, 정확한 두 import 캐시의 원본 크기·SHA와 격리 사본 부재 4건을 기록한다. 네 파일은 원본 동결 분모에 남고, 사본에서 모두 없다. 독립적으로 원본 manifest와 사본 manifest의 경로·해시를 대조한 결과 이 네 경로와 fixture용 `.gdignore` 외 차이가 없었다. 그 밖의 정본 소스와 캐시 사본은 동결 SHA와 같다. `UiSound._next_music()`의 `ResourceLoader.exists(path)` 분기와 runner의 `ResourceLoader.exists` false guard를 확인했다. 본 실행은 음악 자산이 없는 격리 제품 장면이다.

`attempt-06`의 source before/after 2766개와 project before/after 2748개가 각각 동일하고, HEAD/index도 동일하다. 이는 지정 보호 입력의 실행 전후 불변이지 전체 작업트리의 동시 변경 부재 증명이 아니다. `command.json`은 격리 project를 headless/verbose Godot console로 실행한다. `result.json`의 `actual_exit: 0`, timeout false, console PID 20916, Godot 본체 PID 37104 및 정본 본체 경로, Job active 0/total 3/terminated 0을 원본 실행 구조와 대조했다. raw stdout의 단일 `HOST_CLOCK_RESULT`는 네 이름 모두 true이고, stderr에는 예상 `invalid_candidate_profile at profile.ally` 두 건만 있다. SCRIPT ERROR·ObjectDB/resource 누수·그 밖의 진단은 없다. raw 결과와 `result.json`의 진단 목록·check 목록이 일치한다.

인계용 `HOST-CLOCK-EVIDENCE.zip`도 독립 검사했다. SHA-256 `7e9728ddb8e270702643b6bad9c2bad34d78d7adb8b9f5ff84dd9e644933a32f`, 77개 항목 중 manifest 외 payload 76개, 중복·누락·추가·CRC/원문·manifest 해시 불일치가 모두 0이다. ZIP에는 격리 프로젝트 전체 파일이 아닌 runner snapshot·실행 로그·입력 manifest 등이 들어 있으므로 전체 사본의 대체물로 해석하지 않는다.

runner는 routed brief seed 20261109를 각 분기에 공급하고 자동 process를 막는다. 전 프레임의 네 분기 baseline 전체 관측값과 fingerprint가 같고 초기 tick/clock_ms가 0이다. 실제 첫 `_process(0.05)`에서 phase 0은 tick 0·0ms·acc/alpha .5, phase .75는 tick 1·100ms·acc/alpha .25다. 실패 후보는 각 분기에 `invalid_candidate_profile`/`profile.ally`를 반환하며 기존 sim·clock·VM·renderer·HUD 및 관측값을 보존한다. 후보 없는 분기는 같은 다음 프레임 대조를 수행하고 정상 신규 게시가 clock을 초기화함을 별도 확인한다. 정리 check true와 원본 종료 진단 0을 함께 요구했다.

이 증거는 격리 호스트의 시계 phase 및 준비 실패 게시 경계에 한정한다. 선택적 BGM을 설치한 완전한 자산 환경의 깨끗한 종료, 음향 동작, 제품 운영 복원·첫 사용자 재개, 외부 ACK, 전체 P03 준비는 입증하지 않는다. 파일 묶음에는 실행 모델 자체를 증명하는 메타데이터가 없어 GPT-6 Sol은 사용자 요청에 따른 검토 배정으로만 기록한다.
