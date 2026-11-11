# 적벽 신규 진입 화면 — 구현·연결 계약 (2026-11-11)

## 완료 범위
신규 독립 진입 씬 및 자체 회귀. 사용자 후속 요청에 따라 최초 도식 프로토타입을 새 맵의 실제 성운·항로·암석 잔해 자산과 기존 한글 글꼴을 사용하는 제품 UI로 교체했다.
실제 전투맵/캠페인 통합 완료나 상용 출시 승인을 뜻하지 않는다. 상세 맵은 전술 준비 화면이며 전투 호스트와 시뮬레이션을 생성하지 않아 0틱이다.

## 실행 및 변경 범위
- 진입 씬: res://scenes/entry/NewEntry.tscn (Godot 4.7.2, 직접 실행).
- 독립 검증 프로젝트: F:/WorkSpace/new-entry-20261111/project.godot.
- E 변경: scripts/entry 3개, scenes/entry 2개, tools/entry 4개, docs/entry 3개.
- project.godot, WorldLink, FleetBattle3D, world_map_screen, deck_screens, first_operation_host, core/battle, 규칙/저장/리플레이/원장/논리치수/공통 체크리스트 및 기존 원본 자산은 수정하지 않았다.
- 사용자 저장·검증 EXE67f9cb20 보존. K6 정식·다중 호스트·강제 종료 미실행.

## 화면과 데이터
- 실행 → 시나리오 선택 → SF 서사 3장(수동 다음/건너뛰기) → 전략 맵 → 전투 문의 → 예: 전술 준비 / 아니오: 정상 프로그램 종료.
- 전략 맵: galaxy_navigation.json의 기존 항로·권역 위치를 그대로 읽는다. 해당 데이터에는 적벽 개별 지점이 없으므로 형초 권역을 '적벽 작전 / 형초 권역'으로 표시한다. 신규 정본 적벽 좌표를 만들지 않는다.
- 준비 맵: p05_p07_first_operation_dev_v1.json의 space.size/nodes/routes.front를 그대로 읽어 집결·정면 항로·목표를 표시한다. 실제 지형 오버레이 red-cliffs-terrain.png 및 red-cliffs-reference-sky.jpg를 참조한다.
- 전략 배경 galaxy_navigation_terrain.png, UI Pretendard-Regular.otf, 제목 NotoSerifKR-SemiBold.otf. 원본 덮어쓰기 없음.
- 고정 시점, 전략 맵 준비 후 2초 자동 문의는 임시 연출 기본값. 서사는 검토 문서의 SF 초안으로 새 세계관 수치를 추가하지 않는다.
- 조작 가능한 지역은 적벽뿐이다. 나머지 권역은 잠금 표기와 비상호작용 렌더링을 사용한다.

## 입력·오류
- 키보드 기본 UI 탐색/Enter, 패드 D-pad/A 직접 처리, 마우스 버튼, 화면 터치 직접 처리.
- 지역 진입 API는 red_cliffs만 허용. 상태 revision과 0.25초 보호시간으로 오래된 콜백·이중 선택·입력 관통·중복 로딩 완료를 거부한다.
- 문의 동안 배경 지도 입력 없음. Esc/패드 B/바깥 클릭은 종료하지 않는다. 아니오는 추가 확인 없이 SceneTree.quit(0).
- 상세 씬/지도 정보/이미지 로딩 실패 시 오류 안내와 재시도/종료. 문의의 지도 로딩 재시도도 기존 상태를 보존한다.
- 작은 창은 스크롤 컨테이너로 대응. 모든 문구는 음향 없이 이해 가능하다.

## 확정 캠페인 연결 계약
- scenario_id=RED-CLIFFS-208-RT.
- 기존 적벽 v1만 승인: pc/first-operation/1, red-cliffs-first-operation-dev-v1 v1, seed 208, 표준/direct/front.
- detail_prepared(context): origin, region_id=red_cliffs, scenario_id, battle_started=false. 준비 완료 신호는 출격 권한이 아니다.
- 실제 명시 출격 때만 기존 BattleBrief.select_first_operation_product()를 사용한다. 준비 중 first_operation_host._begin() 호출 금지.
- resume/settlement는 부트 라우터에서 기존 WorldMap으로 전달하여 서사/문의 생략. 독립 씬을 사용하는 경우 add_child 전에 entry_origin 및 continuation_requested 연결을 설정한다. 현재 독립 실행의 BYPASS는 자동 저장 복원이 아니라 통합 경계다.
- 저장 복원은 기존 _resume_saved_battle(true) → begin_restore → validate_restored_owner → WorldLink.go_battle 순서를 유지한다. 검증 전 전장 전환 금지. 실패/취소 시 기존 화면·선택 유지 및 재시도.
- 결산은 기존 host/WorldLink 책임. 신규 화면에서 저장·결산 재처리 없음.
- 자동 전투 시작 _ready를 가진 기존 전투 씬을 detail_scene에 넣으면 준비 계약을 위반한다. 준비 전용 Control만 허용.

## 미적용 통합 패치
- main-scene-candidate.patch: 기본 씬 교체 예시. resume/settlement 부트 분기 없이 단독 적용 금지.
- campaign-api-candidate.patch: 기존 world_map_screen의 승인 출격·복원 흐름을 재사용하는 공개 API 제안. 출격 API 반환 OK는 요청 수락이며 전장 전환 성공을 뜻하지 않는다.
- 두 패치는 git apply --check 통과했으며 적용하지 않았다. 부트 라우터·준비 화면 수명·복귀 UI의 최종 결선은 단일 통합 담당의 독립 검토 후 수행한다.

## 검증 결과 및 증거
- verify_entry.gd: 21 checks / 0 failures. 서사 완료/skip, 지역·시나리오 잠금, 오래된 토큰, 중복 선택/로딩, 모달 배경, Esc, 로딩 실패/재시도, 준비 지도 1회 생성, resume/settlement BYPASS, 오류 종료.
- verify_entry_input.gd: 합성 Input keyboard Enter → touch skip → mouse no, exit=0. EXPECT_NORMAL_EXIT 뒤 엔진 정상 종료.
- verify_entry_pad.gd: 합성 Joypad A PASS.
- capture_entry.gd: 실제 OpenGL 렌더러 실행·정상 종료. select/story/confirm/ready/ready-small PNG. 선택·문의·준비 화면 육안 검사; 전략 레이블 겹침 수정.
- 물리 키보드/패드/터치 장치, 내보낸 EXE, 모든 해상도 조합 및 실제 전투/저장 통합은 미검증. 독립 검토 별도 필요.
- 증거 폴더: F:/WorkSpace/new-entry-20261111.
- regression.log, input.log, pad.log, capture.log, 각 화면 PNG.
- SHA256.csv: 신규 변경 파일 목록과 SHA256. asset-inputs.sha256.csv: 참조 원본 자산/데이터 SHA256.
