# 공개 이어하기와 리플레이 테스트 재현

Windows x64의 별도 체크아웃에서 Godot 4.7.2 Windows 콘솔 빌드, Python 3.11 이상, Git 및 MSVC x64 도구와 Windows SDK를 사용한다. MSVC x64 개발자 PowerShell을 열어 저장소 루트에서 실행한다. `$engine`을 설치한 Godot 콘솔 실행 파일로 바꾼다.

```powershell
$engine = 'C:\path\to\Godot_v4.7.2-stable_win64_console.exe'
$scratch = Join-Path $env:TEMP ('sbtk-resumed-replay-' + [guid]::NewGuid().ToString('N'))
$importProfile = Join-Path $scratch 'import-profile'
New-Item -ItemType Directory -Path $importProfile -Force | Out-Null

cmd /c native\o07_win32\build.cmd
if ($LASTEXITCODE -ne 0) { throw 'O07 extension build failed' }

$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = $importProfile
    $env:LOCALAPPDATA = $importProfile
    & $engine --headless --path . --import
    if ($LASTEXITCODE -ne 0) { throw 'Godot asset import failed' }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}

python -B tests/first_operation_public_resumed_replay.py --engine $engine --evidence (Join-Path $scratch 'evidence')
if ($LASTEXITCODE -ne 0) { throw 'Resumed replay regression failed' }
```

O07 DLL과 Godot 임포트 결과는 별도 체크아웃의 로컬 빌드 산출물이다. 생성된 DLL과 임포트 메타데이터는 소스 커밋에서 제외한다. 테스트 러너는 새 `evidence` 폴더에 격리 프로필을 만들고 체크포인트, 이어하기, 공개 리플레이의 세 프로세스를 순차 실행한다. 첫 프로세스에서 저장과 리플레이를 생성하므로 아카이브 픽스처 없이 재현할 수 있다. 검토된 테스트는 19+14+14개 검사를 통과한다. 단계별 로그, 실행한 파일의 SHA-256과 판정은 `evidence/RESULT.json` 및 해당 로그에서 확인한다.

인접 테스트의 입력은 러너별로 다르다. `first_operation_consumer_parity.py`는 자체 입력을 생성한다. `first_operation_public_cursor_fallback.py`는 `first_operation_public_cursor.gd`의 `seed`·`rotate` 단계가 생성한 두 슬롯과 B 오라클을 `--fixture`로 받는다. `first_operation_public_version.py`와 공개 리플레이의 `guard`·`terminal` 러너는 각 러너에 SHA가 고정된 원본을 입력으로 받는다.
