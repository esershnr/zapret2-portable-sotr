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

echo ========================================================
echo Zapret 2 - Blockcheck [kisisel ayar olusturucu]
echo ========================================================
echo.
echo Bu arac internet saglayicinizda hangi DPI atlatma yonteminin
echo calistigini test eder ve size ozel Baslat-Kisisel.bat olusturur.
echo VPN, GoodbyeDPI, baska zapret kopyalari vb. KAPALI olmali.
echo.
echo  1 = Hizli test [1-3 dk, onerilen]
echo      Bilinen stratejileri sirayla dener, ilk calisanda durur.
echo  2 = Tam blockcheck [30-60 dk]
echo      Hizli test bir sey bulamazsa. ~40 MB zapret-win-bundle indirir.
echo.
choice /C 12 /M "Secim"
if errorlevel 2 (set "MODE=full") else (set "MODE=fast")

echo.
echo Calisan zapret durduruluyor...
net stop zapret2 >nul 2>&1
taskkill /F /IM winws2.exe >nul 2>&1
taskkill /F /IM winws.exe >nul 2>&1
"%~dp0killall.exe" -q winws2.exe >nul 2>&1
"%~dp0killall.exe" -q winws.exe >nul 2>&1
net stop WinDivert >nul 2>&1
sc delete WinDivert >nul 2>&1

set "DOMAINS=discord.com"
echo.
echo Test edilecek alan adlari, bosluk ile ayirin.
echo Bos birakirsaniz varsayilan kullanilir: %DOMAINS%
set "INP="
set /p "INP=Alan adlari: "
if defined INP set "DOMAINS=%INP%"
echo.

if "%MODE%"=="full" goto :full

set "LOG=%~dp0blockcheck\hizli-test.log"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0blockcheck\hizli-test.ps1" -Domains "%DOMAINS%" -Log "%LOG%"
goto :generate

:full
if exist "%BC2%" goto :have_bundle

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
set "LOG=%~dp0blockcheck\blockcheck2.log"

rem blockcheck2.sh ayarlari, soru sormadan calismasi icin
set BATCH=1
set TEST=standard
set IPVS=4
set ENABLE_HTTP=1
set ENABLE_HTTPS_TLS12=1
set ENABLE_HTTPS_TLS13=0
set ENABLE_HTTP3=0
set REPEATS=1
set PARALLEL=0
set SCANLEVEL=quick
rem Kisisel .bat'a hic secilmeyecek stratejileri test etme, sureyi cok kisaltir:
rem sabit TTL (1-12 arasi tek tek, hat degisince bozulur; autottl testleri kalir)
set MAX_TTL=0
rem syndata SYN paketinde calisir, site listesiyle (hostlist) birlikte kullanilamaz
set NOTEST_SYNDATA_HTTP=1
set NOTEST_SYNDATA_HTTPS=1
rem Turkiye'de engelli alan adlari ISS DNS'inde hic cozulmeyebilir, test icin DoH kullan
set SECURE_DNS=1
rem DoH sunuculari IP ile: ISS cloudflare-dns.com / dns.google SNI'sini DPI ile kesebiliyor
set "DOH_SERVERS=https://1.1.1.1/dns-query https://8.8.8.8/dns-query https://1.0.0.1/dns-query https://8.8.4.4/dns-query"
set "DNSCHECK_DOM=discord.com pornhub.com"

echo Blockcheck basliyor: %DOMAINS%
echo.

pushd "%BUNDLE%\cygwin\bin"
for /f "usebackq tokens=*" %%F in (`cygpath -C OEM -a -m "%~dp0blockcheck\run.sh"`) do set "RUNSH=%%F"
bash -i "%RUNSH%"
popd

:generate
taskkill /F /IM winws2.exe >nul 2>&1
echo.
echo ========================================================
echo Sonuclar isleniyor...
echo ========================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0blockcheck\strateji-olustur.ps1" -Log "%LOG%" -OutDir "%~dp0."
if errorlevel 1 goto :fail

echo.
echo Hazir! Artik Baslat.bat yerine Baslat-Kisisel.bat kullanin.
echo Arka planda otomatik calismasi icin: Servis_Kur-Kisisel.bat
echo.
pause
exit /b 0

:fail
echo.
echo Kisisel ayar olusturulamadi.
if "%MODE%"=="fast" echo Hizli test bir sey bulamadiysa Blockcheck.cmd'yi tekrar calistirip 2 = Tam blockcheck secin.
echo Test ciktisi: %LOG%
echo.
pause
exit /b 1
