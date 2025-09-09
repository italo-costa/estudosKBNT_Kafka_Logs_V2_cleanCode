# KBNT Kafka Logs - Script de Teste PowerShell Simplificado
Write-Host "🚀 KBNT Kafka Logs - Ambiente Linux Virtualizado (Docker)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "📊 Status dos Containers Docker:" -ForegroundColor Cyan
wsl -d Ubuntu docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "(log-|virtual-stock|kbnt-)"

Write-Host ""
Write-Host "🏥 Testando Health Checks via Docker:" -ForegroundColor Cyan
Write-Host ""

$containers = @("log-consumer-service", "log-analytics-service", "log-producer-service", "virtual-stock-service")

foreach ($container in $containers) {
    Write-Host "🔍 Testando $container..." -ForegroundColor Yellow
    $result = wsl -d Ubuntu sh -c "docker exec $container curl -s http://localhost:8080/actuator/health 2>/dev/null || echo 'FAILED'"
    
    if ($result -eq "FAILED" -or $result -eq "") {
        Write-Host "  ❌ Serviço não respondeu" -ForegroundColor Red
    } else {
        Write-Host "  ✅ Health: $result" -ForegroundColor Green
    }
    Write-Host ""
}

Write-Host "📋 Comandos de Teste Disponíveis:" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "🐧 Teste Health Check (WSL/Docker):" -ForegroundColor Green
Write-Host 'wsl -d Ubuntu sh -c "docker exec log-consumer-service curl -s http://localhost:8080/actuator/health"' -ForegroundColor White
Write-Host ""

Write-Host "📤 Teste de Produção de Log:" -ForegroundColor Green
Write-Host 'wsl -d Ubuntu sh -c "docker exec log-producer-service curl -X POST http://localhost:8080/api/logs -H \"Content-Type: application/json\" -d \"{\\\"message\\\":\\\"Test from PowerShell\\\",\\\"level\\\":\\\"INFO\\\"}\""' -ForegroundColor White
Write-Host ""

Write-Host "📊 Teste de Stock Service:" -ForegroundColor Green
Write-Host 'wsl -d Ubuntu sh -c "docker exec virtual-stock-service curl -s http://localhost:8080/api/stocks"' -ForegroundColor White
Write-Host ""

Write-Host "🌐 Teste de Conectividade Externa:" -ForegroundColor Green
Write-Host 'Invoke-RestMethod -Uri "http://localhost:8082/actuator/health" -Method Get' -ForegroundColor White
Write-Host ""

Write-Host "✨ Ambiente Pronto para Testes!" -ForegroundColor Green
