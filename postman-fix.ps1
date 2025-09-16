# Port Forwarding para Postman Windows

Write-Host "=== CONFIGURANDO POSTMAN WINDOWS ===" -ForegroundColor Green

# Obter IP WSL2
$wslIP = wsl -e bash -c "hostname -I | awk '{print `$1}'"
Write-Host "IP WSL2: $wslIP" -ForegroundColor Cyan

# Limpar port forwarding
netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0 2>$null

# Configurar port forwarding
Write-Host "Configurando port forwarding..." -ForegroundColor Yellow
netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP

# Configurar firewall
Write-Host "Configurando firewall..." -ForegroundColor Yellow
netsh advfirewall firewall delete rule name="WSL2 Port 8084" 2>$null
netsh advfirewall firewall add rule name="WSL2 Port 8084" dir=in action=allow protocol=TCP localport=8084

# Verificar
Write-Host "Verificando configuracao..." -ForegroundColor Yellow
netsh interface portproxy show v4tov4

Write-Host "`nUSE NO POSTMAN:" -ForegroundColor Green
Write-Host "http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan