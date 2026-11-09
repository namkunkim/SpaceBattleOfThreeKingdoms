# 단일 호스트 BGM 수명 진단 독립 계획 심사 — GPT-6 Sol

판정: **조건부 수용**. `PLAN-HOST-LIFETIME.md` SHA-256은 `a69541277bbd94452edb8cf2e4280dc9236d546ae22f442633104b59652efdfe`이다. 구현·실행에는 참여하지 않았다.

최소 진단의 attempt-01 load-only와 attempt-02 play는 각 `result.json`의 actual exit 0, Job active 0, 진단 0, 원본 22개·사본 입력 및 HEAD/index/status 안정으로 일치한다. play 원문은 Ogg load, `playing`·`has_stream_playback` true와 12 frame 뒤 position > 0을 보여 준다. 따라서 같은 Dummy driver에서 plain player의 짧은 재생·정리만으로 기존 누수를 재현하지 못했다. 이 사실은 엔진/driver 무결성의 일반 증명이 아니다. 신규 K6의 사용은 2/6이다.

다음 단일 host legacy 종료 진단 1회는 허용한다. `FleetBattle3D.tscn`과 production 스크립트·BGM/import/캐시의 원본 바이트, 실제 canonical 경로·WorldLink seed·playing/playback 시작, 수동 `_process(.05)`와 presentation 갱신, legacy 종료 이벤트 순서를 raw 출력과 시도별 manifest에 남겨야 한다. 종료 누수 재현 oracle은 verbose의 OggPacketSequence, AudioStreamOggVorbis 및 두 playback 객체 **네 종류·네 건**, 해당 BGM stream·packet resource **두 건**이다. 인스턴스 번호는 가변값이므로 클래스·리소스 경로·건수를 비교한다. actual exit 0, timeout false, Job active 0, 원본·사본 입력 전후 SHA 및 예상 외 SCRIPT ERROR 0은 재현 진단의 유효성 조건이다. 누수가 관측되면 제품 PASS가 아니라 **재현 성공**으로 분류한다.

정확히 재현된 때에만 ordered 종료 대조 1회를 허용한다. 첫 호출과 같은 정본·BGM·seed·호스트 수, 시작 재생 상태와 종료 전 프레임을 사용하고, stop과 stream clear 사이에서 tree 부착 상태의 12 `process_frame` 및 250ms 대기만 변경한다. 그 대기 동안 host process 중지와 tick·주 clock 불변, 이벤트 순서·attached·playing/playback·stream 상태를 기록한다. 동일 manifest와 raw gate 아래 누수 소실은 **이 격리 종료 순서의 회피 증거**로만 판정한다. legacy에서 정확 재현되지 않으면 ordered를 실행하지 않고 범위를 재심한다. 두 호출 모두 K6에 포함하며 4회 잔여에서 최대 2회를 사용한다.

격리 fixture 외 공유 `hud/ui_kit/ui_sound.gd`·`scripts/FleetBattle3D.gd`·P02 파일을 쓰지 않는다. 공유 수정 후보는 원인·정확한 hunk·회귀 및 P02 소유·실행 창을 별도 독립 심사한 뒤에만 진행한다. BGM이 포함된 제품 전체의 깨끗한 종료, 사용자 청취, 운영 복원·외부 ACK는 이 진단의 결론 범위 밖이다.
