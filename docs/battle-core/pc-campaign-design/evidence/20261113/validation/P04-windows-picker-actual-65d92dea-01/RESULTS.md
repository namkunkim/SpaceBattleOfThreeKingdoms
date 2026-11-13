# P04 Windows 파일 선택기 실제 입력 결과

후보 `65d92deaa783795d156b5c3f0763d9490d18e978`의 Windows x64 패키지에서 공개 적벽 작전의 외부 저장 왕복을 확인했다. 게임 클라이언트는 1600×900, 제목 표시줄과 테두리를 포함한 창은 1602×932였다. 실행은 새 격리 프로필에서 진행했다. [실행 기록](launch.json) · [엔진 로그](engine.log)

| 관찰한 실제 입력 | 결과 |
| --- | --- |
| 공개 시작 화면에서 적벽 선택, 출격, Start operation | 공개 작전 시작 |
| Save battle 두 번 | 틱 58과 98에서 각각 저장 표시 |
| Export battle… → Godot FileDialog의 Save | `runtime/battle.pcopsave` 생성, 틱 142 내보내기 표시 |
| Import battle… → 같은 파일 선택 → Open | 틱 142 복원 표시와 Resume operation 노출 |
| Resume operation → Alt+F4 | 틱 160까지 진행한 뒤 창이 닫힘. 기록된 PID 23904는 사후 조회 시 종료 상태 |

보존된 외부 파일 (원본 실행 폴더 자료)은 944바이트다. SHA-256은 `f25cb73e0f7ba846f0b31cfb5ce65873cdd8194838050a7cf9b6e2e63feb150a`다. 바깥 형식은 `pc-first-operation-external` v1이며, 디코딩한 UTF-8 body의 재계산 SHA-256이 봉투의 `6e4f07ca7bbe71c821f0639bbdad856d9bf88e4bb9d1e3603cf38830514218ea`와 일치한다. body는 공개 capability `pc/first-operation/1`, front 경로, 틱 142, 논리 시계 14,200 ms를 기록한다. 적용 명령과 대기 명령은 0개이고 event_cursor는 0이다.

| 격리 파일 | 왕복 전·종료 후 SHA-256 |
| --- | --- |
| `pc-first-operation-product-v1.save` | `b66477e4d69d56126ce340223246ad39864c19c1a717eb625955f3a7204539d6` |
| `pc-first-operation-product-v1.save.previous` | `392b5e05e5cc6d19517aa291052738140321448228c4e8c02ecdeba01c3c4a36` |

결산 원장의 두 세대는 준비하지 않았으며 종료 후에도 생성되지 않았다. 실행·프로필 폴더에 `.pending-*`이 없었다. Godot 4.7.2 로그의 ERROR, WARNING, leak, orphan 검색 결과는 0건이다. 종료 코드는 수집하지 않았다.

판정 범위는 실제 Windows 입력을 통한 공개 정상 내보내기·가져오기와 슬롯 두 세대 보존이다. 선택기 취소, 쓰기 실패·재시도, 거부 표본, 기존 결산 세대 보존, 대기 명령 재적용, 소비 이벤트 커서와 K6 정식 인수는 이 실행에서 검증하지 않았다.

- `launch.json` SHA-256 `d71b328a15bbe1e12b2b666686055aaa0f0d5e3fdc0eb3f268b3a42003aae655`
- `engine.log` SHA-256 `4a5271c11c7a060f369d0bb3cff53610529b689930bb4b29b62add0995305ab3`

