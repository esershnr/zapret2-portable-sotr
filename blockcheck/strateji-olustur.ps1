param(
    [Parameter(Mandatory = $true)][string]$Log,
    [Parameter(Mandatory = $true)][string]$OutDir
)

# blockcheck2.log icindeki SUMMARY bolumunden en uygun stratejileri secer,
# Baslat-Kisisel.bat ve Servis_Kur-Kisisel.bat dosyalarini uretir.

$ErrorActionPreference = "Stop"

function Fail($msg) {
    Write-Host $msg -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $Log)) { Fail "Log dosyasi bulunamadi: $Log" }
$lines = Get-Content $Log | ForEach-Object { $_.TrimEnd() }

$dnsSpoofed = [bool]($lines | Where-Object { $_ -match "DNS HIJACK" })
$noResolve = [bool]($lines | Where-Object { $_ -match "could not resolve host|does not resolve" })

$start = [Array]::IndexOf($lines, "* SUMMARY")
if ($start -lt 0) { Fail "blockcheck tamamlanmamis (SUMMARY bolumu yok). Log: $Log" }

# test -> @{ Domains = set; NoBypass = set; Strategies = ordered list of @{ Args; Domains; Index } }
$tests = @{}
$index = 0
for ($i = $start + 1; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    if ($l -eq "" -or $l.StartsWith("* ")) { break }
    if ($l -notmatch '^(curl_test_\S+) ipv\d (\S+) : (.+)$') { continue }
    $test = $Matches[1]; $dom = $Matches[2]; $val = $Matches[3]

    if (-not $tests.ContainsKey($test)) {
        $tests[$test] = @{ Domains = @{}; NoBypass = @{}; Aborted = @{}; Strategies = [ordered]@{} }
    }
    $t = $tests[$test]
    $t.Domains[$dom] = $true

    if ($val -eq "working without bypass") { $t.NoBypass[$dom] = $true; continue }
    if ($val -like "test aborted*") { $t.Aborted[$dom] = $true; continue }
    if ($val -notmatch '^winws2 ' -or $val -like "* not working") { continue }

    # "--wf-*" parametreleri blockcheck'e ozel, gercek yapilandirmada kendi filtrelerimiz var
    $tokens = $val.Substring(7).Split(" ", [StringSplitOptions]::RemoveEmptyEntries) | Where-Object { $_ -notlike "--wf-*" }
    $strat = ($tokens -join " ").Trim()
    if ($strat -eq "") { continue }

    if (-not $t.Strategies.Contains($strat)) {
        $t.Strategies[$strat] = @{ Args = $strat; Domains = @{}; Index = $index++ }
    }
    $t.Strategies[$strat].Domains[$dom] = $true
}

function Get-Penalty($s) {
    # SYN asamasinda calisan yontemler (syndata, wssize, "<s1") hostlist ile birlikte calismaz:
    # SYN aninda alan adi henuz bilinmez. Ozel karakterler .bat icinde sorun cikarir.
    if ($s -match '[<>|&^%!"]' -or $s -match 'syndata|wssize') { return 100000 }
    # sabit TTL, hat/rota degisince bozulabilir
    if ($s -match 'ip6?_ttl=|ip4_ttl=') { return 1000 }
    return 0
}

function Select-Strategy($testNames) {
    foreach ($name in $testNames) {
        if (-not $tests.ContainsKey($name)) { continue }
        $t = $tests[$name]
        $need = @($t.Domains.Keys | Where-Object { -not $t.NoBypass.ContainsKey($_) -and -not $t.Aborted.ContainsKey($_) })
        if ($need.Count -eq 0 -and $t.Aborted.Count -gt 0) { return @{ Status = "aborted"; Test = $name } }
        if ($need.Count -eq 0) { return @{ Status = "nobypass"; Test = $name } }

        $cands = @($t.Strategies.Values | ForEach-Object {
            $s = $_
            $cover = @($need | Where-Object { $s.Domains.ContainsKey($_) }).Count
            [pscustomobject]@{ Args = $s.Args; Cover = $cover; Penalty = (Get-Penalty $s.Args); Index = $s.Index }
        } | Where-Object { $_.Penalty -lt 100000 } | Sort-Object @{ e = "Cover"; Descending = $true }, Penalty, Index)

        if ($cands.Count -eq 0) { return @{ Status = "none"; Test = $name; Need = $need } }
        return @{ Status = "ok"; Test = $name; Args = $cands[0].Args; Full = ($cands[0].Cover -eq $need.Count); Need = $need }
    }
    return @{ Status = "notrun" }
}

$http = Select-Strategy @("curl_test_http")
$tls  = Select-Strategy @("curl_test_https_tls12", "curl_test_https_tls13")

Write-Host ""
Write-Host "HTTP  : $($http.Status) $($http.Args)"
Write-Host "HTTPS : $($tls.Status) $($tls.Args)"
Write-Host ""

$domainList = @($tests.Values | ForEach-Object { $_.Domains.Keys } | Sort-Object -Unique)

# zapret DNS engelini asmaz: sistem DNS'i alan adini cozemiyorsa once DNS degistirilmeli
$sysDnsBad = $false
foreach ($d in $domainList) {
    try { Resolve-DnsName $d -Type A -DnsOnly -ErrorAction Stop | Out-Null } catch { $sysDnsBad = $true }
}

if ($dnsSpoofed -or $sysDnsBad) {
    Write-Host "UYARI: Saglayicinizin DNS'i engelli alan adlarini cozmuyor veya degistiriyor." -ForegroundColor Yellow
    Write-Host "       zapret DNS engelini asmaz, once DNS_Ayarla.cmd veya DNS_Ayarla_Google.cmd calistirin." -ForegroundColor Yellow
    Write-Host ""
}

if (($tls.Status -eq "aborted" -or $tls.Status -eq "notrun") -and $noResolve) {
    Fail "Alan adi cozulemedi, test yapilamadi. Once DNS_Ayarla.cmd calistirip Blockcheck.cmd'yi tekrar deneyin."
}
if ($tls.Status -eq "none") {
    Fail "HTTPS icin calisan bir strateji bulunamadi."
}
if ($tls.Status -ne "ok" -and $http.Status -ne "ok") {
    Fail "Test edilen alan adlarinda DPI engeli tespit edilmedi, kisisel ayar olusturulmadi. Sorun DNS kaynakli olabilir: DNS_Ayarla.cmd calistirin."
}
if ($tls.Status -eq "ok" -and -not $tls.Full) {
    Write-Host "UYARI: Hicbir strateji tum alan adlarinda calismadi, en cok alan adini acan secildi." -ForegroundColor Yellow
}

$domains = $domainList -join " "
$stamp = Get-Date -Format "yyyy-MM-dd HH:mm"

# profil listesi: her eleman bir satir dizisi; {DP} ve {Q} sonra .bat turune gore degistirilir
$profiles = @()
if ($http.Status -eq "ok") {
    $profiles += , @(
        "--filter-tcp=80 --filter-l7=http --hostlist={Q}{DP}files\list-discord.txt{Q} --hostlist={Q}{DP}files\list-other.txt{Q}",
        "  --out-range=-d10",
        "  $($http.Args)")
}
if ($tls.Status -eq "ok") {
    $profiles += , @(
        "--filter-tcp=443 --filter-l7=tls --hostlist={Q}{DP}files\list-discord.txt{Q} --hostlist={Q}{DP}files\list-other.txt{Q}",
        "  --out-range=-d10",
        "  $($tls.Args)")
}
$profiles += , @(
    "--filter-udp=19294-19344,50000-50099 --filter-l7=discord --payload=discord_ip_discovery",
    "  --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=2")

function Build-Args($indent, $q) {
    $out = @(
        "--wf-l3=ipv4,ipv6 --wf-tcp-out=80,443",
        "--wf-raw-part=@{Q}{DP}windivert.filter\windivert_part.discord_media.txt{Q}",
        "--lua-init=@{Q}{DP}lua\zapret-lib.lua{Q} --lua-init=@{Q}{DP}lua\zapret-antidpi.lua{Q}")
    for ($p = 0; $p -lt $profiles.Count; $p++) {
        if ($p -gt 0) { $out += "--new" }
        $out += $profiles[$p]
    }
    $out = $out | ForEach-Object { $indent + $_.Replace("{Q}", $q).Replace("{DP}", "%~dp0") }
    # son satir haric hepsine satir devami
    $res = @()
    for ($j = 0; $j -lt $out.Count; $j++) {
        if ($j -lt $out.Count - 1) { $res += $out[$j] + " ^" } else { $res += $out[$j] }
    }
    return $res
}

$header = @(
    "@echo off",
    "rem Bu dosya Blockcheck.cmd tarafindan $stamp tarihinde otomatik olusturuldu.",
    "rem Test edilen alan adlari: $domains",
    "rem Yeniden olusturmak icin Blockcheck.cmd calistirin.",
    "cd /d `"%~dp0`"",
    "",
    "net session >nul 2>&1",
    "if %errorLevel% neq 0 (",
    "    `"%~dp0elevator.exe`" `"%~f0`"",
    "    exit /b",
    ")",
    "",
    "rem tcp_ts fooling icin TCP timestamp gerekli, Windows'ta varsayilan kapali",
    "netsh interface tcp set global timestamps=enabled >nul 2>&1",
    "")

$baslat = $header + @(
    "rem Acik kalan eski kopyayi kapat",
    "taskkill /F /IM winws2.exe >nul 2>&1",
    "",
    "start `"Zapret 2 - Kisisel`" `"%~dp0winws2.exe`" ^") + (Build-Args "  " '"') + @("", "exit")

$servis = $header + @(
    "echo ========================================================",
    "echo zapret2 Windows Servisi Olarak Kuruluyor [Kisisel Ayar]...",
    "echo ========================================================",
    "echo.",
    "",
    "taskkill /F /IM winws2.exe >nul 2>&1",
    "`"%~dp0killall.exe`" -q winws2.exe >nul 2>&1",
    "net stop zapret2 >nul 2>&1",
    "sc delete zapret2 >nul 2>&1",
    "",
    "set ARGS=^") + (Build-Args "" '\"') + @(
    "",
    "sc create `"zapret2`" binPath= `"\`"%~dp0winws2.exe\`" %ARGS%`" DisplayName= `"Zapret 2 - Kisisel`" start= auto depend= `"tcpip`" >nul",
    "sc description `"zapret2`" `"zapret2 DPI bypass servisi - Blockcheck ile olusturulan kisisel ayar`" >nul",
    "sc start `"zapret2`" >nul",
    "",
    "echo Servis kuruldu ve baslatildi. Kaldirmak icin Servis_Sil.bat calistirin.",
    "echo.",
    "pause")

$enc = New-Object System.Text.ASCIIEncoding
[IO.File]::WriteAllText((Join-Path $OutDir "Baslat-Kisisel.bat"), (($baslat -join "`r`n") + "`r`n"), $enc)
[IO.File]::WriteAllText((Join-Path $OutDir "Servis_Kur-Kisisel.bat"), (($servis -join "`r`n") + "`r`n"), $enc)

Write-Host "Olusturuldu: Baslat-Kisisel.bat ve Servis_Kur-Kisisel.bat" -ForegroundColor Green
exit 0
