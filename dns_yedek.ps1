# DNS_Ayarla scriptleri DNS'i degistirmeden once mevcut ayarlari yedekler.
# Yedek zaten varsa dokunmaz; boylece DNS_Sifirla.cmd ilk (orijinal) ayarlara doner.
# NameServer bos ise DNS otomatik (DHCP) demektir.

$backup = Join-Path $PSScriptRoot "dns_yedek.json"
if (Test-Path $backup) { return }

$list = @(foreach ($a in Get-NetAdapter) {
    $guid = $a.InterfaceGuid
    $v4 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name NameServer -ErrorAction SilentlyContinue).NameServer
    $v6 = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$guid" -Name NameServer -ErrorAction SilentlyContinue).NameServer
    [pscustomobject]@{ Name = $a.Name; Guid = $guid; V4 = "$v4"; V6 = "$v6" }
})

ConvertTo-Json -InputObject $list | Set-Content -Path $backup -Encoding ASCII
Write-Host "Mevcut DNS ayarlari yedeklendi: dns_yedek.json" -ForegroundColor DarkGray
