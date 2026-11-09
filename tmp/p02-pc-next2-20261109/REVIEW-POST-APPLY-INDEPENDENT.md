# 전장 → 천하 거절 복구 적용 후 독립 심사

판정: 심사된 WorldLink.back_to_world 한 함수의 원본 적용을 수용한다. 현재 scripts/world_link.gd SHA 42f98746255011935166770bfd070ed60218a227f6051a166adaa3b6353bbb56은 승인 후보 및 실제 격리 after 입력과 byte 동일하다. 적용 전 후보 대비 diff는 이 함수의 이전 brief/outcome 복원 및 경고만 포함하며, 기존 go_battle 출격 수정은 보존된다.

나머지 source 1479 및 보호 baseline 26 경로는 해당 적용 대상을 제외하고 동결 SHA와 같다. HEAD 0be09755, index 6980bad4… 및 빈 staged를 확인했고 이 파일 scoped git diff --check exit 0이다(LF/CRLF 경고). apply-result SHA cb189a263230b36f6469c6fa548023eb670a2c9fed07e445f203bdb2e0499ac8. 이는 확인 시점과 명시 경로의 관측이며 다른 작업의 장래 변경 또는 전체 사용자 데이터 무변이 보장은 아니다.

실제 Godot 근거는 원본 적용 후 재실행이 아닌 동일 바이트의 격리 20 lane·210 assertion 및 독립 5-b다. 프로그램 발화 버튼·강제 sim._end는 OS 입력이나 자연 플레이가 아니다. WORLD_RETURN_REJECTED는 로그 경고이며 사용자 화면 오류 표시가 없다. 즉시 로더 거절 외 제품 운영 복원, PC0, 별도 K6 및 P02 전체는 미인수다. 이 심사는 제품 파일 변경이나 디스크 정리를 하지 않았다. 정확한 모델 ID는 이 런타임에서 독립 확인하지 못했다.
