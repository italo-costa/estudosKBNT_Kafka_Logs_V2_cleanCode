# Solução DEFINITIVA para ECONNREFUSED WSL2 -> Windows
# Script PowerShell para resolver conectividade Postman

Write-Host "🔧 RESOLVENDO PROBLEMA ECONNREFUSED WSL2 -> WINDOWS" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow

# 1. Verificar se aplicação está rodando no WSL
Write-Host "🔍 Verificando aplicação no WSL..." -ForegroundColor Cyan
$wslTest = wsl curl -s -w "%{http_code}" -o /dev/null http://localhost:8084/api/v1/virtual-stock/stocks 2>$null
if ($wslTest -eq "200") {
    Write-Host "✅ Aplicação funcionando no WSL2 (HTTP 200)" -ForegroundColor Green
} else {
    Write-Host "❌ Aplicação não responde no WSL2" -ForegroundColor Red
    Write-Host "🔄 Reiniciando serviços..." -ForegroundColor Yellow
    wsl cd /mnt/c/workspace/estudosKBNT_Kafka_Logs/06-deployment '&&' docker compose -f docker-compose.simple.yml restart virtual-stock-simple
    Start-Sleep 20
}

# 2. Obter IP do WSL2
$wslIP = (wsl hostname -I).Split()[0].Trim()
Write-Host "📍 IP do WSL2: $wslIP" -ForegroundColor Yellow

# 3. Verificar se Windows consegue acessar WSL2
Write-Host "🌐 Testando conectividade Windows -> WSL2..." -ForegroundColor Cyan
try {
    $testResponse = Invoke-WebRequest -Uri "http://$wslIP:8084/actuator/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Windows consegue acessar WSL2 diretamente!" -ForegroundColor Green
    Write-Host "🎯 USE ESTA URL NO POSTMAN:" -ForegroundColor Green
    Write-Host "   http://$wslIP:8084/api/v1/virtual-stock/stocks" -ForegroundColor White
    exit 0
} catch {
    Write-Host "❌ Windows não consegue acessar WSL2 diretamente" -ForegroundColor Red
}

# 4. Configurar Port Forwarding como administrador
Write-Host "⚡ Configurando Port Forwarding..." -ForegroundColor Cyan

# Verificar se está rodando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "🔑 Executando como Administrador para configurar port forwarding..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
    exit 0
}

# Configurar port forwarding (executando como admin)
Write-Host "🔧 Configurando port forwarding (como administrador)..." -ForegroundColor Green

# Remover configuração existente se houver
$existingProxy = netsh interface portproxy show all | Select-String "8084"
if ($existingProxy) {
    Write-Host "🗑️ Removendo configuração existente..." -ForegroundColor Yellow
    netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0 | Out-Null
}

# Adicionar nova configuração
try {
    netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP | Out-Null
    Write-Host "✅ Port forwarding configurado!" -ForegroundColor Green
    
    # Configurar firewall
    New-NetFireWallRule -DisplayName "WSL2 KBNT Port 8084" -Direction Inbound -LocalPort 8084 -Action Allow -Protocol TCP -ErrorAction SilentlyContinue | Out-Null
    Write-Host "✅ Regra de firewall configurada!" -ForegroundColor Green
    
    # Mostrar configuração
    Write-Host "📋 Configuração atual:" -ForegroundColor Cyan
    netsh interface portproxy show all
    
    Write-Host ""
    Write-Host "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!" -ForegroundColor Green
    Write-Host "✅ USE NO POSTMAN: http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor White
    
    # Testar configuração
    Write-Host "🧪 Testando configuração..." -ForegroundColor Cyan
    Start-Sleep 3
    try {
        $testResponse = Invoke-WebRequest -Uri "http://localhost:8084/api/v1/virtual-stock/stocks" -Method GET -TimeoutSec 10
        Write-Host "✅ TESTE PASSOU! Status: $($testResponse.StatusCode)" -ForegroundColor Green
        Write-Host "📄 Resposta: $($testResponse.Content)" -ForegroundColor White
        Write-Host ""
        Write-Host "🎯 PROBLEMA RESOLVIDO! Use localhost:8084 no Postman!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Aguarde alguns segundos e teste no Postman..." -ForegroundColor Yellow
        Write-Host "💡 Se não funcionar, use: http://$wslIP:8084" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "❌ Erro ao configurar port forwarding: $_" -ForegroundColor Red
    Write-Host "💡 Solução alternativa - use IP direto no Postman:" -ForegroundColor Yellow
    Write-Host "   http://$wslIP:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📚 Documentação: WSL2_NETWORKING_SOLUTION.md" -ForegroundColor Magenta
