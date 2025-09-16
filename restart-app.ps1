# Script de Restart da Aplicação Virtual Stock Service
# Use este script se precisar reiniciar a aplicação

Write-Host "=== Reiniciando Virtual Stock Service ===" -ForegroundColor Green

$containers = @("postgres-kbnt-stable", "virtual-stock-stable")

# Parar containers
Write-Host "Parando containers..." -ForegroundColor Yellow
foreach ($container in $containers) {
    Write-Host "Parando $container..." -ForegroundColor Cyan
    wsl -e bash -c "docker stop '$container'"
}

# Aguardar um pouco
Start-Sleep -Seconds 5

# Iniciar containers
Write-Host "Iniciando containers..." -ForegroundColor Yellow
foreach ($container in $containers) {
    Write-Host "Iniciando $container..." -ForegroundColor Cyan
    wsl -e bash -c "docker start '$container'"
}

# Aguardar inicialização
Write-Host "Aguardando aplicação inicializar..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# Testar saúde da aplicação
Write-Host "Testando aplicação..." -ForegroundColor Yellow
try {
    $response = wsl -e bash -c "curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8084/actuator/health'"
    if ($response -eq "200") {
        Write-Host "✅ Aplicação reiniciada com sucesso!" -ForegroundColor Green
        Write-Host "🌐 Acesse: http://localhost:8084" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Aplicação não está respondendo (HTTP $response)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erro ao testar aplicação" -ForegroundColor Red
}
