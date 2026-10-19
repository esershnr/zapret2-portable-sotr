@echo off
cd /d "%~dp0"

if "%1" == "doit" goto :run_admin

"%~dp0elevator" "%~f0" doit
goto :eof

:run_admin
echo ========================================================
echo Google DNS ve Sifreli DNS Yapilandiriliyor...
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_dns.ps1" -Provider google

echo.
echo ========================================================
pause
