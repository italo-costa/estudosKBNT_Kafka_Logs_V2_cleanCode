#!/usr/bin/env pwsh
# Teste Integrado REAL - 300 Mensagens
# Garantia de disponibilidade completa da aplicacao

param(
    [int]$TotalMessages = 300,
    [int]$Port = 8080,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "           TESTE INTEGRADO REAL - $TotalMessages MENSAGENS" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# FASE 1: LIMPEZA COMPLETA
Write-Host "`nFASE 1: LIMPEZA COMPLETA DO AMBIENTE" -ForegroundColor Yellow

Write-Host "   Finalizando processos Java..." -ForegroundColor White
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "   Liberando porta $Port..." -ForegroundColor White
$portsInUse = netstat -ano | findstr ":$Port"
if ($portsInUse) {
    $processes = netstat -ano | findstr ":$Port" | ForEach-Object { 
        if ($_ -match '\s+(\d+)$') { $matches[1] } 
    } | Select-Object -Unique
    
    foreach ($pid in $processes) {
        taskkill /PID $pid /F 2>$null
    }
}

Start-Sleep 3
Write-Host "   OK - Ambiente limpo" -ForegroundColor Green

# FASE 2: INICIALIZACAO DA APLICACAO
Write-Host "`nFASE 2: INICIALIZACAO DA APLICACAO" -ForegroundColor Yellow

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
$javaPath = "$env:JAVA_HOME\bin\java.exe"
$jarPath = "C:\workspace\estudosKBNT_Kafka_Logs\simple-app\target\simple-stock-api-1.0.0.jar"

if (-not (Test-Path $javaPath)) {
    Write-Host "ERRO: Java nao encontrado: $javaPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $jarPath)) {
    Write-Host "ERRO: JAR nao encontrado: $jarPath" -ForegroundColor Red
    exit 1
}

Write-Host "   Iniciando Spring Boot na porta $Port..." -ForegroundColor White

$processArgs = @(
    "-Dserver.address=0.0.0.0",
    "-Dserver.port=$Port", 
    "-Djava.net.preferIPv4Stack=true",
    "-Dspring.profiles.active=dev",
    "-jar",
    "`"$jarPath`""
) -join " "

$process = Start-Process -FilePath $javaPath -ArgumentList $processArgs -PassThru -WindowStyle Hidden

Write-Host "   Aplicacao iniciada - PID: $($process.Id)" -ForegroundColor Green

# FASE 3: VERIFICACAO DE DISPONIBILIDADE
Write-Host "`nFASE 3: VERIFICACAO DE DISPONIBILIDADE" -ForegroundColor Yellow

$maxAttempts = 60
$attempt = 0
$appReady = $false

do {
    $attempt++
    Start-Sleep 2
    
    Write-Host "      Tentativa $attempt/$maxAttempts..." -ForegroundColor Gray
    
    if ($process.HasExited) {
        Write-Host "ERRO: Processo terminou - Exit Code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    try {
        $healthResponse = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 5
        if ($healthResponse.status -eq "UP") {
            Write-Host "   OK - Aplicacao disponivel!" -ForegroundColor Green
            $appReady = $true
        }
    } catch {
        # Continua tentando
    }
    
} while (-not $appReady -and $attempt -lt $maxAttempts)

if (-not $appReady) {
    Write-Host "ERRO: Aplicacao nao ficou disponivel apos $maxAttempts tentativas" -ForegroundColor Red
    $process.Kill()
    exit 1
}

# FASE 4: VALIDACAO DOS ENDPOINTS
Write-Host "`nFASE 4: VALIDACAO DOS ENDPOINTS" -ForegroundColor Yellow

$criticalEndpoints = @(
    "http://localhost:$Port/actuator/health",
    "http://localhost:$Port/actuator/info", 
    "http://localhost:$Port/api/v1/stocks",
    "http://localhost:$Port/test"
)

$allEndpointsReady = $true
foreach ($endpoint in $criticalEndpoints) {
    try {
        $testStart = Get-Date
        $response = Invoke-RestMethod -Uri $endpoint -TimeoutSec 10
        $testEnd = Get-Date
        $duration = [math]::Round(($testEnd - $testStart).TotalMilliseconds)
        
        Write-Host "      OK: $endpoint (${duration}ms)" -ForegroundColor Green
        
    } catch {
        Write-Host "      ERRO: $endpoint - $($_.Exception.Message)" -ForegroundColor Red
        $allEndpointsReady = $false
    }
}

if (-not $allEndpointsReady) {
    Write-Host "ERRO: Nem todos os endpoints estao funcionando" -ForegroundColor Red
    $process.Kill()
    exit 1
}

Write-Host "   SUCESSO - TODOS OS ENDPOINTS VALIDADOS!" -ForegroundColor Green

# FASE 5: TESTE DE TRAFEGO REAL
Write-Host "`nFASE 5: TESTE DE TRAFEGO - $TotalMessages MENSAGENS REAIS" -ForegroundColor Yellow

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
        
        # Progress a cada 25 requests
        if ($i % 25 -eq 0) {
            $percentage = [math]::Round(($i / $TotalMessages) * 100, 1)
            $successRate = [math]::Round(($results.SuccessfulRequests / $i) * 100, 1)
            $avgLatency = [math]::Round($results.TotalLatency / $results.SuccessfulRequests, 1)
            
            Write-Host "      OK: $i/$TotalMessages ($percentage%) | Sucesso: $successRate% | Latencia: ${avgLatency}ms" -ForegroundColor Green
        }
        
    } catch {
        $results.FailedRequests++
        
        if ($i % 50 -eq 0) {
            $percentage = [math]::Round(($i / $TotalMessages) * 100, 1)
            Write-Host "      ERRO: $i/$TotalMessages ($percentage%) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Start-Sleep -Milliseconds 25
}

$results.EndTime = Get-Date
$results.TotalDuration = ($results.EndTime - $results.StartTime).TotalSeconds
$results.Throughput = [math]::Round($TotalMessages / $results.TotalDuration, 2)
$results.AverageLatency = if ($results.SuccessfulRequests -gt 0) {
    [math]::Round($results.TotalLatency / $results.SuccessfulRequests, 2)
} else { 0 }
$results.SuccessRate = [math]::Round(($results.SuccessfulRequests / $TotalMessages) * 100, 2)

# FASE 6: RELATORIO FINAL
Write-Host "`nFASE 6: RELATORIO FINAL" -ForegroundColor Yellow

$totalTime = (Get-Date) - $StartTime

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                 RELATORIO DE TESTE INTEGRADO REAL" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

Write-Host "`nRESULTADOS PRINCIPAIS:" -ForegroundColor White
Write-Host "   Total de mensagens: $($results.TotalRequests)" -ForegroundColor White
Write-Host "   Requests bem-sucedidos: $($results.SuccessfulRequests)" -ForegroundColor Green
Write-Host "   Requests falharam: $($results.FailedRequests)" -ForegroundColor $(if ($results.FailedRequests -eq 0) {"Green"} else {"Red"})
Write-Host "   Taxa de sucesso: $($results.SuccessRate)%" -ForegroundColor $(if ($results.SuccessRate -ge 95) {"Green"} elseif ($results.SuccessRate -ge 90) {"Yellow"} else {"Red"})

Write-Host "`nPERFORMANCE:" -ForegroundColor White
Write-Host "   Throughput: $($results.Throughput) requests/segundo" -ForegroundColor Cyan
Write-Host "   Latencia media: $($results.AverageLatency)ms" -ForegroundColor Cyan
Write-Host "   Latencia minima: $([math]::Round($results.MinLatency, 2))ms" -ForegroundColor White
Write-Host "   Latencia maxima: $([math]::Round($results.MaxLatency, 2))ms" -ForegroundColor White

Write-Host "`nDISTRIBUICAO POR ENDPOINT:" -ForegroundColor White
Write-Host "   Health Checks: $($results.HealthChecks)" -ForegroundColor White
Write-Host "   Info Requests: $($results.InfoRequests)" -ForegroundColor White
Write-Host "   Stocks API: $($results.StocksRequests)" -ForegroundColor White
Write-Host "   Test Endpoint: $($results.TestRequests)" -ForegroundColor White

Write-Host "`nTEMPOS:" -ForegroundColor White
Write-Host "   Tempo total: $([math]::Round($totalTime.TotalSeconds, 2))s" -ForegroundColor White
Write-Host "   Tempo do teste: $([math]::Round($results.TotalDuration, 2))s" -ForegroundColor White

Write-Host "`nAVALIACAO FINAL:" -ForegroundColor White
if ($results.SuccessRate -eq 100) {
    Write-Host "   PERFEITO - Todos os requests foram bem-sucedidos!" -ForegroundColor Green
} elseif ($results.SuccessRate -ge 95) {
    Write-Host "   EXCELENTE - Taxa de sucesso acima de 95%" -ForegroundColor Green
} elseif ($results.SuccessRate -ge 90) {
    Write-Host "   MUITO BOM - Taxa de sucesso acima de 90%" -ForegroundColor Yellow
} else {
    Write-Host "   ATENCAO - Taxa de sucesso abaixo de 90%" -ForegroundColor Red
}

Write-Host "`nAPLICACAO AINDA RODANDO:" -ForegroundColor White
Write-Host "   PID: $($process.Id)" -ForegroundColor Gray
Write-Host "   Para finalizar: taskkill /PID $($process.Id) /F" -ForegroundColor Gray

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "         TESTE DE $TotalMessages MENSAGENS REAIS CONCLUIDO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Salvar relatorio
$reportFile = "C:\workspace\estudosKBNT_Kafka_Logs\RELATORIO-TESTE-300-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "`nRelatorio salvo em: $reportFile" -ForegroundColor Cyan

return $results
