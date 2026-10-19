@echo off
cd /d "%~dp0"

if "%1" == "doit" goto :run_admin

"%~dp0elevator" "%~f0" doit
goto :eof

:run_admin
echo ========================================================
echo Google DNS ve IPv6 DNS Yapilandiriliyor...
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_dns_google.ps1"

echo.
echo ========================================================
pause
