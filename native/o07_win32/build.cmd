@echo off
setlocal
if not defined VCToolsInstallDir call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b %errorlevel%
set "O07_TEST_DEFINE="
if /i "%~1"=="test" set "O07_TEST_DEFINE=/DO07_TEST_CHECKPOINTS"
set "O07_BUILD_DIR=%TEMP%\o07_win32_%RANDOM%_%RANDOM%"
mkdir "%O07_BUILD_DIR%" || exit /b 1
pushd "%O07_BUILD_DIR%" || exit /b 1
cl /nologo /LD /std:c17 /W4 /O2 /MT %O07_TEST_DEFINE% "%~dp0o07_win32.c" /link /out:o07_win32.dll
set "O07_BUILD_RESULT=%errorlevel%"
if not "%O07_BUILD_RESULT%"=="0" goto cleanup
copy /y o07_win32.dll "%~dp0o07_win32.dll" >nul
set "O07_BUILD_RESULT=%errorlevel%"

:cleanup
for %%F in (o07_win32.obj o07_win32.lib o07_win32.exp o07_win32.dll) do if exist "%%F" del /q "%%F"
popd
rmdir "%O07_BUILD_DIR%"
exit /b %O07_BUILD_RESULT%
