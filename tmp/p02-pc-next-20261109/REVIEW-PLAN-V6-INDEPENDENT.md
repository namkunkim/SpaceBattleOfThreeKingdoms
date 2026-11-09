# V6 독립 계획 심사

판정: 동결된 attempt-03 한 회 수용. engine 실행·제품 변경은 이 심사에서 하지 않았다. 2/6 사용 후 이번은 3/6이며 PC0 2/2 및 별도 K6 미사용은 바꾸지 않는다. 승인 manifest는 review-only의 status만 변경한 DIRECT-MANIFEST-V6-INDEPENDENT-APPROVED.json이다.

기존 두 번째 detached 버튼 signal 대신 동일 frame에서 아직 해제 전인 outgoing WorldMap의 _finish_sortie를 직접 호출한다. Godot scene change는 기존 scene을 즉시 tree에서 떼고 프레임 말에 해제하므로 호출은 이미 leaving 상태의 조기 반환을 검사한다. 이는 handler 재진입 검증이지 두 번째 OS/UI 입력 증거가 아니다. 성공 경로에서 다른 side effect가 없고 scene_changed 한 회인지 raw 결과로 확인한다. A/B 실패시 scene은 tree에 남아 기존 실제 버튼 신호를 사용한다. 미예상 오디오 또는 다른 오류를 허용하지 않는다.

11개 입력과 source 1480·보호 4개 SHA가 검토 시점에 일치하고 attempt-03이 없다. 이전 V5 guard와 독립 fixture·45행·엄격한 오류·root exit/Job 정리 조건을 유지한다. 실제 engine parsing, test 행 및 cleanup은 새 실행에서 확인해야 한다. 원본 파일 적용 전 독립 5-b 및 P03 최신 상태 확인이 필요하며 이번 결과가 PC0, 실제 GUI 입력, 자연 종료 또는 P02 완료를 뜻하지 않는다.
