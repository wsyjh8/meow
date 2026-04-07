@echo off
REM Start Flutter mobile app (development mode)
REM Usage: scripts\start-mobile.bat

echo Starting Meow Flutter app...

set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR:~0,-1%
set MOBILE_DIR=%ROOT_DIR%\apps\mobile

echo Working directory: %MOBILE_DIR%

cd /d "%MOBILE_DIR%"

REM Get dependencies
echo Getting Flutter dependencies...
call flutter pub get

REM Run the app
echo Running Flutter app...
call flutter run
