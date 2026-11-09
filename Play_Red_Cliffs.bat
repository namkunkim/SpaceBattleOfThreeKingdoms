@echo off
setlocal
set "GAME_DIR=C:\WorkSpace\SpaceBattleOfThreeKingdoms"
set "GAME_EXE=C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe"

if not exist "%GAME_DIR%\project.godot" (
  echo ERROR: Game project not found at "%GAME_DIR%".
  pause
  exit /b 1
)
if not exist "%GAME_EXE%" (
  echo ERROR: Godot executable not found at "%GAME_EXE%".
  pause
  exit /b 1
)
if /i "%~1"=="--check" (
  echo OK: Game project and Godot executable found.
  exit /b 0
)
start "Space Battle Of Three Kingdoms" /d "%GAME_DIR%" "%GAME_EXE%" --path "%GAME_DIR%"
if errorlevel 1 (
  echo ERROR: Failed to launch the game.
  pause
  exit /b 1
)
endlocal