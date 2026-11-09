# attempt-02 독립 결과

판정: 2/6 소진, 실제 테스트 실패로 전체 후보 미완료. before import root exit 0 및 Job 정리 뒤 reject에서 실제 loader 오류 네 쌍과 45행(17 PASS/28 FAIL)이 관찰됐다. before direct의 C1–C4 및 완료 마커는 PASS였으나 원문 ERROR가 있어 runner가 중단했다. after 및 auto/title/restart는 실행되지 않았다. PC0 2/2와 별도 K6 미사용 유지, 자동 재실행 금지.

오류 backtrace는 tests/world_link.gd:255 → world_map_screen.gd:150 버튼 공통 사운드 callback → ui_sound.gd:165 AudioStreamPlayer.play이며 노드가 tree 안에 없다고 보고한다. 테스트는 첫 skip으로 장면 변경 직후 C1에서 outgoing scene이 tree 밖임을 확인하고, 같은 detached 버튼의 pressed signal을 인위적으로 다시 발생시킨다. 해당 호출이 사운드 callback을 실행하는 정적 인과와 로그가 일치한다. 이 오류를 사용자 물리 입력에서 재현된 제품 결함으로 주장할 수 없고 기존에 수용된 정상 진단이라고도 볼 수 없다. workspace tmp의 기존 .log 검색에서는 이 문자열이 본 로그에만 있었다.

최소 수정 후보는 테스트에서 이미 tree를 떠난 버튼 전체 신호를 두 번째 발화하지 않고, 동일 프레임 전환 중복 방어를 적절한 생존 객체/공개 경계에서 별도 검증하거나 이미 제거된 outgoing 화면에는 두 번째 실제 입력이 전달되지 않는다는 범위로 검증 목표를 조정하는 것이다. UI 신호와 내부 메서드 직접 호출의 증거 수준을 구분해야 한다. 정확한 수정은 별도 계획·diff 심사 후 결정하며 ERROR를 전역 허용하거나 숨기지 않는다. 정상 1회 전환·결산 원문, 자동/취소, title/restart 및 after 검증은 여전히 남았다.
