# 전환 거절 계획 V2 독립 심사

판정: fixture·검증 분모의 구체화는 수용하나 아직 실행 계획으로는 반려한다. 계획은 argv를 나중에 materialize한다고만 하고 실행 runner 자체를 특정·동결하지 않는다. 이전 PC0 GUI 감독기는 stdout/stderr를 캡처하지 않으며, 여기서는 console 래퍼·Godot 자손의 stdout/stderr, timeout 및 소유 자손 정리를 요구한다. 어떤 소스와 실행 파일이 이 동작을 수행하는지, pipe drain과 정확한 Job 할당·cleanup·exit 기록이 어떻게 구현되는지 확인되지 않아 이 14회 명령의 실행 가능성과 사용자 프로세스 보호를 독립 검증할 수 없다. 구체 runner/입력 closure·생성될 test hunk를 동결해 별도 검토해야 한다. baseline 수집 중 상태가 변했으므로 실행 직전 scoped SHA 및 비소유 P03 경로도 재확인한다. 이는 사용자 승인을 요청하라는 뜻이 아니다.

45 단언과 엔진 거절 4회, 별도 성공 및 auto/title/restart 경계는 유용하다. 다만 현재 선언은 아직 구현되지 않은 가설이다. fixture에서 제거된 씬을 캐시·remap이 되살리지 않는지와 actual ERR_CANT_OPEN을 검증하고, 리소스 누락이 WorldMap 및 typed class 사전 로딩을 막으면 정상 거절로 집계하지 않는다. before void 반환과 실패 단언이 나머지 모든 케이스의 실행을 막지 않도록 각 ID/실행 여부를 기록한다. 성공 lane의 scene_changed 수신을 전환 전에 연결하고 outgoing node 접근 수명과 강제 종료의 한계를 지킨다. 테스트가 다른 경로를 통해 prior result나 영역 표현을 파괴하지 않는지 구현 diff와 실제 raw 결과를 함께 심사한다.

14 프로세스 상한 합계는 1,640초이나 이는 개별 timeout 합계이고 import 복사·진단·정리 등을 포함한 전체 벽시계 보장은 아니다. 6회는 이 별도 변경 후보에 한정된 상한이며 PC0 2/2 또는 기존 K6을 리셋하지 않는다. 사용자 파일과 기존 run 데이터를 재사용·삭제하지 않는다. 이 작업은 legacy 전환 거절 처리이지 자연 종료, operation 또는 P02 완료 증거가 아니다.
