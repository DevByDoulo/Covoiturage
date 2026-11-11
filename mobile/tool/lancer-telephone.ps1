# Lance l'appli sur le téléphone branché en USB, en pointant sur l'API de ce PC via le Wi-Fi.
# L'adresse IP est détectée à chaque lancement (rien de personnel dans le dépôt).
# Usage (depuis mobile/) : .\tool\lancer-telephone.ps1 [-Ip 192.168.x.y] [-Appareil <id flutter>]
param([string]$Ip, [string]$Appareil)

if (-not $Ip) {
    $cartes = Get-NetIPConfiguration | Where-Object {
        $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway -and
        $_.NetAdapter.InterfaceDescription -notmatch 'Virtual|VPN|vEthernet|Hyper-V'
    }
    # Le Wi-Fi d'abord : c'est par lui que le téléphone joint le PC.
    $carte = ($cartes | Where-Object { $_.InterfaceAlias -match 'Wi-?Fi|WLAN|Sans fil' } | Select-Object -First 1)
    if (-not $carte) { $carte = $cartes | Select-Object -First 1 }
    $Ip = $carte.IPv4Address.IPAddress | Select-Object -First 1
}
if (-not $Ip) { throw "Adresse IP du PC introuvable : passez-la avec -Ip." }
Write-Host "API : http://${Ip}:8080/api  (site : http://${Ip}:4200)"

$arguments = @('run', "--dart-define=API_URL=http://${Ip}:8080/api", "--dart-define=SITE_URL=http://${Ip}:4200")
if ($Appareil) { $arguments += @('-d', $Appareil) }
& flutter @arguments
