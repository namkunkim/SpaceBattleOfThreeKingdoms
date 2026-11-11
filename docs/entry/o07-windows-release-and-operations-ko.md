# O07 Windows 빌드와 운영 인계

Windows x64에서 O07은 제품 EXE에 `--o07-supply`를 준 경우에 시작한다. 인수만 주면 호스트의 재개 화면이 열리고, `--restricted-operation-input`으로 입력 파일을 함께 주면 호스트가 해당 파일을 준비한다. 저장과 재개는 호스트의 버튼에서 시작한다. 확정 결산은 호스트의 지도 복귀에서 같은 ID로 표시한다.

## Windows 패키지 빌드

승인된 Godot 4.7.2 Windows 엔진·템플릿과 MSVC x64 도구를 사용한다. 프로젝트 루트에서 먼저 Win32 확장을 빌드한 뒤 지문 빌더를 실행한다. 네이티브 빌드는 인수 없이 실행해야 강제 종료 시험용 훅이 빠진 DLL이 생성된다. 출력 경로는 새 디렉터리로 지정한다.

```powershell
cmd /c native\o07_win32\build.cmd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python tools/build_fingerprinted_windows.py C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe out/windows-release
```

디버그 패키지도 같은 빌더에 `--debug`를 주어 생성한다. Windows PC 프리셋의 직접 디버그·릴리스 내보내기는 지문 생성 없이 패키지가 나가는 것을 막기 위해 차단된다. 공식 빌더는 토큰과 remap, 매니페스트 앵커를 최종 EXE에서 대조한다. 출력 EXE 옆의 `o07_win32.dll`과 빌드 입력 DLL의 SHA-256을 확인하고 두 파일을 한 쌍으로 보관한다. `_build`에는 매니페스트와 검증 로그가 있다.

저장과 리플레이 지문은 원문 파일 바이트를 해시한다. 같은 코드라도 체크아웃 줄바꿈이 달라지면 지문이 달라질 수 있다. 배포 승인에는 커밋, 빌드에 사용한 원문 SHA, O07과 리플레이 매니페스트, 최종 EXE·DLL SHA를 함께 기록한다. 승인 후보의 원문 바이트를 재현하지 못한 빌드는 별도 대상으로 저장·리플레이 호환성을 검증한다.

```powershell
& .\out\windows-release\SpaceBattleOfThreeKingdoms.exe -- --o07-supply
& .\out\windows-release\SpaceBattleOfThreeKingdoms.exe -- --o07-supply --restricted-operation-input C:\path\input.json
```

## 실제 운영 슬롯 전환

실제 운영 슬롯 전환에는 별도 승인과 운영 담당자가 필요하다. 최종 대상 패키지의 EXE·DLL SHA와 지문, 지정 primary의 작전 ID·세대·순번·영수증, 승인된 원본·후보·기존 백업 SHA를 같은 승인 기록에 묶는다. 이전 개발 슬롯은 승인된 이전·대상 지문 쌍에 한해 오프라인 복제본으로 검증한다. 빈 지문이나 승인 목록 밖 지문, 오래된 백업과 pending은 운영 권위의 근거로 삼을 수 없다.

전환 창에서 기존·신규 writer와 자동 재시작을 동결하고, 같은 네이티브 배타 잠금 아래에서 슬롯과 보존본을 재대조한다. 지정 경로의 primary만 교체하고 같은 세대와 영수증으로 재개되는지 확인한 뒤 새 writer 한 쪽을 활성화한다. 첫 쓰기와 외부 효과가 발생하기 전에는 현재 후보 및 보존본 SHA를 대조해 원래 primary와 백업을 복원할 수 있다. 새 쓰기나 외부 효과가 확인된 뒤에는 최신 head를 보존해 전진 복구를 판단한다. primary와 백업의 갱신은 별도 연산이므로 전환 중단으로 승인된 파일 쌍을 확인할 수 없으면 writer를 동결한 상태에서 복구 승인을 받는다.

격리 리허설에서 Win32 잠금·같은 primary 게시·첫 쓰기 전 복원·쓰기 후 롤백 거절을 확인했다. 실제 운영 전환 승인에는 최종 빌드와 운영 슬롯의 재대조가 필요하다. 배포 EXE 전경 재개 조작과 실기기 전원 상실은 각자의 실행 조건과 별도 검증이 필요하다.

## 외부 지급

현재 제품의 외부 지급 요청은 `external_payment_contract_missing`으로 종료된다. 제품 인수에는 승인된 수신자 식별자와 연동 설정, 결산 ID와 효과를 결합한 요청 계약, 영속적 중복 제거, 같은 ID에 다른 효과가 도착했을 때의 충돌 응답, 승인된 비운영 검증 환경이 필요하다. 요청 전송 후 응답을 잃은 상태에서 재시작하고 같은 ID를 재전송해 수신자 원장이 한 건인지 확인한다. 같은 ID에 변경된 효과도 보내 거절과 원장 불변을 대조한 뒤 운영 승인을 받는다.

[현재 제품 인수 항목](../battle-core/CHECKLIST-OPEN.md)
