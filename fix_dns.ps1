param([ValidateSet("cloudflare", "google")][string]$Provider = "cloudflare")

$ErrorActionPreference = "Continue"

$providers = @{
    cloudflare = @{ Name = "Cloudflare"; Template = "https://cloudflare-dns.com/dns-query"; Servers = @("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001") }
    google     = @{ Name = "Google";     Template = "https://dns.google/dns-query";         Servers = @("8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844") }
}
$p = $providers[$Provider]

# DNS_Sifirla.cmd ile geri donebilmek icin mevcut ayarlari yedekle
& "$PSScriptRoot\dns_yedek.ps1"

# Bazi ISS'ler 1.1.1.1 / 8.8.8.8'e giden duz DNS (53. port) sorgularini yolda yakalar,
# bu yuzden Windows 11'in DNS over HTTPS (sifreli DNS) ozelligi de acilir.
$dohSupported = [bool](Get-Command Set-DnsClientDohServerAddress -ErrorAction SilentlyContinue)
if ($dohSupported) {
    foreach ($ip in $p.Servers) {
        try {
            if (Get-DnsClientDohServerAddress -ServerAddress $ip -ErrorAction SilentlyContinue) {
                Set-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $p.Template -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop | Out-Null
            } else {
                Add-DnsClientDohServerAddress -ServerAddress $ip -DohTemplate $p.Template -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop | Out-Null
            }
        } catch {
            Write-Host "  -> DoH tanimlanamadi ($ip): $_" -ForegroundColor Red
        }
    }
}

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Hyper-V|Virtual|Loopback|Geri D' }
if (-not $adapters) {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
}

foreach ($adapter in $adapters) {
    Write-Host "Yapilandiriliyor: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $p.Servers
        Write-Host "  -> DNS ayarlandi ($($p.Name): $($p.Servers -join ' / '))." -ForegroundColor Green
    } catch {
        Write-Host "  -> Hata: $_" -ForegroundColor Red
        continue
    }

    if ($dohSupported) {
        # Ayarlar > Ag > DNS sifrelemesi: "Yalnizca sifreli (DNS over HTTPS)" ile ayni kayit
        $base = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($adapter.InterfaceGuid)\DohInterfaceSettings"
        try {
            foreach ($ip in $p.Servers) {
                $key = if ($ip.Contains(":")) { "$base\Doh6\$ip" } else { "$base\Doh\$ip" }
                New-Item -Path $key -Force | Out-Null
                New-ItemProperty -Path $key -Name DohFlags -PropertyType QWord -Value 1 -Force | Out-Null
            }
            Write-Host "  -> Sifreli DNS (DNS over HTTPS) acildi." -ForegroundColor Green
        } catch {
            Write-Host "  -> Sifreli DNS acilamadi: $_" -ForegroundColor Red
        }
    }
}

if (-not $dohSupported) {
    Write-Host "`nBu Windows surumu sifreli DNS (DoH) desteklemiyor, sadece DNS adresi degistirildi." -ForegroundColor Yellow
}

Clear-DnsClientCache
ipconfig /flushdns | Out-Null
Write-Host "`nDNS onbellegi temizlendi." -ForegroundColor Green

Write-Host "`nDNS Testi:" -ForegroundColor Yellow
$ok = $false
for ($try = 1; $try -le 3 -and -not $ok; $try++) {
    try {
        $res = Resolve-DnsName discord.com -Type A -DnsOnly -ErrorAction Stop | Where-Object { $_.IPAddress }
        Write-Host "discord.com cozuldu -> $($res.IPAddress -join ', ')" -ForegroundColor Green
        $ok = $true
    } catch {
        if ($try -lt 3) { Start-Sleep -Seconds 3; Clear-DnsClientCache }
        else { Write-Host "discord.com cozulemedi: $_" -ForegroundColor Red }
    }
}
if (-not $ok) {
    Write-Host "Bilgisayari yeniden baslatip tekrar deneyin. Duzelmezse diger DNS_Ayarla dosyasini deneyin" -ForegroundColor Yellow
    Write-Host "veya internetiniz bozulduysa DNS_Sifirla.cmd ile eski ayarlara donun." -ForegroundColor Yellow
}
