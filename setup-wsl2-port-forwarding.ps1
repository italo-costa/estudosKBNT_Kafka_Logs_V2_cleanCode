# Script para configurar port forwarding WSL2 - Virtual Stock Service
# Execute como Administrador

# Obter IP do WSL2
$wslIP = (wsl hostname -I).Trim()
Write-Host "WSL2 IP detected: $wslIP"

# Remover regras existentes (se houver)
netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0

# Configurar port forwarding para a porta 8084
netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP

# Configurar regra do Windows Firewall
New-NetFireWallRule -DisplayName 'WSL2 Virtual Stock Service Port 8084' -Direction Inbound -LocalPort 8084 -Action Allow -Protocol TCP

# Mostrar configuração
Write-Host "Port forwarding configured:"
netsh interface portproxy show all

Write-Host "Testing connection..."
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/" -Method Get -TimeoutSec 10
    Write-Host "SUCCESS: $response"
} catch {
    Write-Host "ERROR: $_"
}
