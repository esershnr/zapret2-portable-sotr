# DNS_Ayarla scriptleri DNS'i degistirmeden once mevcut ayarlari yedekler.
# Yedek zaten varsa dokunmaz; boylece DNS_Sifirla.cmd ilk (orijinal) ayarlara doner.
# NameServer bos ise DNS otomatik (DHCP) demektir.

$backup = Join-Path $PSScriptRoot "dns_yedek.json"
if (Test-Path $backup) { return }

# Bu scriptlerin kendi ayarladigi adresler orijinal ayar sayilmaz (eski surumler yedek almadan
# degistirmis olabilir); bunlar varsa yedege otomatik (DHCP) yazilir.
$ours = @("1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001", "8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844")
function Get-Original($val) {
    $ips = @("$val" -split '[,\s]+' | Where-Object { $_ })
    if (@($ips | Where-Object { $ours -contains $_ }).Count -gt 0) { return "" }
    return ($ips -join ",")
}

$list = @(foreach ($a in Get-NetAdapter) {
    $guid = $a.InterfaceGuid
    $v4 = Get-Original (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" -Name NameServer -ErrorAction SilentlyContinue).NameServer
    $v6 = Get-Original (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$guid" -Name NameServer -ErrorAction SilentlyContinue).NameServer
    [pscustomobject]@{ Name = $a.Name; Guid = $guid; V4 = "$v4"; V6 = "$v6" }
})

ConvertTo-Json -InputObject $list | Set-Content -Path $backup -Encoding ASCII
Write-Host "Mevcut DNS ayarlari yedeklendi: dns_yedek.json" -ForegroundColor DarkGray
