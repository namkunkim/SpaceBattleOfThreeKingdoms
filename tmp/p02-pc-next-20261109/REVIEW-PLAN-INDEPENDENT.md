# 직접 출격 전환 거절 계획 독립 심사

판정: 구현과 검증 설계 준비 범위는 수용하나 현 계획만으로 제품 수정 및 Godot 실행은 미수용이다. 계획 자체가 오류 fixture의 실현 여부, 정확한 명령·단언·시간·예상 진단 및 입력 closure를 미확정으로 남기고 이를 독립 심사에서 먼저 확정하도록 요구한다. 진행 중인 baseline 수집 완료 및 실제 대상 SHA·병행 소유 상태 재대조도 필요하다. 사용자 확인 요청은 필요하지 않다.

원문상 WorldLink는 네 필드를 변경하고 엔진 반환 오류를 버리며 지도는 leaving/input_lock 상태를 유지한다. 오류시 이전 객체 참조와 설정 값을 되돌리고 출발지가 browse 또는 result인지 구별하는 계획은 유효하다. 결과 객체 identity, seed·레이블·버튼, 결과 재소비/음향·타이머 부재를 확인해야 한다. _enter_browse만으로 기존 result가 복구되지는 않는다. 성공 경로는 전환 전에 기존 값이 공개되어야 하고, OK 뒤 outgoing node가 tree에서 즉시 제거되고 새 노드는 프레임 말에 들어가므로 복구 로직을 성공 분기에 수행하면 안 된다. OK는 다음 scene의 준비 또는 자연 전투 종료 보증이 아니다. Godot 공식 문서: https://docs.godotengine.org/en/stable/classes/class_scenetree.html .

정확한 fixture는 원본을 변경하지 않는 격리 프로젝트에서 실제 change_scene_to_file의 엔진 거절을 발생시키고 오류·current scene identity·네 필드 참조/값 및 UI 복구를 관찰해야 한다. 캐시·동일 프로세스 성공 가능성은 실측 전 가정하지 않는다. browse, result의 실제 같은 판/새 판 연결, 중복 skip/자동 end, 정상 direct 한 번, 기존 auto/title 범위를 중복 없이 명시하고 각각 실제 실행된 case 수를 기록한다. 새 suite를 금지하는 문구 때문에 요구 행을 관찰하지 못하면 PASS가 아니라 결손이다. 예상 엔진 진단과 SCRIPT ERROR·종료코드·timeout을 구별하고, 결과가 나오기 전 테스트 실행 상한과 정확한 fixture/argv/environment를 고정한다.

WorldLink 부재 시 기존 auto fallthrough를 유지한다는 계획은 최소 범위 정책이며 별도 UX 결함 가능성을 이 수정의 해결로 주장하지 않는다. PC0 2/2와 별도 K6는 유지한다. 이것은 기존 제품 전환 경계의 오류 처리이며 첫 PC operation 연결 또는 완료가 아니다.
