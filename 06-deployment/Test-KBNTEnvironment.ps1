# KBNT Kafka Logs - Script de Teste PowerShell
# =============================================

Write-Host "🚀 KBNT Kafka Logs - Ambiente Linux Virtualizado (Docker)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

# Função para testar endpoint
function Test-Endpoint {
    param(
        [string]$ServiceName,
        [string]$Url,
        [string]$Port
    )
    
    Write-Host "🔍 Testando $ServiceName (porta $Port):" -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 5
        Write-Host "  ✅ Status: $($response.status)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ❌ Falha: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Função para testar via WSL/Docker
function Test-DockerEndpoint {
    param(
        [string]$ServiceName,
        [string]$ContainerName
    )
    
    Write-Host "🔍 Testando $ServiceName via Docker:" -ForegroundColor Yellow
    
    try {
        $result = wsl -d Ubuntu sh -c "docker exec $ContainerName curl -s -f http://localhost:8080/actuator/health 2>/dev/null"
        if ($result) {
            Write-Host "  ✅ Health Check: $result" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ Serviço não respondeu" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  ❌ Erro ao conectar: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "📊 Status dos Containers Docker:" -ForegroundColor Cyan
wsl -d Ubuntu docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" | Select-String -Pattern "(log-|virtual-stock|kbnt-)"

Write-Host ""
Write-Host "🏥 Testando Health Checks via Docker (Interno):" -ForegroundColor Cyan

$services = @(
    @{Name="Log Consumer Service"; Container="log-consumer-service"},
    @{Name="Log Analytics Service"; Container="log-analytics-service"},
    @{Name="Log Producer Service"; Container="log-producer-service"},
    @{Name="Virtual Stock Service"; Container="virtual-stock-service"}
)

$workingServices = @()

foreach ($service in $services) {
    if (Test-DockerEndpoint -ServiceName $service.Name -ContainerName $service.Container) {
        $workingServices += $service
    }
    Write-Host ""
}

Write-Host "🌐 Testando Conectividade Externa (Windows → Docker):" -ForegroundColor Cyan

$externalTests = @(
    @{Name="Log Consumer"; Url="http://localhost:8082/actuator/health"; Port="8082"},
    @{Name="Log Analytics"; Url="http://localhost:8083/actuator/health"; Port="8083"},
    @{Name="Log Producer"; Url="http://localhost:8081/actuator/health"; Port="8081"},
    @{Name="Virtual Stock"; Url="http://localhost:8084/actuator/health"; Port="8084"}
)

$externalWorking = @()

foreach ($test in $externalTests) {
    if (Test-Endpoint -ServiceName $test.Name -Url $test.Url -Port $test.Port) {
        $externalWorking += $test
    }
    Write-Host ""
}

# Gerar comandos curl para teste
Write-Host "📋 Comandos de Teste Disponíveis:" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta
Write-Host ""

if ($workingServices.Count -gt 0) {
    Write-Host "🐧 Comandos WSL/Docker (Interno):" -ForegroundColor Green
    foreach ($service in $workingServices) {
        Write-Host "wsl -d Ubuntu sh -c `"docker exec $($service.Container) curl -s http://localhost:8080/actuator/health`"" -ForegroundColor White
    }
    Write-Host ""
}

if ($externalWorking.Count -gt 0) {
    Write-Host "🪟 Comandos Windows (Externo):" -ForegroundColor Green
    foreach ($test in $externalWorking) {
        Write-Host "Invoke-RestMethod -Uri '$($test.Url)' -Method Get" -ForegroundColor White
    }
    Write-Host ""
}

# Teste específico de funcionalidade
Write-Host "🧪 Testes de Funcionalidade Recomendados:" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

if ($workingServices | Where-Object {$_.Container -eq "log-producer-service"}) {
    Write-Host "📤 Teste de Produção de Logs:" -ForegroundColor Cyan
    Write-Host "wsl -d Ubuntu sh -c `"docker exec log-producer-service curl -X POST http://localhost:8080/api/logs -H 'Content-Type: application/json' -d '{\"message\":\"Test log\",\"level\":\"INFO\"}'`"" -ForegroundColor White
    Write-Host ""
}

if ($workingServices | Where-Object {$_.Container -eq "virtual-stock-service"}) {
    Write-Host "📊 Teste de Stock Service:" -ForegroundColor Cyan
    Write-Host "wsl -d Ubuntu sh -c `"docker exec virtual-stock-service curl -s http://localhost:8080/api/stocks`"" -ForegroundColor White
    Write-Host ""
}

Write-Host "✨ Ambiente Linux Virtualizado com Docker - Pronto para Testes!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
