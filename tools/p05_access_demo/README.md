# P05 독립 PC 접근 검증

검증용 Godot 프로젝트입니다. 저장소의 게임 프로젝트와 분리되어 있습니다. Python 3과 Windows용 Godot 4.7.2를 사용합니다. PowerShell에서 저장소 루트 기준으로 실행합니다.

```powershell
.\tools\p05_access_demo\run.ps1 -Mode WindowsManual
.\tools\p05_access_demo\run.ps1 -Mode WindowsAuto
.\tools\p05_access_demo\run.ps1 -Mode Headless
```

Godot 실행 파일이 다른 위치에 있다면 `-Godot`에 그 경로를 넣습니다. `-EvidenceDir`로 로그와 결과를 저장할 위치를 지정할 수 있습니다. 기본값은 모드마다 새로 만드는 임시 프로젝트 폴더입니다.

- **WindowsManual**은 창의 **Run P05 access checks** 버튼으로 검사합니다. 검사가 끝난 뒤 창을 직접 닫습니다.
- **WindowsAuto**는 Windows 창을 띄우고 같은 버튼 처리기를 자동으로 실행합니다. 그리기가 끝난 프레임을 저장한 다음 종료합니다.
- **Headless**는 창 없이 동일한 이동과 상태 검사를 실행합니다.

검증 시작점은 P05 전용 창입니다. 화면에는 경로, 정지한 외곽, 검사 개수가 표시됩니다. 실제 게임 시작·명령·결산 및 애니메이션은 후속 연결 범위입니다. [P05 접근 계약](../../docs/battle-core/pc-campaign-design/P05-PC-MAP-ACCESS-VALIDATION-20261109.md).
