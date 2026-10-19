@echo off
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    "%~dp0elevator.exe" "%~f0"
    exit /b
)

echo ========================================================
echo zapret2 Windows Servisi Olarak Kuruluyor...
echo ========================================================
echo.

rem tcp_ts fooling icin TCP timestamp gerekli, Windows'ta varsayilan kapali
netsh interface tcp set global timestamps=enabled >nul 2>&1

rem Once acik calisan winws varsa kapatalim
taskkill /F /IM winws2.exe >nul 2>&1
"%~dp0killall.exe" -q winws2.exe >nul 2>&1

rem Eski servisi temizleyelim
net stop zapret2 >nul 2>&1
sc delete zapret2 >nul 2>&1

set ARGS=^
--wf-l3=ipv4,ipv6 --wf-tcp-out=80,443 ^
--wf-raw-part=@\"%~dp0windivert.filter\windivert_part.discord_media.txt\" ^
--lua-init=@\"%~dp0lua\zapret-lib.lua\" --lua-init=@\"%~dp0lua\zapret-antidpi.lua\" ^
--filter-tcp=80 --filter-l7=http --hostlist=\"%~dp0files\list-discord.txt\" --hostlist=\"%~dp0files\list-other.txt\" ^
  --out-range=-d10 ^
  --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_ts=-1000 ^
--new ^
--filter-tcp=443 --filter-l7=tls --hostlist=\"%~dp0files\list-discord.txt\" ^
  --out-range=-d10 ^
  --payload=tls_client_hello ^
  --lua-desync=fake:blob=0x00000000:tcp_md5:repeats=1 ^
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid:repeats=1 ^
  --lua-desync=multisplit:pos=2 ^
--new ^
--filter-tcp=443 --filter-l7=tls --hostlist=\"%~dp0files\list-other.txt\" ^
  --out-range=-d10 ^
  --payload=tls_client_hello ^
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000 ^
--new ^
--filter-udp=19294-19344,50000-50099 --filter-l7=discord --payload=discord_ip_discovery ^
  --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=2

sc create "zapret2" binPath= "\"%~dp0winws2.exe\" %ARGS%" DisplayName= "Zapret 2 - Discord + Web @esershnr SONLINE" start= auto depend= "tcpip" >nul
sc description "zapret2" "zapret2 DPI bypass servisi (Windows baslangicinda otomatik calisir)" >nul
sc start "zapret2" >nul

echo ========================================================
echo Servis basariyla kuruldu ve baslatildi!
echo Bilgisayariniz her acildiginda arka planda otomatik calisacaktir.
echo ========================================================
echo.
pause
