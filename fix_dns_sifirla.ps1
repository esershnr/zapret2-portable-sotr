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

    # DNS_Ayarla'nin actigi sifreli DNS (DoH) ayarini kaldir
    $iface = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\$($adapter.InterfaceGuid)"
    $removed = $false
    foreach ($sub in @("DohInterfaceSettings", "DohProfileSettings")) {
        foreach ($fam in @("Doh", "Doh6")) {
            foreach ($k in @(Get-ChildItem "$iface\$sub\$fam" -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $k.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                $removed = $true
            }
        }
    }
    if ($removed) { Write-Host "  -> Sifreli DNS ayari kaldirildi." -ForegroundColor Green }
}

Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name DoHPolicy -ErrorAction SilentlyContinue

if (Get-Command Set-DnsClientDohServerAddress -ErrorAction SilentlyContinue) {
    foreach ($ip in @("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001", "8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844")) {
        Set-DnsClientDohServerAddress -ServerAddress $ip -AutoUpgrade $false -ErrorAction SilentlyContinue | Out-Null
    }
}

if ($saved) {
    # bir sonraki DNS_Ayarla yeni yedek alsin
    Remove-Item $backup -Force -ErrorAction SilentlyContinue
}

Clear-DnsClientCache
ipconfig /flushdns | Out-Null
Write-Host "`nDNS onbellegi temizlendi." -ForegroundColor Green
