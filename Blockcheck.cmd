@echo off
setlocal
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    "%~dp0elevator.exe" "%~f0"
    exit /b
)

set "BUNDLE_DIR=%~dp0blockcheck\bundle"
set "BUNDLE=%BUNDLE_DIR%\zapret-win-bundle-master"
set "BC2=%BUNDLE%\blockcheck\zapret2\blockcheck2.sh"
set "LOG=%~dp0blockcheck\blockcheck2.log"

echo ========================================================
echo Zapret 2 - Blockcheck [kisisel ayar olusturucu]
echo ========================================================
echo.
echo Bu arac internet saglayicinizda hangi DPI atlatma yonteminin
echo calistigini test eder ve size ozel Baslat-Kisisel.bat olusturur.
echo.
echo  - VPN, GoodbyeDPI, baska zapret kopyalari vb. KAPALI olmali.
echo  - Test 5-20 dakika surebilir, pencereyi kapatmayin.
echo  - Ilk calistirmada ~40 MB zapret-win-bundle indirilir.
echo.
pause

echo.
echo Calisan zapret durduruluyor...
net stop zapret2 >nul 2>&1
taskkill /F /IM winws2.exe >nul 2>&1
taskkill /F /IM winws.exe >nul 2>&1
"%~dp0killall.exe" -q winws2.exe >nul 2>&1
"%~dp0killall.exe" -q winws.exe >nul 2>&1
net stop WinDivert >nul 2>&1
sc delete WinDivert >nul 2>&1

if exist "%BC2%" goto :have_bundle

echo.
echo Windows Defender zapret dosyalarini "HackTool" olarak gorup silebilir.
echo Bu klasor Defender istisnalarina eklenirse indirilen dosyalar silinmez:
echo   %~dp0
choice /C EH /M "Klasor Defender istisnalarina eklensin mi"
if errorlevel 2 goto :download
set "ZAPRET_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-MpPreference -ExclusionPath $env:ZAPRET_DIR" 2>nul
if errorlevel 1 echo Istisna eklenemedi, devam ediliyor.

:download
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0blockcheck\indir.ps1" -Dest "%BUNDLE_DIR%"
if exist "%BC2%" goto :have_bundle
echo.
echo HATA: zapret-win-bundle indirilemedi veya Defender tarafindan silindi.
echo Klasoru Defender istisnalarina ekleyip tekrar deneyin.
pause
exit /b 1

:have_bundle
set "DOMAINS=discord.com"
echo.
echo Test edilecek alan adlari, bosluk ile ayirin.
echo Bos birakirsaniz varsayilan kullanilir: %DOMAINS%
set "INP="
set /p "INP=Alan adlari: "
if defined INP set "DOMAINS=%INP%"

rem blockcheck2.sh ayarlari, soru sormadan calismasi icin
set BATCH=1
set TEST=standard
set IPVS=4
set ENABLE_HTTP=1
set ENABLE_HTTPS_TLS12=1
set ENABLE_HTTPS_TLS13=0
set ENABLE_HTTP3=0
set REPEATS=2
set PARALLEL=0
set SCANLEVEL=quick
rem Turkiye'de engelli alan adlari ISS DNS'inde hic cozulmeyebilir, test icin DoH kullan
set SECURE_DNS=1
set "DNSCHECK_DOM=discord.com pornhub.com"

echo.
echo Blockcheck basliyor: %DOMAINS%
echo.

pushd "%BUNDLE%\cygwin\bin"
for /f "usebackq tokens=*" %%F in (`cygpath -C OEM -a -m "%~dp0blockcheck\run.sh"`) do set "RUNSH=%%F"
bash -i "%RUNSH%"
popd

echo.
echo ========================================================
echo Sonuclar isleniyor...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0blockcheck\strateji-olustur.ps1" -Log "%LOG%" -OutDir "%~dp0."
if errorlevel 1 goto :fail

echo.
echo Hazir! Artik Baslat.bat yerine Baslat-Kisisel.bat kullanin.
echo Arka planda otomatik calismasi icin: Servis_Kur-Kisisel.bat
echo Tam test ciktisi: blockcheck\blockcheck2.log
echo.
pause
exit /b 0

:fail
echo.
echo Kisisel ayar olusturulamadi. Tam test ciktisi: blockcheck\blockcheck2.log
echo.
pause
exit /b 1
