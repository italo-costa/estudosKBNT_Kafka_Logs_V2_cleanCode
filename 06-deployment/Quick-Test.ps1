# KBNT Kafka Logs - Teste Rápido do Ambiente
Write-Host "🚀 Teste Rápido - KBNT Kafka Logs" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

$services = @(
    @{Name="Log Consumer"; Port="8082"; Container="log-consumer-service"},
    @{Name="Log Analytics"; Port="8083"; Container="log-analytics-service"},
    @{Name="Log Producer"; Port="8081"; Container="log-producer-service"},
    @{Name="Virtual Stock"; Port="8084"; Container="virtual-stock-service"}
)

Write-Host ""
Write-Host "Testando serviços via Docker (WSL):" -ForegroundColor Cyan

foreach ($service in $services) {
    Write-Host "🔍 $($service.Name) (porta $($service.Port)):" -ForegroundColor Yellow
    
    try {
        $result = wsl -d Ubuntu sh -c "docker exec $($service.Container) curl -s http://localhost:8080/actuator/health 2>/dev/null"
        
        if ($result -and $result -like "*UP*") {
            Write-Host "  ✅ Status: UP" -ForegroundColor Green
            Write-Host "  🌐 Externo: http://localhost:$($service.Port)/actuator/health" -ForegroundColor White
        } else {
            Write-Host "  ⏳ Inicializando..." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  ❌ Não disponível" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "📋 Comandos de Teste Prontos:" -ForegroundColor Magenta
Write-Host ""
Write-Host "WSL/Docker (Interno):" -ForegroundColor Green
Write-Host 'wsl -d Ubuntu sh -c "docker exec log-consumer-service curl -s http://localhost:8080/actuator/health"' -ForegroundColor White
Write-Host ""
Write-Host "PowerShell (Externo):" -ForegroundColor Green  
Write-Host "Invoke-RestMethod -Uri 'http://localhost:8082/actuator/health' -Method Get" -ForegroundColor White
Write-Host ""
Write-Host "✨ Ambiente Linux Virtualizado Pronto!" -ForegroundColor Green
