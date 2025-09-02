#!/usr/bin/env pwsh
# Teste Integrado de Tráfego REAL - 300 Mensagens
# Garante disponibilidade completa da aplicação antes do teste

param(
    [int]$TotalMessages = 300,
    [int]$Port = 8080,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "      TESTE INTEGRADO REAL - $TotalMessages MENSAGENS" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# === FASE 1: LIMPEZA COMPLETA DO AMBIENTE ===
Write-Host "`n🧹 FASE 1: LIMPEZA COMPLETA DO AMBIENTE" -ForegroundColor Yellow

Write-Host "   Finalizando processos Java existentes..." -ForegroundColor White
Get-Process | Where-Object {$_.ProcessName -eq "java"} | ForEach-Object {
    Write-Host "      Finalizando Java PID: $($_.Id)" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Host "   Liberando porta $Port..." -ForegroundColor White
$portsInUse = netstat -ano | findstr ":$Port"
if ($portsInUse) {
    $processes = netstat -ano | findstr ":$Port" | ForEach-Object { 
        if ($_ -match '\s+(\d+)$') { $matches[1] } 
    } | Select-Object -Unique
    
    foreach ($pid in $processes) {
        Write-Host "      Liberando porta - PID: $pid" -ForegroundColor Gray
        taskkill /PID $pid /F 2>$null
    }
}

Start-Sleep 3
Write-Host "   ✅ Ambiente limpo" -ForegroundColor Green

# === FASE 2: INICIALIZAÇÃO ROBUSTA DA APLICAÇÃO ===
Write-Host "`n🚀 FASE 2: INICIALIZAÇÃO DA APLICAÇÃO" -ForegroundColor Yellow

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
$javaPath = "$env:JAVA_HOME\bin\java.exe"
$jarPath = "C:\workspace\estudosKBNT_Kafka_Logs\simple-app\target\simple-stock-api-1.0.0.jar"

if (-not (Test-Path $javaPath)) {
    Write-Host "❌ Java não encontrado: $javaPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $jarPath)) {
    Write-Host "❌ JAR não encontrado: $jarPath" -ForegroundColor Red
    exit 1
}

Write-Host "   Iniciando Spring Boot na porta $Port..." -ForegroundColor White

# Usar Start-Process para melhor controle
$processArgs = @(
    "-Dserver.address=0.0.0.0",
    "-Dserver.port=$Port", 
    "-Djava.net.preferIPv4Stack=true",
    "-Dspring.profiles.active=dev",
    "-Xmx512m",
    "-jar",
    "`"$jarPath`""
) -join " "

$process = Start-Process -FilePath $javaPath -ArgumentList $processArgs -PassThru -WindowStyle Hidden

if (-not $process) {
    Write-Host "❌ Falha ao iniciar aplicação" -ForegroundColor Red
    exit 1
}

Write-Host "   Aplicação iniciada - PID: $($process.Id)" -ForegroundColor Green

# === FASE 3: VERIFICAÇÃO DE DISPONIBILIDADE ===
Write-Host "`n🔍 FASE 3: VERIFICAÇÃO DE DISPONIBILIDADE" -ForegroundColor Yellow

Write-Host "   Aguardando aplicação ficar disponível..." -ForegroundColor White

$maxAttempts = 60  # 60 tentativas = 2 minutos
$attempt = 0
$appReady = $false

do {
    $attempt++
    Start-Sleep 2
    
    Write-Host "      Tentativa $attempt/$maxAttempts..." -ForegroundColor Gray
    
    # Verificar se processo ainda existe
    if ($process.HasExited) {
        Write-Host "❌ Processo da aplicação terminou inesperadamente" -ForegroundColor Red
        Write-Host "   Exit Code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    try {
        $healthResponse = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 5
        if ($healthResponse.status -eq "UP") {
            Write-Host "   ✅ Aplicação disponível!" -ForegroundColor Green
            $appReady = $true
        }
    } catch {
        # Continua tentando
    }
    
} while (-not $appReady -and $attempt -lt $maxAttempts)

if (-not $appReady) {
    Write-Host "❌ Aplicação não ficou disponível após $maxAttempts tentativas" -ForegroundColor Red
    $process.Kill()
    exit 1
}

# === FASE 4: VALIDAÇÃO COMPLETA DOS ENDPOINTS ===
Write-Host "`n✅ FASE 4: VALIDAÇÃO DOS ENDPOINTS" -ForegroundColor Yellow

$criticalEndpoints = @(
    "http://localhost:$Port/actuator/health",
    "http://localhost:$Port/actuator/info", 
    "http://localhost:$Port/api/v1/stocks",
    "http://localhost:$Port/test"
)

Write-Host "   Validando todos os endpoints críticos..." -ForegroundColor White

$allEndpointsReady = $true
foreach ($endpoint in $criticalEndpoints) {
    try {
        $testStart = Get-Date
        $response = Invoke-RestMethod -Uri $endpoint -TimeoutSec 10
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        Write-Host "      ✅ $endpoint ($([math]::Round($duration))ms)" -ForegroundColor Green
        
    } catch {
        Write-Host "      ❌ $endpoint - FALHOU: $($_.Exception.Message)" -ForegroundColor Red
        $allEndpointsReady = $false
    }
}

if (-not $allEndpointsReady) {
    Write-Host "❌ Nem todos os endpoints estão funcionando" -ForegroundColor Red
    $process.Kill()
    exit 1
}

Write-Host "   🎉 TODOS OS ENDPOINTS VALIDADOS E FUNCIONANDO!" -ForegroundColor Green

# === FASE 5: TESTE DE TRÁFEGO REAL ===
Write-Host "`n📊 FASE 5: TESTE DE TRÁFEGO - $TotalMessages MENSAGENS REAIS" -ForegroundColor Yellow

$results = @{
    TotalRequests = $TotalMessages
    SuccessfulRequests = 0
    FailedRequests = 0
    HealthChecks = 0
    InfoRequests = 0
    StocksRequests = 0
    TestRequests = 0
    MinLatency = [double]::MaxValue
    MaxLatency = 0
    TotalLatency = 0
    StartTime = Get-Date
}

Write-Host "   Executando $TotalMessages requests reais..." -ForegroundColor White
Write-Host "   Distribuição balanceada entre todos os endpoints" -ForegroundColor Gray

for ($i = 1; $i -le $TotalMessages; $i++) {
    $endpointIndex = $i % 4
    $requestStart = Get-Date
    
    try {
        switch ($endpointIndex) {
            0 { 
                $response = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 15
                $results.HealthChecks++
            }
            1 { 
                $response = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/info" -TimeoutSec 15
                $results.InfoRequests++
            }
            2 { 
                $response = Invoke-RestMethod -Uri "http://localhost:$Port/api/v1/stocks" -TimeoutSec 15
                $results.StocksRequests++
            }
            3 { 
                $response = Invoke-RestMethod -Uri "http://localhost:$Port/test" -TimeoutSec 15
                $results.TestRequests++
            }
        }
        
        $requestEnd = Get-Date
        $latency = ($requestEnd - $requestStart).TotalMilliseconds
        
        $results.SuccessfulRequests++
        $results.TotalLatency += $latency
        $results.MinLatency = [Math]::Min($results.MinLatency, $latency)
        $results.MaxLatency = [Math]::Max($results.MaxLatency, $latency)
        
        # Progress com detalhes a cada 25 requests
        if ($i % 25 -eq 0) {
            $percentage = [math]::Round(($i / $TotalMessages) * 100, 1)
            $successRate = [math]::Round(($results.SuccessfulRequests / $i) * 100, 1)
            $avgLatency = [math]::Round($results.TotalLatency / $results.SuccessfulRequests, 1)
            
            Write-Host "      ✅ $i/$TotalMessages ($percentage%) | Sucesso: $successRate% | Latência média: ${avgLatency}ms" -ForegroundColor Green
        }
        
    } catch {
        $results.FailedRequests++
        
        if ($i % 50 -eq 0) {  # Mostrar erros menos frequentemente
            $percentage = [math]::Round(($i / $TotalMessages) * 100, 1)
            Write-Host "      ❌ $i/$TotalMessages ($percentage%) - FALHA: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Pequeno delay para não sobrecarregar
    Start-Sleep -Milliseconds 25
}

$results.EndTime = Get-Date
$results.TotalDuration = ($results.EndTime - $results.StartTime).TotalSeconds
$results.Throughput = [math]::Round($TotalMessages / $results.TotalDuration, 2)
$results.AverageLatency = if ($results.SuccessfulRequests -gt 0) {
    [math]::Round($results.TotalLatency / $results.SuccessfulRequests, 2)
} else { 0 }
$results.SuccessRate = [math]::Round(($results.SuccessfulRequests / $TotalMessages) * 100, 2)

# === FASE 6: RELATÓRIO DETALHADO ===
Write-Host "`n📋 FASE 6: RELATÓRIO FINAL DO TESTE REAL" -ForegroundColor Yellow

$totalTime = (Get-Date) - $StartTime

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    RELATÓRIO DE TESTE INTEGRADO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

Write-Host "`n🎯 RESULTADOS PRINCIPAIS:" -ForegroundColor White
Write-Host "   Total de mensagens processadas: $($results.TotalRequests)" -ForegroundColor White
Write-Host "   Requests bem-sucedidos: $($results.SuccessfulRequests)" -ForegroundColor Green
Write-Host "   Requests falharam: $($results.FailedRequests)" -ForegroundColor $(if ($results.FailedRequests -eq 0) {"Green"} else {"Red"})
Write-Host "   Taxa de sucesso: $($results.SuccessRate)%" -ForegroundColor $(if ($results.SuccessRate -ge 95) {"Green"} elseif ($results.SuccessRate -ge 90) {"Yellow"} else {"Red"})

Write-Host "`n⚡ PERFORMANCE:" -ForegroundColor White
Write-Host "   Throughput: $($results.Throughput) requests/segundo" -ForegroundColor Cyan
Write-Host "   Latência média: $($results.AverageLatency)ms" -ForegroundColor Cyan
Write-Host "   Latência mínima: $([math]::Round($results.MinLatency, 2))ms" -ForegroundColor White
Write-Host "   Latência máxima: $([math]::Round($results.MaxLatency, 2))ms" -ForegroundColor White

Write-Host "`n📊 DISTRIBUIÇÃO POR ENDPOINT:" -ForegroundColor White
Write-Host "   Health Checks: $($results.HealthChecks)" -ForegroundColor White
Write-Host "   Info Requests: $($results.InfoRequests)" -ForegroundColor White
Write-Host "   Stocks API: $($results.StocksRequests)" -ForegroundColor White
Write-Host "   Test Endpoint: $($results.TestRequests)" -ForegroundColor White

Write-Host "`n⏱️ TEMPOS:" -ForegroundColor White
Write-Host "   Tempo total (com inicialização): $([math]::Round($totalTime.TotalSeconds, 2))s" -ForegroundColor White
Write-Host "   Tempo do teste de tráfego: $([math]::Round($results.TotalDuration, 2))s" -ForegroundColor White

Write-Host "`n🏆 AVALIAÇÃO FINAL:" -ForegroundColor White
if ($results.SuccessRate -eq 100) {
    Write-Host "   🥇 PERFEITO - Todos os requests foram bem-sucedidos!" -ForegroundColor Green
    Write-Host "   Sistema completamente estável e responsivo" -ForegroundColor Green
} elseif ($results.SuccessRate -ge 95) {
    Write-Host "   🥈 EXCELENTE - Taxa de sucesso acima de 95%" -ForegroundColor Green
    Write-Host "   Sistema muito estável" -ForegroundColor Green
} elseif ($results.SuccessRate -ge 90) {
    Write-Host "   🥉 MUITO BOM - Taxa de sucesso acima de 90%" -ForegroundColor Yellow
    Write-Host "   Sistema estável com pequenas falhas" -ForegroundColor Yellow
} else {
    Write-Host "   ⚠️ ATENÇÃO - Taxa de sucesso abaixo de 90%" -ForegroundColor Red
    Write-Host "   Sistema pode ter problemas de estabilidade" -ForegroundColor Red
}

# === LIMPEZA FINAL ===
Write-Host "`n🧹 FINALIZANDO TESTE..." -ForegroundColor White
Write-Host "   Mantendo aplicação rodando para análise adicional..." -ForegroundColor Gray
Write-Host "   PID da aplicação: $($process.Id)" -ForegroundColor Gray
Write-Host "   Para finalizar: taskkill /PID $($process.Id) /F" -ForegroundColor Gray

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "     TESTE DE $TotalMessages MENSAGENS REAIS CONCLUÍDO COM SUCESSO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Salvar resultados em arquivo para análise posterior
$reportFile = "C:\workspace\estudosKBNT_Kafka_Logs\RELATORIO-TESTE-300-MENSAGENS-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "`n📄 Relatório salvo em: $reportFile" -ForegroundColor Cyan

return $results
