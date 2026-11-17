@echo off
setlocal EnableExtensions

rem Script lives in the same folder as this .bat
set "SCRIPT=%~dp0Rename-InterviewFiles.ps1"

if not exist "%SCRIPT%" (
    echo [ERROR] Script not found: "%SCRIPT%"
    pause
    exit /b 1
)

set "TARGET="
set /p "TARGET=Enter the candidate folder to process (e.g. C:\Users\Amy\Downloads\20261116-DS-XXX): "

rem Remove surrounding double quotes in case the path was pasted with them
set "TARGET=%TARGET:"=%"

if "%TARGET%"=="" (
    echo [ERROR] No folder entered.
    pause
    exit /b 1
)

if not exist "%TARGET%\" (
    echo [ERROR] Folder not found: "%TARGET%"
    pause
    exit /b 1
)

rem The PowerShell script uses Get-Location, so run it from inside the target folder
cd /d "%TARGET%"
echo.
echo Working folder: %CD%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

echo.
pause
endlocal
