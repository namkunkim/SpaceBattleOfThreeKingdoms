# 전장 → 천하 거절 복구 계획 독립 심사

판정: 한 함수와 독립 fixture의 준비 범위는 수용한다. 현 계획만으로 제품 편집 또는 Godot 실행은 수용하지 않는다. 구체적인 복제 closure·누락 scene fixture·argv/env/timeout·기존 감독기의 고정 SHA·실패/성공 각각의 정확한 assertion과 경고 원문 분모가 아직 제안 수준이다. 이 항목들을 실제 후보 및 테스트와 함께 동결한 후 별도 독립 심사가 필요하다. 사용자에게 재허가를 요청할 필요는 없다.

back_to_world는 void를 유지하면서 변경 전 brief/outcome 객체 참조를 복원할 수 있다. 오류 경고는 개발 로그일 뿐 사용자 화면 표시가 아니다. WorldLink의 기존 go_battle 및 WorldMap 수정은 보호한다. 결과 화면에서는 호출할 때마다 새 BattleOutcome이 만들어질 수 있으므로 이전 대기 outcome 보존은 참조 identity, 성공 전달 결과는 seed·설정 및 독립 기대 필드 값으로 각각 비교한다. null 복귀와 이전 non-null queue의 조합, 실제 result/pause 버튼 및 최초 준비 실패의 직접 link 경로는 서로 다르다. 준비 실패 fixture가 없으면 해당 사용자 경로를 미검증으로 남긴다. 반복 거절에서는 각 시도당 loader 호출/경고 1개와 동일 scene·sim·UI·routed·기존 queue를 확인한다.

WorldMap 누락은 격리 복제본에만 적용하고 main scene/typed class 파싱과 자원 캐시·remap에 의해 테스트가 시작조차 못하거나 다른 scene을 로드하면 무효다. 실제 오류를 엔진에서 관측하며 stub 반환이나 queue 자체의 자가비교만으로 성공을 판정하지 않는다. 동일 전장에서 실제 자산 복원 뒤 retry 성공을 재현하지 못하면 별도 프로세스 성공은 분명히 분리하고 재시도 성공을 주장하지 않는다. 성공시 scene_changed 관찰은 호출 전 연결하고 실제 WorldMap의 표시와 take_outcome 1회 소진, pause/null 경로의 빈 결과를 각각 확인한다.

제시된 26개 baseline은 전체 파일시스템 스냅샷이 아니다. 구체 입력과 P03 등 소유 경계를 직전 재확인하고 격리 사용자 데이터·원본 캐시 보호, 실제 root exit·Job active/retained signal·시간 초과·raw 로그에 근거한 유한 명령을 고정한다. 기존 clean/returning 부트 편차는 실측과 분리하며 예상 밖 오류를 무시하지 않는다. 이 후보 K6은 PC0 2/2 및 여덟째 K6과 별도다. 실제 operation, 자연 종료 또는 사용자 오류 표시는 이 조각으로 인수하지 않는다.
