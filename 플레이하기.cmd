@echo off
setlocal
set "GODOT_EXE=C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
  echo Godot 실행 파일을 찾을 수 없습니다:
  echo %GODOT_EXE%
  pause
  exit /b 1
)

start "성한지 우주함대 3D 전투 POC" "%GODOT_EXE%" --path "%~dp0"
endlocal
