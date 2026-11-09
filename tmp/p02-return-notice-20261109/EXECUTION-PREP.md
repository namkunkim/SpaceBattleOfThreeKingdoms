# 천하 복귀 안내 실행 검토 묶음

독립 승인 전 엔진·Windows 창 실행 및 원본 적용 0회. 단일 격리 프로젝트의 before와 after가 같은 경로 및 캐시를 순차 사용한다. 전환 시 승인 4개 파일만 교체하고 import를 다시 실행한다. 두 WorldLink fixture overlay는 요청 객체 및 로더의 실제 Error만 기록한다. 원본 closure 1,480개, 보호 표본 26개 및 브랜치·HEAD·index를 재대조한다.

- headless 각 단계는 동일 버튼의 2회 거절 후 복구 성공, 정상 첫 클릭, standalone 3개 흐름과 returning 설정을 확인한다. 결산은 기존 fixture처럼 의도적으로 유도하며 버튼 신호를 프로그램으로 발행한다.
- native는 1600×900 창에서 같은 세 실패 화면의 초기·첫째·둘째 거절 PNG를 attempt-01/<side>/native-<phase>/{initial,reject-1,reject-2}.png에 저장한다. Windows Godot의 실제 viewport 렌더이며 OS 화면 캡처나 물리 입력 증거는 없다. 독립 검토자가 18개 PNG에서 한글 glyph·대비·버튼 위치·잘림·겹침을 확인한다. 해상도가 성립하지 않거나 창 실행이 불가하면 native는 결손이다.
- 준비 실패 카드는 경고를 위한 42px 공간과 VBox 간격을 항상 예약한다. 원본보다 카드 높이는 커질 수 있다. 재시도 버튼은 첫 거절 후 같은 위치다. Pause 예상 메뉴 끝 y432 뒤의 y436–468, Result의 버튼 행 종료 y−56 뒤에 y−48–−8을 둔다.
- 실제 리소스 rename/restore는 격리 WorldMap 한 파일만 바꾼다. 기존 로더 오류 두 줄 및 Error 19 경고 한 줄이 거절마다 발생한다. prepare에는 기존 profile 오류 한 줄이 추가된다. raw 로그와 assertion ID 순서·건수를 대조한다. 대상 프로세스는 SHA 고정 Windows exe를 전용 Job에 suspended 생성하고 등록한다. 로그는 root·exit·cleanup, supervisor stdout/stderr, Godot log로 나뉜다. 지정된 timeout과 supervisor 여유 45초를 적용한다. 외부 중단 표식은 attempt-01/abort다. 비정상 종료 시 hold의 SHA가 일치할 경우 격리 WorldMap만 복구한다.
- 준비 관측 약 3.996 GB 자유 공간. closure 약 670 MB, 과거 동급 import 캐시 약 335 MB, PNG·로그·userdata 여유 100 MB, 2차 import 임시 여유 200 MB로 추가 사용 추정 약 1.305 GB다. 시작 최소 2.8 GB 및 명령 사이 최소 1.5 GB 자유 공간을 확인한다. 엔진 실행 중 하드 쿼터는 없다.
- 신규 캐시 reclaim은 독립 수용 및 raw logs·PNG·results·Job cleanup 검토 후 별도로 진행한다. attempt-01/project/.godot의 이름·SHA·크기와 자유 공간을 저장하고 resolved path가 해당 격리 경로와 일치하며 reparse point가 없는 것을 확인한 뒤 신규 캐시만 대상으로 삼는다. 원본·과거 격리물·증거를 삭제하지 않는다.
- 원본 적용 및 5-b는 별도 승인 단계다. P03 공용 FleetBattle3D hunk, 원본 SHA, 쓰기 창을 다시 확인한다. PC0, K6, operation, 자연 플레이 완료 판정은 범위 밖이다.
