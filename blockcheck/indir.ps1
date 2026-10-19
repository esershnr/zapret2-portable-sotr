param([Parameter(Mandatory = $true)][string]$Dest)

# zapret-win-bundle (cygwin + blockcheck2 + winws2) indirir ve $Dest altina acar.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$url = "https://github.com/bol-van/zapret-win-bundle/archive/refs/heads/master.zip"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$zip = Join-Path $Dest "bundle.zip"

try {
    Write-Host "Indiriliyor: $url" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

    Write-Host "Arsiv aciliyor..." -ForegroundColor Cyan
    $tar = Join-Path $env:SystemRoot "System32\tar.exe"
    $ok = $false
    if (Test-Path $tar) {
        & $tar -xf $zip -C $Dest
        $ok = ($LASTEXITCODE -eq 0)
    }
    if (-not $ok) {
        Expand-Archive -Path $zip -DestinationPath $Dest -Force
    }
    Write-Host "Tamamlandi." -ForegroundColor Green
} catch {
    Write-Host "Hata: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
}
