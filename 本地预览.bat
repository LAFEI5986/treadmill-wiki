@echo off
rem No "chcp" call on purpose - see the publish .bat for the reason.
rem Keep this file pure ASCII so cmd never mis-parses it.
cd /d "%~dp0"
echo.
echo   Preview will start at http://localhost:8080
echo   Press Ctrl+C in this window to stop it.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" -Preview
pause
