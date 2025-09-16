# Script de Diagnóstico de Rede - Virtual Stock Service
# Use este script para diagnosticar problemas de timeout e conectividade

Write-Host "=== Diagnóstico de Rede Virtual Stock Service ===" -ForegroundColor Green

# Função para testar endpoint com timeout customizado
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$URL,
        [int]$TimeoutSeconds = 30
    )
    
    Write-Host "Testando $Name..." -ForegroundColor Yellow
    
    try {
        $startTime = Get-Date
        $response = wsl -e bash -c "timeout ${TimeoutSeconds}s curl -s -w 'HTTP_CODE:%{http_code}\nTIME_TOTAL:%{time_total}\nTIME_CONNECT:%{time_connect}\nTIME_NAMELOOKUP:%{time_namelookup}' -o /dev/null '$URL'"
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if ($response -match "HTTP_CODE:(\d+)") {
            $httpCode = $matches[1]
            if ($response -match "TIME_TOTAL:([0-9.]+)") {
                $totalTime = [math]::Round([double]$matches[1], 3)
            }
            if ($response -match "TIME_CONNECT:([0-9.]+)") {
                $connectTime = [math]::Round([double]$matches[1], 3)
            }
            
            if ($httpCode -eq "200") {
                Write-Host "✅ $Name: OK (HTTP $httpCode) - Total: ${totalTime}s, Connect: ${connectTime}s" -ForegroundColor Green
            } else {
                Write-Host "⚠️ $Name: HTTP $httpCode - Total: ${totalTime}s, Connect: ${connectTime}s" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ $Name: Timeout ou erro - Duração: ${duration}s" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ $Name: Erro de execução - $_" -ForegroundColor Red
    }
}

# Verificar status dos containers
Write-Host "`n1. Status dos Containers:" -ForegroundColor Cyan
wsl -e bash -c "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'NAMES|kbnt'"

# Verificar conectividade de rede Docker
Write-Host "`n2. Conectividade de Rede Docker:" -ForegroundColor Cyan
Write-Host "Testando ping interno entre containers..." -ForegroundColor Yellow
$pingResult = wsl -e bash -c "docker exec virtual-stock-stable ping -c 2 postgres-kbnt-stable 2>/dev/null"
if ($pingResult -match "2 packets transmitted, 2 received") {
    Write-Host "✅ Ping entre containers funcionando" -ForegroundColor Green
} else {
    Write-Host "❌ Problema de conectividade entre containers" -ForegroundColor Red
}

# Verificar portas em uso
Write-Host "`n3. Verificação de Portas:" -ForegroundColor Cyan
Write-Host "Portas Docker em uso:" -ForegroundColor Yellow
wsl -e bash -c "docker port virtual-stock-stable"
wsl -e bash -c "docker port postgres-kbnt-stable"

# Testar endpoints com métricas detalhadas
Write-Host "`n4. Teste de Endpoints com Métricas:" -ForegroundColor Cyan

$endpoints = @(
    @{Name="Health Check"; URL="http://localhost:8084/actuator/health"},
    @{Name="Página Inicial"; URL="http://localhost:8084/"},
    @{Name="Ping"; URL="http://localhost:8084/ping"},
    @{Name="API Health"; URL="http://localhost:8084/api/v1/health"},
    @{Name="Stocks API"; URL="http://localhost:8084/api/v1/virtual-stock/stocks"}
)

foreach ($endpoint in $endpoints) {
    Test-Endpoint -Name $endpoint.Name -URL $endpoint.URL -TimeoutSeconds 30
    Start-Sleep -Seconds 2
}

# Verificar logs recentes para erros
Write-Host "`n5. Verificação de Logs Recentes:" -ForegroundColor Cyan
Write-Host "Últimos erros da aplicação:" -ForegroundColor Yellow
$logs = wsl -e bash -c "docker logs --tail 50 virtual-stock-stable 2>&1 | grep -i 'error\|exception\|timeout'"
if ($logs) {
    Write-Host $logs -ForegroundColor Red
} else {
    Write-Host "✅ Nenhum erro recente encontrado" -ForegroundColor Green
}

# Verificar recursos do sistema
Write-Host "`n6. Recursos do Sistema:" -ForegroundColor Cyan
Write-Host "Uso de recursos dos containers:" -ForegroundColor Yellow
wsl -e bash -c "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"

# Verificar port forwarding Windows
Write-Host "`n7. Port Forwarding Windows:" -ForegroundColor Cyan
Write-Host "Verificando port forwarding para Windows..." -ForegroundColor Yellow
try {
    $portForward = netsh interface portproxy show v4tov4 2>$null | Select-String "8084"
    if ($portForward) {
        Write-Host "✅ Port forwarding configurado: $portForward" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Port forwarding não configurado" -ForegroundColor Yellow
        Write-Host "Execute setup-port-forwarding.ps1 como Administrador" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Erro ao verificar port forwarding" -ForegroundColor Red
}

Write-Host "`n=== Diagnóstico Concluído ===" -ForegroundColor Green
Write-Host "Se houver timeouts consistentes:" -ForegroundColor Yellow
Write-Host "1. Execute setup-port-forwarding.ps1 como Administrador" -ForegroundColor Gray
Write-Host "2. Reinicie a aplicação: restart-app.ps1" -ForegroundColor Gray
Write-Host "3. Verifique se antivírus/firewall está bloqueando" -ForegroundColor Gray
