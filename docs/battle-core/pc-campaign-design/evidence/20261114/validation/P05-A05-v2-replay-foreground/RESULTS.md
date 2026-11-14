# 적벽 v2 공개 리플레이 Windows 전경 검증

2026-11-14 KST. Windows Godot 4.7.2 디버그 실행에서 1600×900 클라이언트를 사용했다. 실행한 소스의 커밋 트리는 시험 당시 원격 `main` `5367d41007266da5de1a0c4c192fe485b703145b`와 일치했다. 작업본에는 기존 Godot 임포트 메타데이터 변경이 있었다. 이전 격리 창이 닫혀 있어 새 APPDATA·LOCALAPPDATA로 출격과 철수를 재현했다.

| 조작 | 전경 관찰 |
| --- | --- |
| 작전 저장 → Withdraw → Finalize withdrawal | 34틱 저장 메시지, 함대 이탈 `fleet_exited`, 88틱(8.8초) 결산 `failure / facility_never_secured` |
| 결산 화면에서 적벽 v2 리플레이 내보내기 | 실제 Godot 파일 선택기에서 격리 폴더를 지정하고 Save를 눌렀다. `red-cliffs-v2.pcop2replay`가 생성됐고 ‘리플레이 내보내기 완료’가 표시됐다. |
| 적벽 v2 메뉴에서 리플레이 보기 | 공개 열기 선택기에서 같은 파일을 선택해 Open을 눌렀다. 뷰어는 0틱에서 열렸다. |
| Play → Pause | Play로 17틱과 18틱이 관찰됐고 재생 중 한 틱 진행 버튼은 비활성화됐다. Pause 뒤 화면을 다시 확인해도 20틱(2.0초)이 유지됐다. |
| Step one tick | 한 번 클릭으로 21틱(2.1초)에 도착했고 다음 화면에서도 21틱이었다. |
| Play → 종결 | 34틱과 65틱을 거쳐 88틱에서 정지했다. 실제 결산과 동일한 결과·사유가 표시됐다. 재생과 한 틱 진행 버튼이 비활성화됐고 이벤트에 `43 withdrawal_started`, `44 fleet_exited`, `88 operation_settled`가 표시됐다. |
| Close replay | 적벽 v2 메뉴로 돌아왔으며 ‘저장한 작전 재개’가 활성화돼 있었다. |

리플레이 본문을 디코딩해 결산 ID `red-cliffs-v2/aea34c66e12d007efbfdc9d99accb328/settlement`, 종료 88틱·8,800ms, 42틱 철수 명령과 87틱 철수 확정 명령을 확인했다. 같은 작전의 34틱 저장과 리플레이 모두 본문 체크섬이 일치했다. 가져오기 직전과 메뉴 복귀 직후의 파일 SHA-256은 각각 동일했다.

| 파일 | 바이트 | SHA-256 |
| --- | ---: | --- |
| `red-cliffs-v2.pcop2replay` | 821 | `77c905b7ac28594f46c4bebf718777f191eeb8b02464507ebe769dcefd0c2b72` |
| `red-cliffs-v2.pcop2save` | 490 | `ccd940344ee70cf4d4cd770dcaa9c87538754bd43a1b8a98c8b4f4c443a5f5b7` |

화면은 이 채팅의 Windows 조작 기록에 있다. 범위는 철수 확정으로 생성한 공개 리플레이 한 건의 소스 디버그 실행이다. [격리 실행 폴더·원본 파일·로그](F:/WorkSpace/Campaign-Orchestration/P05-A05-v2-replay-foreground-24c48d17-r2)

독립 검토에서 원본 두 파일의 체크섬과 결산 내용, 커밋 트리 동일성 및 공개 재생 제어 소스를 대조했다.
