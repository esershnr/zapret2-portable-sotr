@echo off
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    "%~dp0elevator.exe" "%~f0"
    exit /b
)

echo ========================================================
echo zapret2 ve WinDivert Servisi Durduruluyor...
echo ========================================================

taskkill /F /IM winws2.exe >nul 2>&1
taskkill /F /IM winws.exe >nul 2>&1
"%~dp0killall.exe" -q winws2.exe
"%~dp0killall.exe" -q winws.exe

net stop WinDivert >nul 2>&1
net stop WinDivert14 >nul 2>&1
sc delete WinDivert >nul 2>&1
sc delete WinDivert14 >nul 2>&1

echo.
echo zapret2 basariyla durduruldu ve surucu sistemden temizlendi.
echo ========================================================
timeout /t 2 >nul
exit
