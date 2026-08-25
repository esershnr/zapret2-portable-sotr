$ErrorActionPreference = "Continue"

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Hyper-V|Virtual|Loopback|Geri D' }
if (-not $adapters) {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
}

foreach ($adapter in $adapters) {
    Write-Host "Yapilandiriliyor: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001")
        Write-Host "  -> DNS basariyla ayarlandi (1.1.1.1 / 1.0.0.1 / Cloudflare IPv6)." -ForegroundColor Green
    } catch {
        Write-Host "  -> Hata: $_" -ForegroundColor Red
    }
}

Clear-DnsClientCache
ipconfig /flushdns | Out-Null
Write-Host "`nDNS onbellegi temizlendi." -ForegroundColor Green

Write-Host "`nDNS Testi:" -ForegroundColor Yellow
try {
    $res = Resolve-DnsName updates.discord.com -Type A -ErrorAction Stop
    Write-Host "updates.discord.com cozuldu -> $($res.IPAddress -join ', ')" -ForegroundColor Green
} catch {
    Write-Host "Test sirasinda hata: $_" -ForegroundColor Red
}
