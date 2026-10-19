$ErrorActionPreference = "Continue"

# dns_yedek.json varsa DNS_Ayarla oncesindeki ayarlara doner,
# yoksa DNS'i otomatik (DHCP / modemin verdigi) yapar.
$backup = Join-Path $PSScriptRoot "dns_yedek.json"
$saved = $null
if (Test-Path $backup) {
    $saved = @(Get-Content $backup -Raw | ConvertFrom-Json)
    Write-Host "Yedek bulundu, eski DNS ayarlarina donuluyor." -ForegroundColor Cyan
    $adapters = Get-NetAdapter | Where-Object { $saved.Guid -contains $_.InterfaceGuid }
} else {
    Write-Host "Yedek yok, DNS otomatik (DHCP) yapiliyor." -ForegroundColor Cyan
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Hyper-V|Virtual|Loopback|Geri D' }
    if (-not $adapters) {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    }
}

foreach ($adapter in $adapters) {
    Write-Host "Yapilandiriliyor: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
    $servers = @()
    if ($saved) {
        $s = $saved | Where-Object { $_.Guid -eq $adapter.InterfaceGuid } | Select-Object -First 1
        $servers = @("$($s.V4) $($s.V6)" -split '[,\s]+' | Where-Object { $_ })
    }
    try {
        if ($servers.Count -gt 0) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $servers
            Write-Host "  -> DNS geri yuklendi: $($servers -join ', ')" -ForegroundColor Green
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
            Write-Host "  -> DNS otomatik (DHCP) yapildi." -ForegroundColor Green
        }
    } catch {
        Write-Host "  -> Hata: $_" -ForegroundColor Red
    }
}

if ($saved) {
    # bir sonraki DNS_Ayarla yeni yedek alsin
    Remove-Item $backup -Force -ErrorAction SilentlyContinue
}

Clear-DnsClientCache
ipconfig /flushdns | Out-Null
Write-Host "`nDNS onbellegi temizlendi." -ForegroundColor Green
