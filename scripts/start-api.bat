@echo off
REM Start API server (development mode)
REM Usage: scripts\start-api.bat

echo Starting Meow API server...

set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR:~0,-1%
set API_DIR=%ROOT_DIR%\apps\api

echo Working directory: %API_DIR%

cd /d "%API_DIR%"

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
  echo Installing dependencies...
  call npm install
)

REM Start development server
echo Starting development server...
call npm run start:dev
