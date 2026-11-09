# 전장 → 천하 거절 복구 독립 closeout

판정: 기존 WorldLink의 즉시 로더 거절 시 상태 복원 조각의 전달을 수용한다. 전체 P02/첫 PC는 미완료다. 실제 OS 입력·자연 종료·사용자용 오류 화면과 전환 수락 후 오류는 범위 밖이며 로그 warning만 존재한다. PC0 2/2 소진, 별도 여덟째 K6 미사용을 유지한다.

ZIP SHA 2b94ac408ca45061c985c3a58ca508de70bf7fff926c6ca249d14dc62bb4ddb4, manifest SHA c044040e1485a6dd51798f314773fca9d28e9d7975ea9b03d8c6d81202260d66을 대조했다. payload 168개와 manifest 1개, 총 169개 중복 없이 CRC 정상이며 payload 전부 크기·SHA·현재 파일 일치다. 원본 WorldLink SHA 42f98746255011935166770bfd070ed60218a227f6051a166adaa3b6353bbb56은 승인 후보와 동일하고 기존 go_battle도 유지된다. 1480개 source는 해당 적용 파일 외 closure와 일치하며 HEAD/index·빈 staged와 기존 baseline ZIP/HTML 62개도 확인했다. 비원자적 baseline을 전체 사용자 파일의 무변이로 확대하지 않는다.

progress.before와 현재 진행표의 차이는 보존된 삽입 구간 하나다. 전달 기록은 원본 반영 후 Godot 미실행, 20 lane/210 검사에서 같은 전장 programmatic 버튼 신호로 두 거절 뒤 재시도, 실제 loader 경고, baseline clean 서막 편차를 구분한다. 독립 5-b 및 적용 후 심사의 원문은 ZIP에 보존된다. P03 idle은 해당 시점 관측이며 향후 소유권 잠금이 아니다. 본 closeout은 ZIP 밖에 기록한다.

공간 정리 후보는 아래 격리 프로젝트의 생성 .godot 캐시뿐이며 아직 삭제하지 않았다. 각 SHA는 해당 디렉터리 파일을 상대 POSIX 경로로 정렬한 [경로,크기,파일 SHA256] 배열을 공백 없는 UTF-8 JSON으로 직렬화한 inventory SHA다. 원본 .godot와 원문 로그·manifest·승인 파일은 제외한다. 삭제 전 현재 경로·inventory를 재확인하고 실제 정리 기록을 남겨야 한다.

- attempt-01/before/project/.godot: 1336파일, 334714604 bytes, 3e68183a148b6e2eaeaebb51b8943c25b4fe834fbbfd1df335a9a179de81bd72
- attempt-02/before/project/.godot: 1336파일, 334714600 bytes, b19a7b28ac492b36e8b6c39b9ff3a7c5d128e187aa8adfc541d84e1c37e1b344
- attempt-02/after/project/.godot: 1336파일, 334714585 bytes, ff072d6b0a2a15c6b16a61e93ba904b1e1d461e9d3ce208e806a4cb84895f5b9

위 경로는 모두 tmp/p02-pc-next2-20261109 아래다. ZIP에는 cache 본문이 없으며 차후 재현시 재import가 필요하다. 실제 모델 ID는 런타임에서 독립 확인하지 못했다.
