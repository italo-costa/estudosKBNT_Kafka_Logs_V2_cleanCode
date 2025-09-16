# Script para Configurar Port Forwarding Windows -> WSL2 para Postman

Write-Host "=== CONFIGURANDO ACESSO POSTMAN WINDOWS ===" -ForegroundColor Green

# 1. Obter IP do WSL2
Write-Host "1. Detectando IP do WSL2..." -ForegroundColor Yellow
$wslIP = wsl -e bash -c "ip addr show eth0 | grep 'inet ' | awk '{print `$2}' | cut -d'/' -f1"
Write-Host "IP WSL2: $wslIP" -ForegroundColor Cyan

# 2. Verificar se aplicação está funcionando no WSL2
Write-Host "2. Verificando aplicação no WSL2..." -ForegroundColor Yellow
$healthCheck = wsl -e bash -c "timeout 5 curl -s http://localhost:8084/actuator/health 2>/dev/null"
if ($healthCheck -match "UP") {
    Write-Host "✅ Aplicação funcionando no WSL2" -ForegroundColor Green
} else {
    Write-Host "❌ Aplicação não está respondendo no WSL2" -ForegroundColor Red
    Write-Host "Tentando reiniciar aplicação..." -ForegroundColor Yellow
    wsl -e bash -c "docker restart virtual-stock-stable"
    Start-Sleep -Seconds 20
}

# 3. Limpar port forwarding anterior
Write-Host "3. Limpando configurações anteriores..." -ForegroundColor Yellow
try {
    netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0 2>$null
    netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=127.0.0.1 2>$null
    Write-Host "Port forwarding anterior removido" -ForegroundColor Gray
} catch {
    Write-Host "Nenhum port forwarding anterior encontrado" -ForegroundColor Gray
}

# 4. Configurar port forwarding Windows -> WSL2
Write-Host "4. Configurando port forwarding..." -ForegroundColor Yellow
try {
    # Port forwarding para localhost do Windows
    netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP
    Write-Host "✅ Port forwarding configurado: Windows:8084 -> WSL2($wslIP):8084" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao configurar port forwarding (Execute como Administrador)" -ForegroundColor Red
    Write-Host "Tentando configuração alternativa..." -ForegroundColor Yellow
}

# 5. Configurar firewall do Windows
Write-Host "5. Configurando firewall..." -ForegroundColor Yellow
try {
    netsh advfirewall firewall delete rule name="WSL2 Virtual Stock Service" 2>$null
    netsh advfirewall firewall add rule name="WSL2 Virtual Stock Service" dir=in action=allow protocol=TCP localport=8084
    Write-Host "✅ Regra de firewall adicionada" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Não foi possível configurar firewall (pode precisar de permissões de Admin)" -ForegroundColor Yellow
}

# 6. Mostrar configurações
Write-Host "6. Verificando configurações..." -ForegroundColor Yellow
try {
    $portForwardRules = netsh interface portproxy show v4tov4
    if ($portForwardRules -match "8084") {
        Write-Host "✅ Port forwarding ativo:" -ForegroundColor Green
        netsh interface portproxy show v4tov4 | Select-String "8084"
    } else {
        Write-Host "⚠️ Port forwarding não detectado" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Não foi possível verificar port forwarding" -ForegroundColor Gray
}

# 7. Testar conectividade do Windows
Write-Host "7. Testando conectividade do Windows..." -ForegroundColor Yellow

$testUrls = @(
    "http://localhost:8084/actuator/health",
    "http://127.0.0.1:8084/actuator/health"
)

foreach ($url in $testUrls) {
    Write-Host "Testando: $url" -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ FUNCIONANDO!" -ForegroundColor Green
        } else {
            Write-Host "❌ Status: $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Falhou: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== CONFIGURAÇÃO PARA POSTMAN ===" -ForegroundColor Green
Write-Host "Use ESTES endpoints no Postman (Windows):" -ForegroundColor Yellow
Write-Host "✅ Health: http://localhost:8084/actuator/health" -ForegroundColor Cyan
Write-Host "✅ API: http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
Write-Host "✅ Ping: http://localhost:8084/ping" -ForegroundColor Cyan
Write-Host "✅ Home: http://localhost:8084/" -ForegroundColor Cyan

Write-Host "`n📋 IMPORTANTE:" -ForegroundColor Yellow
Write-Host "- Use http://localhost:8084 (NÃO use o IP 172.30.221.62)" -ForegroundColor White
Write-Host "- Se não funcionar, execute este script como Administrador" -ForegroundColor White
Write-Host "- Pode ser necessário reiniciar o Postman após a configuração" -ForegroundColor White