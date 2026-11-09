# 복귀 거절 attempt-01 독립 결과

판정: 1/6 소진, before 준비 실패 lane의 테스트 SCRIPT ERROR 및 timeout으로 실패. candidate lane은 시작하지 않았다. raw는 invalid_candidate_profile이 실제 _prepare_game에서 거부된 다음 tests/p02_return_probe.gd:71에서 G.state 접근 실패, root 125·소유 Job active 0을 기록한다. supervisor-failure.json은 격리 WorldMap 존재 및 held 부재다. 첫 세 lane에서 관측된 loader 결과는 해당 lane 범위에만 한정하고 전체 성공을 주장하지 않는다.

원문 FleetBattle3D는 G를 빈 Dictionary로 만들고 init_game에서 후보가 거절되면 _publish_game 전에 반환한다. 따라서 최초 준비 실패에서 state 키가 존재하지 않는 것은 정상적으로 가능한 상태다. 단순 get 기본값만 전후 비교하면 키 부재와 동일 기본값을 가진 실제 키가 혼동된다. 최소 수정은 처음에 state 키 존재 여부와 존재시 정확 Variant 값을 각각 보관하고, 거절 전후 존재 여부와 값이 모두 같음을 단언하는 것이다. result/pause는 state 존재 및 기존 값(특히 pause)을 별도 요구한다. 이 조각은 실제 실패 화면/버튼 및 sim identity도 계속 확인해야 하고 SCRIPT ERROR를 예상 진단으로 허용하지 않는다.

수정된 테스트/manifest/runner·입력 SHA와 이전 실패 증거를 동결하고 독립 심사 전 재실행하지 않는다. 재실행은 2/6으로 계산하며 PC0 2/2 및 별도 K6은 그대로다. 격리 프로젝트는 약 5GB가 될 수 있으나 이 심사는 삭제를 승인하지 않았다. 실제 사용자 목표와 디스크 압박에 따라 사후 정리할 경우 필요한 raw logs·SHA·복제 입력 및 held 상태를 먼저 보존하고 경로를 명확히 식별해 증거와 사용자 파일을 제외해야 한다. 현재 파일은 그대로다.
