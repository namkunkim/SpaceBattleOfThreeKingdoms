# attempt-01 독립 결과 및 fixture 경계

판정: 1/6 소진, 준비 guard에서 중단. 정상 import의 root exit 0, active 0, 보유 자식 두 HANDLE signal을 원문에서 확인했다. 거절 시험 및 after import는 시작하지 않았고 엔진의 ERR_CANT_OPEN이나 테스트 행을 관측하지 않았다. PC0 2/2와 별도 K6 미사용은 그대로다. 자동 재실행 금지.

실제 matched 파일은 .godot/editor/FleetBattle3D.tscn-folding-6fc9f3aa03723dcea84c2d7516fcefec.cfg 단 하나다. 내용은 [folding], node_unfolds, resource_unfolds, nodes_folded, animation_groups_folded의 편집기 접힘 상태이며 장면 리소스나 remap payload가 아니다. 장면 파일은 reject 복제본에서 없었다. runner의 이름 부분문자열 조건이 해당 편집기 메타데이터를 포함하여 사전 guard가 중단됐고 reject-closure.json은 생성 전이다. 이 결과만으로 전체 로드 경로나 엔진 거절을 실증하지 않는다.

다음 독립 계획은 guard의 예외를 .godot/editor/<정확 대상명>-folding-<hex>.cfg 경로와 파싱된 예상 섹션·키로 한정하고 예외 파일을 SHA와 내용으로 기록할 수 있다. 실제 res:// 대상의 부재, 해당 .remap 및 프로젝트 설정 remap·import 메타의 경로 참조 검토, inventory에서 대상 이외 원본/캐시 바이트 동일, F1/F2, 동일 프로세스의 실제 ERR_CANT_OPEN과 기대 loader 로그는 유지해야 한다. 검사 불가능하거나 다른 참조가 있으면 중지한다. 편집기 파일만 지우거나 broad 캐시 전체 허용으로 증거를 약화시키지 않는다. 실행 시 오류가 다르면 원문에 따라 별도 판정한다.

이것은 실패 원인의 파일 기반 분석이며 revised runner/manifest 승인이 아니다. 후속 계획은 기존 1/6을 이어받고 새 attempt 경로와 변경된 runner 및 closure를 동결해 독립 심사를 거쳐야 한다.
