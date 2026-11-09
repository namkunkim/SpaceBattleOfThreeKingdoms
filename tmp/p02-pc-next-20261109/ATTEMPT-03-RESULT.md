# 직접 전환 거절 V6 attempt-03 결과 · 독립 5-b 검토용

판정: 격리 실행 PASS, 독립 5-b 대기. 이번 조각 3/6 사용. 승인 manifest SHA b9fc3b6ce855b52f2d7dd6e0e0e28e7d6ef969c1e86eaa5dbaa0d7c90f51f173의 attempt-03을 기본 sandbox에서 1회 실행했다. runner exit 0 및 completed.json. 제품 원본·테스트·index에는 적용하지 않았다. PC0 2/2, 여덟째 K6 미사용 및 기존 실패 자료를 보존한다.

| Lane | before actual root exit | after actual root exit | 실제 관측 |
|---|---:|---:|---|
| import | 0 | 0 | 각 독립 import 완료. .godot 글로벌 class cache SHA는 양쪽 ed124eccd739e5e865688cc4f906ff9bf6da154828a5d1bef4235ff6397cacb0. |
| reject | 1 | 0 | 양쪽 실제 missing-scene 오류 4쌍, 전체 45행. before 17 PASS/28 의도 FAIL, after 45/45. |
| direct | 0 | 0 | 양쪽 C1–C4 및 왕복 DONE 0. 첫 pressed와 같은 frame handler 재진입을 구별. 이전 artificial detached button 오디오 오류 없음. |
| auto-complete | 0 | 0 | 각 14/14. seed 350157, fingerprint 3028c9c61eadaa2fb1c7a6ea2934f6d2c6b6d079491b4cd0aa1cc1f17e3835c8, 결산 1회 및 결과 값 동일. |
| auto-cancel | 0 | 0 | 각 15/15, 중단 join 및 결과 없음. |
| title | 0 | 0 | 양쪽 UI_FLOW_PASS. |
| restart | 0 | 0 | 양쪽 BATTLE_FLOW_PASS. |

14개 실제 root HANDLE signal 및 exit, 각 Job active 0을 원문에서 다시 확인했다. 보유 자손 HANDLE의 signal은 모두 0이다. import에 각 두 개, before auto-complete에 하나의 보유 자손 identity가 기록됐다. 모든 단명 자손의 신원과 엔진 stdout/stderr는 이 실행으로 확인되지 않았다. Godot 출력은 --log-file, PowerShell의 별도 스트림은 supervisor 증거다. 두 reject lane의 명시 엔진 진단과 before의 의도된 TEST_FAIL 외 예상 밖 ERROR/WARNING·SCRIPT ERROR·parse error를 engine.log에서 관측하지 않았다.

after의 R1은 직접 WorldLink 반환 ERR_CANT_OPEN을 관측했고, A/BS/BN은 실제 기존 버튼 signal과 같은 지도 scene identity, 입력 복구, 이전 link 및 local brief, 결과 identity·표시·버튼·영역, 중복 소비·결산 sound 없는 상태를 대조했다. diff에서 제품 복구가 _show_result, 결과 consume, 신규 결산 sound/timer를 호출하지 않음을 별도 확인한다. 정량 판정은 준비된 테스트가 관측하는 공개 효과에 한정한다. direct의 최종 결과는 기존 강제 sim._end 기반이다. 신규 operation·자연 종료·실제 Windows 마우스나 키보드 입력·제품 PC 전체 플레이의 인수 증거는 없다.

사후 승인 입력 11개, closure 1,480개, 보호 경로 4개, branch/HEAD/index를 다시 해시했다. pre-import manifest에서 두 제품 파일 이외 before/after는 동일하고 기존 P03 private bytes도 동일하다. 각 reject manifest는 각 post-import manifest에서 FleetBattle3D.tscn 하나만 빠졌다. before와 after 모두 편집기 folding만 exact hash로 분류하고 참조 검사 후 시작했다. 검사는 명시한 경로와 시점에 한정된다.

[결과 원문 요약 JSON](attempt-03/result-review-only.json)의 SHA-256은 a22a2f47649e0657b7d618baeab6cd6086d8ae25023d09da2a99ff9a93b43187이다. JSON에는 전 14개 lane의 engine.log/engine.os.tsv/command.json SHA, 실제 exit와 행, 생성 cache 및 fixture manifests SHA가 있다. [완료 마커](attempt-03/completed.json) · [후보 diff](candidate-review.diff) · [V6 테스트 한 줄 변경](v6-review.diff).

원본 반영은 작성자와 별도의 독립 5-b에서 변경·실제 raw 로그 및 결산 보존을 받아들인 뒤, 그 시점의 공유 소유 상태와 원본 SHA를 다시 확인해서 진행한다. 전체 P02는 NOT_READY다.
