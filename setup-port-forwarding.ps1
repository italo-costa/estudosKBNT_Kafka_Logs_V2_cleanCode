# Configuração de Port Forwarding para aplicação Virtual Stock
# Execute este script como Administrador

Write-Host "Configurando port forwarding para Virtual Stock Service..." -ForegroundColor Green

# Obter o IP do WSL2
$wslIP = (wsl hostname -I).Trim()
Write-Host "IP do WSL2 encontrado: $wslIP" -ForegroundColor Yellow

# Configurar port forwarding
$port = 8084
try {
    # Remover configuração existente se houver
    netsh interface portproxy delete v4tov4 listenport=$port listenaddress=0.0.0.0 2>$null
    
    # Adicionar nova configuração
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIP
    
    Write-Host "Port forwarding configurado com sucesso!" -ForegroundColor Green
    Write-Host "Porta $port -> $wslIP`:$port" -ForegroundColor Yellow
    
    # Configurar firewall
    Write-Host "Configurando regras do firewall..." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "WSL2 Virtual Stock Service" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    
    Write-Host "Configuração concluída!" -ForegroundColor Green
    Write-Host "Agora você pode acessar a aplicação via: http://localhost:$port" -ForegroundColor Green
    
    # Verificar configuração
    Write-Host "`nConfiguração atual do port proxy:" -ForegroundColor Cyan
    netsh interface portproxy show all
    
} catch {
    Write-Host "Erro ao configurar port forwarding: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
