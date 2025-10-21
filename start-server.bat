@echo off
echo Starting Plan My Trip Website Server...
echo.

REM Try different Python commands
python -m http.server 3000 2>nul
if %errorlevel% neq 0 (
    echo Python not found in PATH, trying alternative...
    py -m http.server 3000 2>nul
    if %errorlevel% neq 0 (
        echo Python not found, trying to find Python installation...
        for /f "tokens=*" %%i in ('where python 2^>nul') do (
            echo Found Python at: %%i
            "%%i" -m http.server 3000
            goto :end
        )
        echo.
        echo Python not found. Please ensure Python is installed and added to PATH.
        echo You can also open index.html directly in your browser.
        echo.
        pause
        goto :end
    )
)

:end
echo.
echo Server should be running at: http://localhost:3000
echo Press Ctrl+C to stop the server
pause
