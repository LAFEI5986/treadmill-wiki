@echo off
rem Do NOT add "chcp 65001" here. Switching the codepage mid-script corrupts
rem %~dp0 when the path contains non-ASCII characters, and this folder does.
rem The default OEM codepage renders Chinese fine on a zh-CN Windows.
rem Keep this file pure ASCII so cmd never mis-parses it.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" %*
echo.
echo ----------------------------------------
pause
