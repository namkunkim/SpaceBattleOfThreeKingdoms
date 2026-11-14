# Windows 공개 적벽 v1 설정 효과음 검증

2026-11-14 · Windows 1600×900 · 실행 후보 `4dac0b8d` · 기준 main `69fc5df4bcc434ba0c6b3e661fd0c96cc7128ad7`

검토된 실행기와 새 격리 프로필의 사전 점검을 통과했다. 같은 게임 PID 32456에서 소리 탭 무입력 대조를 녹음한 뒤 UI·알림음을 80%에서 85%로 한 단계 변경했다. 창의 실제 클라이언트는 1600×900, DPI 96이었다. 조작 전후 QPC 마커는 준비 메시지 뒤 각각 2.588초와 5.416초였다. UI 입력 호출은 두 마커 사이에 있었고, 격리 설정에는 `ui=0.85`가 저장됐다. 두 녹음 도구는 종료 코드 0으로 WAV를 확정했다. 준비 파일 잠금 때문에 중단된 첫 조작 캡처는 시도 기록에 보존했다.

두 WAV를 600 Hz 하이패스, 모노 4 kHz PCM으로 변환하고 원본 템플릿 전체를 가능한 모든 위치에서 대조했다. 조작 캡처의 `button.wav` 상관계수는 **0.96334**였고 무입력 대조에서는 유효 일치가 없었다. 다른 효과음의 최고 상관계수는 0.18882였다. 버튼음의 근접 정렬은 하나의 단발 신호에 대응했다.

| PCM 근거 | 결과 |
| --- | --- |
| 명목상 템플릿 종료 | 4.496초 |
| 종료점 뒤 확보한 PCM | 5.384초 |
| 종료점 직후 3초 | 왼쪽/오른쪽 peak 160/161, RMS 1.28478/1.28676 |
| 마지막 ±1 초과 신호 | 44.1 kHz 프레임 198341, 4.497528초. 템플릿 종료점 뒤 약 1.528 ms |
| 마지막 신호 뒤 이어지는 PCM | 5.382초. 첫 3초 peak 1/1, RMS 0.478858/0.479221. 같은 구간의 대조군 RMS 0.478866/0.479221 |

상위 모델 독립 검토가 핀·마커·파형을 재계산했다. 짧은 종료 전이 뒤 지속 잔류 신호가 없었으며, QPC 마커는 WAV 표본 시계 계산에 사용하지 않았다. 설정과 오디오 자산은 실행 후보와 기준 main에서 동일했다. `4dac0b8d`의 전경 캡처를 근거로 사용했다.

같은 격리 실행에 배경음 50%를 적용한 뒤 게임은 12:08:10 KST에 종료 코드 0으로 끝났고 엔진 로그에 오류·경고가 없었다. 사용자 장치 기록은 Realtek 스피커, Windows 음량 100%, 음소거 해제다. 해당 종료 전후 청취는 일부 미확인으로 남았다. 별도 청취 응답은 그 응답 후 생성된 재실행 PID와 시간상 연결할 수 없어 완료 근거에서 제외했다.

[실행기·프로필·원시 WAV·QPC·종료 로그](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-red-cliffs-v1-settings-20261114-139c74e1) · [파형 대조 JSON](F:/WorkSpace/Campaign-Orchestration/SpaceBattleOfThreeKingdoms-validation/P09-red-cliffs-v1-settings-20261114-139c74e1/slider-source-comparison.json) · [기존 설정·지도·일반 전투 근거](WINDOWS-BACKGROUND-VERIFICATION-20261113.md)

| 파일 | SHA-256 |
| --- | --- |
| 검토된 `run.ps1` | `5430bb2551d86d7c858041b1e6739be269c16f5889f7b13513f65660acfde7ef` |
| 무입력 `control.wav` | `68d33f93579bb299664c7b5ef51df6a796dba8fea6424cafaf0cb6b98aa52224` |
| 조작 `slider.wav` | `940cdfa398f403cc5c86ec6f42e3e09d928b05d52138d3952eb13a7c336ad419` |
| 원본 `button.wav` | `e06ab62aeef0390e068de71572633c737dc400f474377ae5adc52f2d1160e4ee` |
