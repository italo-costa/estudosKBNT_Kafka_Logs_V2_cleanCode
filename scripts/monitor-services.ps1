# =============================================================================
# Monitor de Serviços - Mantém toda aplicação funcionando
# =============================================================================

param(
    [int]$CheckInterval = 30,  # Verificar a cada 30 segundos
    [switch]$AutoRestart = $true,
    [switch]$ShowLogs = $true
)

# Configurações dos serviços
$services = @{
    "postgres-db" = @{
        "port" = 5432
        "healthUrl" = $null
        "command" = "docker run -d --name postgres-db --restart=always -p 5432:5432 -e POSTGRES_DB=kbnt_db -e POSTGRES_USER=kbnt_user -e POSTGRES_PASSWORD=kbnt_password postgres:15"
    }
    "virtual-stock-svc" = @{
        "port" = 8084
        "healthUrl" = "http://172.30.221.62:8084/actuator/health"
        "command" = "docker run -d --name virtual-stock-svc --restart=always -p 0.0.0.0:8084:8080 --add-host=host.docker.internal:host-gateway -e SERVER_PORT=8080 -e SPRING_DATASOURCE_URL='jdbc:postgresql://host.docker.internal:5432/kbnt_db' -e SPRING_DATASOURCE_USERNAME=kbnt_user -e SPRING_DATASOURCE_PASSWORD=kbnt_password -e SPRING_PROFILES_ACTIVE=docker estudoskbnt_kafka_logs_v2_cleancode_virtual-stock-service-1"
    }
    "api-gateway-svc" = @{
        "port" = 8080
        "healthUrl" = "http://172.30.221.62:8080/actuator/health"
        "command" = "docker run -d --name api-gateway-svc --restart=always -p 0.0.0.0:8080:8080 --add-host=host.docker.internal:host-gateway -e SERVER_PORT=8080 -e SPRING_PROFILES_ACTIVE=simple estudoskbnt_kafka_logs_v2_cleancode_api-gateway-1"
    }
}

# Função para verificar se container está rodando
function Test-ContainerRunning {
    param([string]$containerName)
    
    try {
        $result = wsl -d Ubuntu bash -c "docker ps --filter name=$containerName --format '{{.Status}}'"
        return ($result -and $result.Contains("Up"))
    }
    catch {
        return $false
    }
}

# Função para verificar health endpoint
function Test-HealthEndpoint {
    param([string]$url)
    
    if (-not $url) { return $true }
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        return ($response.StatusCode -eq 200)
    }
    catch {
        return $false
    }
}

# Função para verificar porta
function Test-Port {
    param([string]$port)
    
    try {
        $connection = Test-NetConnection -ComputerName 172.30.221.62 -Port $port -WarningAction SilentlyContinue
        return $connection.TcpTestSucceeded
    }
    catch {
        return $false
    }
}

# Função para obter logs do container
function Get-ContainerLogs {
    param([string]$containerName, [int]$lines = 10)
    
    try {
        return wsl -d Ubuntu bash -c "docker logs $containerName --tail $lines 2>&1"
    }
    catch {
        return "Erro ao obter logs de $containerName"
    }
}

# Função para restart de serviço
function Restart-Service {
    param([string]$serviceName)
    
    Write-Host "🔄 RESTART: $serviceName" -ForegroundColor Yellow
    
    # Parar e remover container existente
    wsl -d Ubuntu bash -c "docker stop $serviceName 2>/dev/null" | Out-Null
    wsl -d Ubuntu bash -c "docker rm $serviceName 2>/dev/null" | Out-Null
    
    # Aguardar limpeza
    Start-Sleep -Seconds 3
    
    # Restart com comando específico
    $command = $services[$serviceName]["command"]
    Write-Host "  ▶️ Executando: $command" -ForegroundColor Cyan
    
    try {
        wsl -d Ubuntu bash -c $command
        Start-Sleep -Seconds 5
        
        if (Test-ContainerRunning $serviceName) {
            Write-Host "  ✅ $serviceName reiniciado com sucesso" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ Falha ao reiniciar $serviceName" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "  ❌ Erro ao executar comando para $serviceName" -ForegroundColor Red
        return $false
    }
}

# Função principal de monitoramento
function Start-Monitoring {
    Write-Host "🚀 INICIANDO MONITORAMENTO DE SERVIÇOS" -ForegroundColor Green
    Write-Host "⏰ Intervalo de verificação: $CheckInterval segundos" -ForegroundColor Cyan
    Write-Host "🔄 Auto-restart: $AutoRestart" -ForegroundColor Cyan
    Write-Host "📊 Mostrar logs: $ShowLogs" -ForegroundColor Cyan
    Write-Host "=" * 80 -ForegroundColor Gray
    
    $iteration = 0
    
    while ($true) {
        $iteration++
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        Write-Host "🔍 CHECK #$iteration - $timestamp" -ForegroundColor White
        
        $allHealthy = $true
        
        foreach ($serviceName in $services.Keys) {
            $service = $services[$serviceName]
            
            Write-Host "  📋 Verificando $serviceName..." -NoNewline
            
            # Verificar se container está rodando
            $isRunning = Test-ContainerRunning $serviceName
            
            if (-not $isRunning) {
                Write-Host " ❌ PARADO" -ForegroundColor Red
                $allHealthy = $false
                
                if ($ShowLogs) {
                    Write-Host "    📄 Logs recentes:" -ForegroundColor Yellow
                    $logs = Get-ContainerLogs $serviceName 5
                    $logs -split "`n" | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
                }
                
                if ($AutoRestart) {
                    if (Restart-Service $serviceName) {
                        Start-Sleep -Seconds 10  # Aguardar inicialização
                    }
                }
                continue
            }
            
            # Verificar porta
            $portOk = Test-Port $service["port"]
            if (-not $portOk) {
                Write-Host " ❌ PORTA $($service['port']) INACESSÍVEL" -ForegroundColor Red
                $allHealthy = $false
                continue
            }
            
            # Verificar health endpoint se existir
            $healthOk = Test-HealthEndpoint $service["healthUrl"]
            if (-not $healthOk -and $service["healthUrl"]) {
                Write-Host " ⚠️ HEALTH ENDPOINT FALHOU" -ForegroundColor Yellow
                $allHealthy = $false
                continue
            }
            
            Write-Host " ✅ OK" -ForegroundColor Green
        }
        
        if ($allHealthy) {
            Write-Host "  🎉 TODOS OS SERVIÇOS FUNCIONANDO!" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️ ALGUNS SERVIÇOS COM PROBLEMAS" -ForegroundColor Yellow
        }
        
        Write-Host "  ⏳ Próxima verificação em $CheckInterval segundos..." -ForegroundColor Gray
        Write-Host ""
        
        Start-Sleep -Seconds $CheckInterval
    }
}

# Função para mostrar status atual
function Show-CurrentStatus {
    Write-Host "📊 STATUS ATUAL DOS SERVIÇOS" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Gray
    
    foreach ($serviceName in $services.Keys) {
        $service = $services[$serviceName]
        
        $isRunning = Test-ContainerRunning $serviceName
        $portOk = Test-Port $service["port"]
        $healthOk = Test-HealthEndpoint $service["healthUrl"]
        
        Write-Host "🔹 $serviceName" -ForegroundColor White
        Write-Host "  Container: $(if($isRunning){'✅ Rodando'}else{'❌ Parado'})"
        Write-Host "  Porta $($service['port']): $(if($portOk){'✅ Acessível'}else{'❌ Inacessível'})"
        
        if ($service["healthUrl"]) {
            Write-Host "  Health: $(if($healthOk){'✅ OK'}else{'❌ Falhou'})"
        }
        
        if ($isRunning -and $ShowLogs) {
            Write-Host "  📄 Últimas linhas do log:" -ForegroundColor Yellow
            $logs = Get-ContainerLogs $serviceName 3
            $logs -split "`n" | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
        
        Write-Host ""
    }
}

# Menu principal
Write-Host "🎯 SISTEMA DE MONITORAMENTO - APLICAÇÃO KBNT" -ForegroundColor Green
Write-Host "Escolha uma opção:" -ForegroundColor White
Write-Host "1. Verificar status atual"
Write-Host "2. Iniciar monitoramento contínuo"
Write-Host "3. Restart todos os serviços"
Write-Host "4. Sair"

$choice = Read-Host "Opção"

switch ($choice) {
    "1" { Show-CurrentStatus }
    "2" { Start-Monitoring }
    "3" { 
        foreach ($serviceName in $services.Keys) {
            Restart-Service $serviceName
        }
    }
    "4" { exit }
    default { Start-Monitoring }
}
