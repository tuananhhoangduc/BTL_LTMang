@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Color Match Arena - Server

if "%JAVA_HOME%"=="" (
    if exist "C:\Program Files\Java\jdk-24" (
        set "JAVA_HOME=C:\Program Files\Java\jdk-24"
    )
)

set "JAVA_CMD=%JAVA_HOME%\bin\java.exe"
if not exist "%JAVA_CMD%" (
    echo [LOI] JAVA_HOME chua tro toi JDK 24.
    echo JAVA_HOME hien tai: %JAVA_HOME%
    pause
    exit /b 1
)
echo ====================================================
echo Starting Color Match Arena Server (Port 5000)...
echo ====================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Run.ps1" -Server
if errorlevel 1 (
    echo.
    echo [LOI] Khong the chay Server. Vui long kiem tra MySQL trong XAMPP da BAT ^(Start^).
    pause
)
