# Script PowerShell para configurar Port Forwarding WSL2 -> Windows
# Este script resolve o problema ECONNREFUSED no Postman

Write-Host "🔧 Configurando Port Forwarding WSL2 -> Windows para KBNT Virtual Stock Service" -ForegroundColor Green

# Obter IP do WSL2
$wslIP = wsl hostname -I
$wslIP = $wslIP.Split()[0].Trim()

Write-Host "📍 IP do WSL2 detectado: $wslIP" -ForegroundColor Yellow

# Verificar se já existe port proxy para 8084
$existingProxy = netsh interface portproxy show all | Select-String "8084"

if ($existingProxy) {
    Write-Host "🗑️ Removendo configuração existente..." -ForegroundColor Yellow
    netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0
}

# Configurar port forwarding
Write-Host "⚡ Configurando port forwarding 8084..." -ForegroundColor Cyan
try {
    netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP
    Write-Host "✅ Port forwarding configurado com sucesso!" -ForegroundColor Green
    
    # Verificar configuração
    Write-Host "📋 Configurações atuais de port proxy:" -ForegroundColor Cyan
    netsh interface portproxy show all
    
    # Configurar firewall se necessário
    Write-Host "🔥 Configurando regra de firewall..." -ForegroundColor Cyan
    New-NetFireWallRule -DisplayName "WSL2 KBNT Port 8084" -Direction Inbound -LocalPort 8084 -Action Allow -Protocol TCP -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "🎉 CONFIGURAÇÃO CONCLUÍDA!" -ForegroundColor Green
    Write-Host "📝 Agora você pode usar no Postman:" -ForegroundColor White
    Write-Host "   URL: http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
    Write-Host ""
    
    # Testar conectividade
    Write-Host "🧪 Testando conectividade..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8084/api/v1/virtual-stock/stocks" -Method GET -TimeoutSec 10
        Write-Host "✅ TESTE PASSOU! Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "📄 Resposta: $($response.Content)" -ForegroundColor White
    }
    catch {
        Write-Host "⚠️ Aguarde alguns segundos para o serviço carregar completamente e teste novamente..." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ ERRO: Este script precisa ser executado como ADMINISTRADOR" -ForegroundColor Red
    Write-Host "💡 Solução alternativa: Use o IP direto do WSL2 no Postman:" -ForegroundColor Yellow
    Write-Host "   http://$wslIP:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📚 Documentação completa em: POSTMAN_API_TESTING_GUIDE.md" -ForegroundColor Magenta
