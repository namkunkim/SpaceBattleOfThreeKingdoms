# 천하 복귀 실패 알림 계획 독립 심사

판정: 네 파일의 격리 후보·테스트 및 실행 명세 준비는 수용한다. 현재 문서만으로 제품 적용이나 Godot/Windows 실행은 수용하지 않는다. 후보, 정확한 테스트/렌더 fixture와 실행 argv·종료/timeout·오류 분모·소유 프로세스 및 source closure, 화면 캡처 경로와 디스크 예산이 아직 동결되지 않았다. 사용자 확인은 필요하지 않다.

실제 pause/result는 서로 다른 화면이 공통 to_title을 호출하고 초기 준비 실패는 FleetBattle3D에서 별도의 직접 WorldLink 호출을 한다. 따라서 WorldLink의 오류값 반환만으로는 세 화면에 안내가 표시되지 않는다. 기존 void 호출자는 반환을 버릴 수 있으나 Signal Callable과 선택 인자의 실제 호환성, 다른 호출자, standalone 성공/실패 흐름을 확인해야 한다. sim==null 처리와 initial 준비 버튼 변경은 기존 active-reprepare 실패 카드를 건드리지 않아야 하며 null brief·link 부재에도 예외나 위장 성공이 없어야 한다. 오류시 이전 brief/outcome identity와 sim·pause/result·버튼, 최초 안내를 유지하고 기존 warning은 정확히 한 번만 남겨야 한다.

동일 화면의 반복 시도는 새 DTO마다 결과 사실은 같되 객체는 다를 수 있다. 정상 전환은 기존 씬이 즉시 tree에서 제거되므로 성공 분기에서 라벨 또는 outgoing scene 접근을 피한다. scene_changed 수신 후 결과 1회 소비를 확인한다. 실패 라벨 초기 숨김·두 번 거절시 하나만 표시·화면 재진입시 초기화·성공에 따른 제거를 각 화면에서 검증한다. 단순 visible 속성이나 프로그램 signal만으로 실제 글자 가독성·물리 입력을 주장하지 않는다.

현재 pause는 860×470 패널에 5개 메뉴가 배치되고 result는 화면 하단 버튼 행을 쓴다. 준비 실패는 SafeArea/VBox 안에 있다. 제안 위치가 버튼·기존 텍스트·safe area와 겹치거나 긴 문구·DPI/UI scale에서 잘릴 가능성은 실제 후보와 렌더로 확인해야 한다. 해상도·scale·캡처/좌표·시각 판정자를 사전 고정하고 native 검증이 불가하면 UI 관측 결손으로 남긴다. 기존 PC0 2/2를 우회하지 않는 별도 비제품 또는 새로운 조각의 정당한 범위를 유지한다.

FleetBattle3D는 P03과 공유 경계다. notLoaded/idle은 쓰기 허가나 잠금이 아니며 후보 적용 직전 최근 소유 현황과 실제 파일/hunk SHA를 확인해 충돌시 중단한다. 독립 5-b 전 원본 반영하지 않고, 기존 26개 baseline을 전체 workspace 원자 스냅샷으로 취급하지 않는다. 기존 거절/복귀 증거와 PC0/K6 한도를 바꾸지 않으며 첫 PC operation 또는 자연 플레이 완료를 주장하지 않는다.
