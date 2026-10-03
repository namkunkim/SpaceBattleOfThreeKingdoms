@echo off
chcp 65001 >nul
setlocal
rem Godot 경로: 환경변수 GODOT_EXE > PATH의 godot > 기본 설치 경로 순으로 찾는다.
if not defined GODOT_EXE (
  for %%G in (godot.exe godot4.exe Godot_v4.7.2-stable_win64.exe) do (
    if not defined GODOT_EXE if not "%%~$PATH:G"=="" set "GODOT_EXE=%%~$PATH:G"
  )
)
if not defined GODOT_EXE set "GODOT_EXE=C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
  echo Godot 실행 파일을 찾을 수 없습니다:
  echo %GODOT_EXE%
  echo 환경변수 GODOT_EXE에 Godot 4.7 실행 파일 경로를 지정하세요.
  pause
  exit /b 1
)

start "성한지 우주함대 3D 전투 POC" "%GODOT_EXE%" --path "%~dp0."
endlocal
