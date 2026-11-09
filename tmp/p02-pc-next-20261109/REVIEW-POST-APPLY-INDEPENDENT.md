# 직접 출격 장면 거절 · 적용 후 독립 심사

판정: 심사된 두 제품 파일 적용을 수용한다. 원본 수정이나 추가 엔진 실행은 이 심사에서 하지 않았다. scripts/world_link.gd와 view/world/world_map_screen.gd는 독립 5-b의 후보 및 격리 after 실제 실행 입력과 각각 byte 동일하다. 적용 전 해시는 동결 closure와 일치하며 결과 JSON 및 diff SHA는 인계 값과 같다. 허용된 변경은 WorldLink 전환 요청의 즉시 오류시 네 필드 참조/값 복원 및 WorldMap 출발 화면/입력·결산 복구와 오류 표시다. 성공과 자동 해결 경로는 해당 branch를 유지한다.

closure 1480개 중 두 적용 대상을 제외한 전 파일이 현재 기록된 해시와 같고, tests/world_link.gd 및 P03 private state·worker·project 설정·P02 진행표 네 보호 대상도 같다. 격리 양쪽 class cache 및 HEAD, 빈 staged diff, index SHA를 대조했다. 두 파일에 대한 git diff --check actual exit 0이며 LF/CRLF 설정 경고가 있었다. 이는 지정된 파일과 시점의 확인이지 전체 사용자 데이터의 전역 보존 증명이 아니다.

독립 5-b에서 실제 14개 격리 lane 원문·종료·정리 및 45행 거절/성공·회귀를 확인했고 현재 원본 바이트가 해당 after 실행과 같다. 적용 이후 원본에서 Godot을 다시 실행한 증거는 없다. ERR_CANT_OPEN 같은 즉시 거절에 한정되며 장면 수락 후 내부 준비 실패, 귀환 경계, 실제 OS 입력·자연 종료·첫 PC operation 및 P02 전체는 미검증이다. PC0 2/2와 별도 K6 미사용을 변경하지 않는다. 정확한 모델 ID는 런타임에서 독립 확인할 수 없어 추정하지 않는다.
