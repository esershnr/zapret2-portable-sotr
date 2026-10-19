param(
    [string]$Domains = "discord.com",
    [Parameter(Mandatory = $true)][string]$Log
)

# Hizli strateji testi: blockcheck2 gibi yuzlerce stratejiyi taramak yerine Turkiye'de
# bilinen, hostlist ile uyumlu stratejileri sirayla dener ve ilk calisanda durur.
# Cikti blockcheck2 SUMMARY formatinda yazilir, strateji-olustur.ps1 ayni sekilde isler.

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
$winws = Join-Path $root "winws2.exe"
$curl = Join-Path $env:SystemRoot "System32\curl.exe"
$hostlist = Join-Path $PSScriptRoot "test-hostlist.txt"
$doms = @($Domains.Split(" ", [StringSplitOptions]::RemoveEmptyEntries))

# en az mudahaleciden en karmasiga
$strategies = @(
    "--lua-desync=multisplit:pos=1",
    "--lua-desync=multisplit:pos=2",
    "--lua-desync=multisplit:pos=sniext+1",
    "--lua-desync=multisplit:pos=1,midsld",
    "--lua-desync=multidisorder:pos=1",
    "--lua-desync=multidisorder:pos=1,midsld",
    "--lua-desync=fake:blob=fake_default_tls:tcp_md5",
    "--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000",
    "--lua-desync=fake:blob=fake_default_tls:tcp_seq=-3000",
    "--lua-desync=fake:blob=fake_default_tls:badsum",
    "--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,sni=www.google.com",
    "--lua-desync=fake:blob=0x00000000:tcp_md5:repeats=1 --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid:repeats=1 --lua-desync=multisplit:pos=2",
    "--lua-desync=fake:blob=fake_default_tls:tcp_md5 --lua-desync=multisplit:pos=1",
    "--lua-desync=fake:blob=fake_default_tls:tcp_md5 --lua-desync=multidisorder:pos=1,midsld",
    "--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000 --lua-desync=multidisorder:pos=1,midsld",
    "--lua-desync=fake:blob=fake_default_tls:badsum --lua-desync=multidisorder:pos=1,midsld",
    "--lua-desync=multisplit:pos=1:seqovl=#fake_default_tls:seqovl_pattern=fake_default_tls",
    "--lua-desync=fakedsplit:pos=1:tcp_md5",
    "--lua-desync=fakeddisorder:pos=1:tcp_md5",
    "--lua-desync=hostfakesplit:tcp_md5",
    "--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20",
    "--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20 --lua-desync=multisplit:pos=1"
) | ForEach-Object { "--payload=tls_client_hello $_" }

# Engelli alan adlari ISS DNS'inde cozulmeyebilir; IP'yi SNI gondermeyen DoH ile bul
function Resolve-Doh($dom) {
    foreach ($url in @("https://1.1.1.1/dns-query?name=$dom&type=A", "https://8.8.8.8/resolve?name=$dom&type=A")) {
        try {
            $r = Invoke-RestMethod -Uri $url -Headers @{ accept = "application/dns-json" } -TimeoutSec 5
            $ip = @($r.Answer | Where-Object { $_.type -eq 1 } | ForEach-Object { $_.data })[0]
            if ($ip) { return $ip }
        } catch { }
    }
    return $null
}

$ips = @{}
foreach ($d in $doms) {
    $ip = Resolve-Doh $d
    if (-not $ip) {
        Write-Host "$d cozulemedi (DoH). Once DNS_Ayarla.cmd calistirin." -ForegroundColor Red
        @("* SUMMARY", "curl_test_https_tls12 ipv4 $d : test aborted, no reason to continue. curl code 6: could not resolve host") | Set-Content $Log -Encoding ASCII
        exit 1
    }
    $ips[$d] = $ip
    Write-Host "$d -> $ip"
}

function Test-Site($d) {
    $code = & $curl -s -o NUL -w "%{http_code}" --max-time 4 --resolve "$($d):443:$($ips[$d])" "https://$d/"
    return ($code -and $code -ne "000")
}
function Test-All { foreach ($d in $doms) { if (-not (Test-Site $d)) { return $false } }; return $true }

$doms | Set-Content $hostlist -Encoding ASCII
netsh interface tcp set global timestamps=enabled | Out-Null

$summary = @("* SUMMARY")
Write-Host "`nBypass olmadan deneniyor..."
if (Test-All) {
    Write-Host "Engel yok, siteler bypass olmadan aciliyor." -ForegroundColor Green
    foreach ($d in $doms) { $summary += "curl_test_https_tls12 ipv4 $d : working without bypass" }
    $summary | Set-Content $Log -Encoding ASCII
    exit 0
}

$found = $null
$n = 0
foreach ($s in $strategies) {
    $n++
    Write-Host ("[{0}/{1}] {2} ... " -f $n, $strategies.Count, $s) -NoNewline
    $wsArgs = "--wf-l3=ipv4 --wf-tcp-out=443 --lua-init=@`"$root\lua\zapret-lib.lua`" --lua-init=@`"$root\lua\zapret-antidpi.lua`" " +
              "--filter-tcp=443 --filter-l7=tls --hostlist=`"$hostlist`" --out-range=-d10 $s"
    $p = Start-Process -FilePath $winws -ArgumentList $wsArgs -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 1500
    if ($p.HasExited) {
        Write-Host "winws2 baslamadi" -ForegroundColor DarkYellow
        continue
    }
    # sans eseri gecmesin diye 3 kez ust uste calismali
    $ok = (Test-All) -and (Test-All) -and (Test-All)
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    $p.WaitForExit(3000) | Out-Null
    if ($ok) {
        Write-Host "CALISIYOR" -ForegroundColor Green
        $found = $s
        break
    }
    Write-Host "olmadi" -ForegroundColor DarkGray
}

Remove-Item $hostlist -Force -ErrorAction SilentlyContinue

if ($found) {
    foreach ($d in $doms) { $summary += "curl_test_https_tls12 ipv4 $d : winws2 --wf-l3=ipv4 --wf-tcp-out=443 $found" }
} else {
    foreach ($d in $doms) { $summary += "curl_test_https_tls12 ipv4 $d : winws2 not working" }
}
$summary | Set-Content $Log -Encoding ASCII
exit 0
