# 제품 복원 bridge 계획 독립 심사 — GPT-6 Sol

판정: **정적 경계·후속 인수 설계로 조건부 수용**. `PLAN.md` SHA-256은 `5034ddaedd4b0ee1413961c273d953d456fafedb3be4bc9254e95f6fb13181`이다. 이 판정은 제품 restore 구현·공유 hunk 쓰기·Godot 실행 승인이 아니다.

현재 원문에서 `FleetBattle3D.init_game`은 `_prepare_game`의 raw `BattleSim.new` 후보를 `_publish_game`에 넘긴다. 게시에서 sim·두 시계·표시/선택을 새 전투 값으로 바꾸고 `sim.drain_events()`를 호출한다. 프레임·`update_sim`, `_pump`의 projection/filtered drain, 명령 `sim.issue`, 결산의 raw sim 의존은 별개로 남아 있다. `OperationRuntimeAdapter.normalize`는 `checkpoint`를 `unsupported_checkpoint`로 거부한다. `OperationPrivateState.prepare`는 제한된 packet에서 별도 owner를 만들며, `restore_completed`는 기존 owner 안의 동기 교체이고 제품 host UI/clock 게시를 수행하지 않는다. 따라서 메모리 packet의 별도 준비 진입, owner 공개 API와 호스트 표시·명령·사건 경로의 결합을 구분하는 계획은 타당하다. private `_sim`을 raw host 슬롯에 직접 꽂는 후보를 배제한 것도 적절하다.

지정 생산 `.gd`/`.tscn`의 검색어 `capture_completed|restore_completed|suspend_requested|resume_requested|create_product_native` 결과에서 owner 정의와 SessionGuard 주석·signal·emit 외 직접 제품 복원 호출은 확인되지 않았다. `create_product_native`도 정본에는 없다. 이는 해당 검색어·범위의 정적 미발견이며 래퍼·동적 호출·범위 밖 소비자 부재의 증명이 아니다.

P02 공동 조율 원문은 runtime adapter의 `create_product_native`, FleetBattle3D `_prepare_game`, auto resolver 초기화 세 후보 hunk를 **격리 상태**로 기록하고 현재 공유 제품 쓰기 창이 없다고 명시한다. 제품 공개 진입과 신규 시작/복원 분기, 게시·프레임·명령·결산·trace에 걸친 쓰기 소유는 아직 확정되지 않았다. P02 담당과 조율자가 파일·함수·정확 hunk·입력 baseline·쓰기/실행 창을 합의하고 P02 격리 K6의 독립 결과를 대조한 뒤에야 공유 변경 계획을 심사할 수 있다. 별도 메모리 restore API의 이름·packet 형식·지원 프로필·owner 수명과 실패 정리는 아직 미정이므로 이 문서는 구현 지시서로 충분하지 않다.

후속 실제 제품 시험에는 성공 전/후 후보 identity, 동일 sim/tick/논리 clock/투영, 이전 owner 명령 차단, pending·미소비 사건 보존과 초기 drain 금지, 첫 프레임 phase 정책을 하나의 명시 계약으로 사전등록해야 한다. 실패는 기존 sim/owner identity, 두 누산기, speed/pause, 선택·투영·사건, 다음 정상 프레임을 공개 진입에서 비교한다. 지원 밖 모듈 및 packet 구조 오류의 정확한 반환도 명시한다. 이름별 단언 수·예상 오류·exit·timeout, engine/class map·fixture·정본 SHA 및 Job/진단/전후 입력 manifest를 별도 독립 심사한다. 현재 `init_game`의 legacy 정상·오류 대조를 실행한다면 **legacy 대조**로만 귀속한다.

현재 HEAD는 `0be09755b70378286105972f35ac5b7031715664`, FleetBattle3D SHA-256 `604b79308d9b3dbab84dced32456a4f41b28686c8eec748073d3816892cffc5c`, runtime adapter `0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a`, private owner `46b6fe191166ec3dcdb620f51c3ccd391a9080f52289517ae804bf86cecc1ea3`으로 계획의 읽기 값과 맞는다. owner와 P02 진행표의 기존 Git 수정 상태를 보존한다. 이 계획 심사 중 생산 변경·Godot 실행은 없었다. 검토 모델은 사용자 요청에 따른 GPT-6 Sol 배정이며 별도 실행 모델 메타데이터는 없다.
