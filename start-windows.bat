@echo off
setlocal enableextensions enabledelayedexpansion

echo Starting KidsTube (Windows)...

REM Ensure Node/npm are available
where npm >nul 2>nul
if errorlevel 1 (
  echo npm was not found in PATH. Please install Node.js from https://nodejs.org/
  pause
  exit /b 1
)

REM Install deps if node_modules is missing
if not exist node_modules (
  echo Installing dependencies...
  npm install || goto :error
)

echo Launching dev server at http://localhost:3000 ...
call npm start
goto :eof

:error
echo.
echo Failed to install or start. You can also run:
echo   npm install
echo   npm start
pause
