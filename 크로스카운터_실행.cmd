@echo off
chcp 65001 >nul
setlocal
if not defined GODOT_EXE set "GODOT_EXE=C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot 실행 파일을 찾을 수 없습니다. GODOT_EXE 환경변수를 지정하세요.
  pause
  exit /b 1
)
start "적벽 크로스 카운터 모의전" "%GODOT_EXE%" --path "%~dp0." --script tools/scenario/cross_counter_drill.gd
endlocal
