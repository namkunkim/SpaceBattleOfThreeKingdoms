# Windows 공개 적벽 v1 릴리스 후보와 성능 계측

2026-11-14 · 후보 빌드 소스 `69fc5df4bcc434ba0c6b3e661fd0c96cc7128ad7`

Godot 4.7.2 공식 지문 빌더로 Windows 릴리스 EXE와 Win32 DLL을 생성했다. 출시 후보와 기준 main `f1b2822100e18bc3f59fec9287563cdf9e0c1b32`의 차이는 P09 근거와 체크리스트 두 Markdown 파일이다. 첫 임포트는 Win32 확장 임시 사본 오류와 진행 지연으로 중단했다. 동일 제품 소스를 사용하는 5d27ec9b의 임포트 캐시를 복사한 뒤 재임포트와 공식 빌드를 완료했다. 패키지의 기준 스크립트 18개 지문과 내장 팩 런타임 검증이 통과했다. 새 격리 프로필에서 헤드리스 타이틀 진입을 확인했다. PID 24544, 종료 코드 0, 진단 없음이다.
상위 모델이 패키지 파일 해시와 저장·리플레이 지문을 재계산했다. 스테이징과 최종 내장 팩에서 토큰·리맵을 대조했고 원본 GDScript가 없음을 확인했다. 이전 스테이징과 파일 크기 418,965,172바이트와 항목 수 1,757개가 같으며, 새 PCK 해시는 다르다. 장면 7개의 내보낸 페이로드 차이를 확인했다.

| 근거 | SHA-256 |
| --- | --- |
| Windows 릴리스 EXE | `e555be3f85d44c337c6b5070d30e9623b0292cc293cff909dd9442379ad116a4` |
| Win32 DLL | `3866b1c2120b2501afcef6ca613aa527b06640e46e4530f9b43c5fbb939edd4d` |
| 저장 지문 | `517027d6ceeaebba808bcddc38965f7ef411b9e94888e9192c1e16f6b76dcc62` |
| 리플레이 지문 | `98e0767ad293b23338285dde9751a53f4db6c254f14b6d07eb6663290186ab54` |
| 스테이징 PCK | `ef896ebf0bb21ddb035b93c2cd71204a2c7599db65124ae4b957f838d405b932` |

[패키지 해시](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/Windows-release-69fc5df4-v1-01/hashes.json) · [공식 빌드 출력](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/Windows-release-69fc5df4-v1-01/build.log) · [격리 기동 결과](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/Windows-release-69fc5df4-v1-01/smoke/result.json)

## 실전 계측 대기

Windows 세션 2에서 관리자 SID가 거부 전용이고 Performance Log Users SID가 없다. 이전 PresentMon 2.6.0 실측 시도에서 ETW trace session은 `access denied`를 반환했다. 종료 코드 6, 샘플 0이다. 이번에는 권한을 동일하게 확인했으며 그 시도를 반복하지 않았다. Windows 릴리스의 1600×900 실전 1× 프레임 시간과 미표시 프레임은 미측정이다.

같은 Windows 데스크톱에서 승인된 ETW 권한 토큰을 확보한 뒤, 고정된 EXE·DLL로 격리 게임을 실행한다. 권한 셸에서 같은 PID에 PresentMon을 연결한다. 실제 1600×900 창·브리핑·실전의 QPC 구간·게임 스왑체인을 기록한 뒤 원시 CSV로 프레임 시간과 미표시 프레임을 계산한다. 실행기와 분석기는 독립 검토를 받았다. 준비 기록에 이어 최종 CSV의 정확한 PID·스왑체인·구간·실전 1×를 확인해야 한다.

[계측 재개 카드](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P08-presentmon-release-69fc5df4-v1-command-pack/OPERATOR-CARD.md) · [기존 실제 ETW 오류](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/sbtk-p08-etw-82fbc41037ed/stderr.txt)
