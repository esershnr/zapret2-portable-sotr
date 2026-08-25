@echo off
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    "%~dp0elevator.exe" "%~f0"
    exit /b
)

echo ========================================================
echo zapret2 Servisi Kaldiriliyor...
echo ========================================================
echo.

net stop zapret2 >nul 2>&1
sc delete zapret2 >nul 2>&1

taskkill /F /IM winws2.exe >nul 2>&1
taskkill /F /IM winws.exe >nul 2>&1
"%~dp0killall.exe" -q winws2.exe >nul 2>&1
"%~dp0killall.exe" -q winws.exe >nul 2>&1

net stop WinDivert >nul 2>&1
net stop WinDivert14 >nul 2>&1
sc delete WinDivert >nul 2>&1
sc delete WinDivert14 >nul 2>&1

echo ========================================================
echo Servis ve suruculer basariyla silindi/kaldirildi.
echo ========================================================
echo.
pause
