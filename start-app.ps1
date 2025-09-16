# Script de Inicialização Rápida - Virtual Stock Service
# Execute este script para garantir que toda a aplicação esteja funcionando

Write-Host "=== Inicialização Virtual Stock Service ===" -ForegroundColor Green

# Verificar se WSL2 está funcionando
Write-Host "Verificando WSL2..." -ForegroundColor Yellow
try {
    $wslCheck = wsl -e bash -c "echo 'WSL2 OK'"
    if ($wslCheck -eq "WSL2 OK") {
        Write-Host "✅ WSL2 está funcionando" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ WSL2 não está funcionando corretamente" -ForegroundColor Red
    exit 1
}

# Verificar Docker
Write-Host "Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerCheck = wsl -e bash -c "docker --version"
    Write-Host "✅ Docker está funcionando: $dockerCheck" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker não está funcionando" -ForegroundColor Red
    exit 1
}

# Verificar se os containers existem
Write-Host "Verificando containers..." -ForegroundColor Yellow
$containers = @("postgres-kbnt-stable", "virtual-stock-stable")

foreach ($container in $containers) {
    $exists = wsl -e bash -c "docker ps -a --format '{{.Names}}' | grep -x '$container'"
    if ($exists -eq $container) {
        Write-Host "✅ Container $container existe" -ForegroundColor Green
        
        # Verificar se está rodando
        $status = wsl -e bash -c "docker inspect --format='{{.State.Status}}' '$container'"
        if ($status -eq "running") {
            Write-Host "✅ Container $container está rodando" -ForegroundColor Green
        } else {
            Write-Host "🔄 Iniciando container $container..." -ForegroundColor Cyan
            wsl -e bash -c "docker start '$container'"
        }
    } else {
        Write-Host "❌ Container $container não existe" -ForegroundColor Red
        Write-Host "Execute o script de deploy primeiro!" -ForegroundColor Yellow
        exit 1
    }
}

# Aguardar inicialização
Write-Host "Aguardando aplicação inicializar..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Testar endpoints
Write-Host "Testando endpoints..." -ForegroundColor Yellow

$endpoints = @(
    @{Name="Health Check"; URL="http://localhost:8084/actuator/health"},
    @{Name="Página Inicial"; URL="http://localhost:8084/"},
    @{Name="Ping"; URL="http://localhost:8084/ping"},
    @{Name="API Health"; URL="http://localhost:8084/api/v1/health"},
    @{Name="Stocks API"; URL="http://localhost:8084/api/v1/virtual-stock/stocks"}
)

$allOk = $true
foreach ($endpoint in $endpoints) {
    try {
        $response = wsl -e bash -c "curl -s -o /dev/null -w '%{http_code}' '$($endpoint.URL)'"
        if ($response -eq "200") {
            Write-Host "✅ $($endpoint.Name): OK" -ForegroundColor Green
        } else {
            Write-Host "❌ $($endpoint.Name): HTTP $response" -ForegroundColor Red
            $allOk = $false
        }
    } catch {
        Write-Host "❌ $($endpoint.Name): Erro" -ForegroundColor Red
        $allOk = $false
    }
}

if ($allOk) {
    Write-Host "`n🎉 APLICAÇÃO VIRTUAL STOCK SERVICE FUNCIONANDO!" -ForegroundColor Green
    Write-Host "🌐 Acesse: http://localhost:8084" -ForegroundColor Cyan
    Write-Host "📊 Health Check: http://localhost:8084/actuator/health" -ForegroundColor Cyan
    Write-Host "📈 API Stocks: http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
    
    Write-Host "`n📝 Para usar no Postman:" -ForegroundColor Yellow
    Write-Host "1. Execute setup-port-forwarding.ps1 como Administrador" -ForegroundColor Gray
    Write-Host "2. Teste os endpoints acima" -ForegroundColor Gray
    
    Write-Host "`n🔄 Para monitoramento contínuo:" -ForegroundColor Yellow
    Write-Host "Execute: powershell -ExecutionPolicy Bypass -File monitor-app.ps1" -ForegroundColor Gray
} else {
    Write-Host "`n❌ Alguns endpoints não estão respondendo" -ForegroundColor Red
    Write-Host "Verifique os logs: wsl -e bash -c 'docker logs virtual-stock-stable'" -ForegroundColor Yellow
}
