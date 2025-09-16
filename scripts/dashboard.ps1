# =============================================================================
# Dashboard de Monitoramento - KBNT Application
# =============================================================================

param(
    [switch]$ShowLogs = $true,
    [int]$RefreshInterval = 5
)

# Função para limpar a tela
function Clear-Screen {
    Clear-Host
}

# Função para exibir header
function Show-Header {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "🎯 KBNT APPLICATION DASHBOARD - $timestamp" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Gray
}

# Função para testar serviço
function Test-Service {
    param(
        [string]$Name,
        [string]$Url,
        [int]$Port
    )
    
    $result = @{
        Name = $Name
        Status = "❌ OFFLINE"
        Response = "N/A"
        Color = "Red"
    }
    
    try {
        # Testar conectividade
        $connection = Test-NetConnection -ComputerName 172.30.221.62 -Port $Port -WarningAction SilentlyContinue
        
        if ($connection.TcpTestSucceeded) {
            if ($Url) {
                $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    $result.Status = "✅ ONLINE"
                    $result.Response = "$($response.StatusCode) OK"
                    $result.Color = "Green"
                } else {
                    $result.Status = "⚠️ ISSUES"
                    $result.Response = "$($response.StatusCode)"
                    $result.Color = "Yellow"
                }
            } else {
                $result.Status = "✅ ONLINE"
                $result.Response = "Port Open"
                $result.Color = "Green"
            }
        }
    }
    catch {
        $result.Status = "❌ OFFLINE"
        $result.Response = "Connection Failed"
        $result.Color = "Red"
    }
    
    return $result
}

# Função para mostrar status dos serviços
function Show-Services {
    Write-Host "📊 SERVIÇOS" -ForegroundColor Cyan
    Write-Host "-" * 40 -ForegroundColor Gray
    
    $services = @(
        @{ Name = "PostgreSQL"; Url = $null; Port = 5432 }
        @{ Name = "Virtual Stock Service"; Url = "http://172.30.221.62:8084/actuator/health"; Port = 8084 }
        @{ Name = "API Gateway"; Url = "http://172.30.221.62:8080/actuator/health"; Port = 8080 }
    )
    
    foreach ($service in $services) {
        $result = Test-Service -Name $service.Name -Url $service.Url -Port $service.Port
        Write-Host "🔹 $($result.Name.PadRight(25)) $($result.Status) ($($result.Response))" -ForegroundColor $result.Color
    }
    
    Write-Host ""
}

# Função para mostrar containers Docker
function Show-Containers {
    Write-Host "🐳 CONTAINERS DOCKER" -ForegroundColor Cyan
    Write-Host "-" * 40 -ForegroundColor Gray
    
    try {
        $containers = wsl -d Ubuntu bash -c "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        $containers -split "`n" | ForEach-Object {
            if ($_ -and $_ -notmatch "NAMES") {
                Write-Host "  $_" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "  ❌ Erro ao obter lista de containers" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Função para mostrar URLs úteis
function Show-URLs {
    Write-Host "🌐 URLs DISPONÍVEIS" -ForegroundColor Cyan
    Write-Host "-" * 40 -ForegroundColor Gray
    Write-Host "  Virtual Stock API:  http://172.30.221.62:8084/api/v1/virtual-stock/stocks" -ForegroundColor Green
    Write-Host "  Health Check:       http://172.30.221.62:8084/actuator/health" -ForegroundColor Green
    Write-Host "  API Gateway:        http://172.30.221.62:8080/actuator/health" -ForegroundColor Green
    Write-Host "  Postman Collection: Virtual_Stock_API_Postman_Collection.json" -ForegroundColor Yellow
    Write-Host ""
}

# Função para mostrar logs recentes
function Show-RecentLogs {
    if (-not $ShowLogs) { return }
    
    Write-Host "📄 LOGS RECENTES" -ForegroundColor Cyan
    Write-Host "-" * 40 -ForegroundColor Gray
    
    $containers = @("postgres-db", "virtual-stock-svc", "api-gateway-svc")
    
    foreach ($container in $containers) {
        try {
            Write-Host "🔹 $container" -ForegroundColor Yellow
            $logs = wsl -d Ubuntu bash -c "docker logs $container --tail 3 2>&1"
            if ($logs) {
                $logs -split "`n" | ForEach-Object {
                    if ($_.Trim()) {
                        Write-Host "  $_" -ForegroundColor Gray
                    }
                }
            } else {
                Write-Host "  (sem logs recentes)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "  ❌ Erro ao obter logs" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Função para mostrar comandos úteis
function Show-Commands {
    Write-Host "⚡ COMANDOS ÚTEIS" -ForegroundColor Cyan
    Write-Host "-" * 40 -ForegroundColor Gray
    Write-Host "  Verificar status: wsl -d Ubuntu bash -c '/mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/scripts/app-manager.sh status'" -ForegroundColor Yellow
    Write-Host "  Restart serviços: wsl -d Ubuntu bash -c '/mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/scripts/app-manager.sh restart'" -ForegroundColor Yellow
    Write-Host "  Ver logs: wsl -d Ubuntu bash -c 'docker logs <container-name> --tail 20'" -ForegroundColor Yellow
    Write-Host "  Monitor logs: wsl -d Ubuntu bash -c 'tail -f /tmp/app-monitor.log'" -ForegroundColor Yellow
    Write-Host ""
}

# Função principal do dashboard
function Start-Dashboard {
    Write-Host "🚀 Iniciando Dashboard de Monitoramento..." -ForegroundColor Green
    Write-Host "⏰ Atualizando a cada $RefreshInterval segundos" -ForegroundColor Cyan
    Write-Host "🛑 Pressione Ctrl+C para sair" -ForegroundColor Yellow
    Write-Host ""
    
    while ($true) {
        Clear-Screen
        Show-Header
        Show-Services
        Show-Containers
        Show-URLs
        
        if ($ShowLogs) {
            Show-RecentLogs
        }
        
        Show-Commands
        
        Write-Host "⏳ Próxima atualização em $RefreshInterval segundos... (Ctrl+C para sair)" -ForegroundColor Gray
        
        Start-Sleep -Seconds $RefreshInterval
    }
}

# Menu inicial
Write-Host "🎯 DASHBOARD DE MONITORAMENTO - KBNT APPLICATION" -ForegroundColor Green
Write-Host ""
Write-Host "Escolha uma opção:" -ForegroundColor White
Write-Host "1. Dashboard completo (com logs)"
Write-Host "2. Dashboard simples (sem logs)"
Write-Host "3. Verificação única"
Write-Host "4. Sair"

$choice = Read-Host "Opção"

switch ($choice) {
    "1" { 
        $ShowLogs = $true
        Start-Dashboard 
    }
    "2" { 
        $ShowLogs = $false
        Start-Dashboard 
    }
    "3" { 
        Show-Header
        Show-Services
        Show-Containers
        Show-URLs
    }
    "4" { exit }
    default { 
        $ShowLogs = $true
        Start-Dashboard 
    }
}
