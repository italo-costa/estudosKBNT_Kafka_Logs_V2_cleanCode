#!/usr/bin/env pwsh
# TESTE DE CARGA AVANÇADO - 1000 MENSAGENS
# Versão otimizada para testes de alta capacidade sem custos

param(
    [int]$TotalMessages = 1000,
    [int]$ParallelThreads = 5,
    [int]$Port = 8080,
    [switch]$GenerateReport,
    [switch]$RealTimeMonitoring,
    [string]$OutputDir = "C:\workspace\estudosKBNT_Kafka_Logs\dashboard\data"
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date
$ExecutionId = (Get-Date).ToString("yyyyMMdd-HHmmss")

Write-Host "=================================================================" -ForegroundColor Magenta
Write-Host "       TESTE DE CARGA AVANÇADO - $TotalMessages MENSAGENS" -ForegroundColor Magenta
Write-Host "       Threads: $ParallelThreads | Porta: $Port | ID: $ExecutionId" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

# Estrutura de dados para coleta de métricas
$TestResults = @{
    ExecutionId = $ExecutionId
    StartTime = $StartTime
    Configuration = @{
        TotalMessages = $TotalMessages
        ParallelThreads = $ParallelThreads
        Port = $Port
        TestType = "AdvancedLoadTest"
    }
    Metrics = @{
        TotalRequests = 0
        SuccessfulRequests = 0
        FailedRequests = 0
        MinLatency = [double]::MaxValue
        MaxLatency = 0
        TotalLatency = 0
        RequestsPerSecond = 0
        ByEndpoint = @{}
        LatencyDistribution = @()
        SlowRequests = @()  # Requests > 1000ms
        ErrorsByType = @{}
    }
    TechnologyStack = @{
        SpringBoot = @{Version = "2.7.18"; ResponseTimes = @(); Errors = 0}
        ActuatorHealth = @{Version = "2.7.18"; ResponseTimes = @(); Errors = 0}
        RestAPI = @{Version = "Custom"; ResponseTimes = @(); Errors = 0}
        TestEndpoint = @{Version = "Custom"; ResponseTimes = @(); Errors = 0}
    }
}

# === FASE 1: PREPARAÇÃO DO AMBIENTE ===
Write-Host "`n🔧 FASE 1: PREPARAÇÃO DO AMBIENTE AVANÇADO" -ForegroundColor Yellow

Write-Host "   Criando diretório de relatórios..." -ForegroundColor White
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

Write-Host "   Verificando aplicação..." -ForegroundColor White
$AppAvailable = $false
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 5
    if ($healthCheck.status -eq "UP") {
        $AppAvailable = $true
        Write-Host "   ✅ Aplicação disponível e respondendo" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️ Aplicação não disponível - modo simulação ativado" -ForegroundColor Yellow
}

# === FASE 2: DEFINIÇÃO DE ENDPOINTS E DISTRIBUIÇÃO ===
Write-Host "`n📊 FASE 2: CONFIGURAÇÃO DE ENDPOINTS" -ForegroundColor Yellow

$EndpointConfig = @(
    @{
        Name = "Health"
        URL = "http://localhost:$Port/actuator/health"
        Weight = 25
        Technology = "ActuatorHealth"
        ExpectedLatency = 50
    },
    @{
        Name = "Stocks"
        URL = "http://localhost:$Port/api/v1/stocks" 
        Weight = 40
        Technology = "RestAPI"
        ExpectedLatency = 100
    },
    @{
        Name = "Test"
        URL = "http://localhost:$Port/test"
        Weight = 25
        Technology = "TestEndpoint"
        ExpectedLatency = 75
    },
    @{
        Name = "Info"
        URL = "http://localhost:$Port/actuator/info"
        Weight = 10
        Technology = "ActuatorHealth"
        ExpectedLatency = 60
    }
)

# Calcular distribuição de requests
$RequestDistribution = @{}
$EndpointConfig | ForEach-Object {
    $RequestDistribution[$_.Name] = [math]::Floor($TotalMessages * ($_.Weight / 100))
    $TestResults.Metrics.ByEndpoint[$_.Name] = @{
        Success = 0
        Failed = 0
        Latencies = @()
        Technology = $_.Technology
        ExpectedLatency = $_.ExpectedLatency
    }
}

# Ajustar para total exato
$TotalDistributed = ($RequestDistribution.Values | Measure-Object -Sum).Sum
$Remaining = $TotalMessages - $TotalDistributed
$RequestDistribution["Stocks"] += $Remaining

Write-Host "   Distribuição de requests:" -ForegroundColor White
$RequestDistribution.GetEnumerator() | ForEach-Object {
    $percentage = [math]::Round(($_.Value / $TotalMessages) * 100, 1)
    Write-Host "      $($_.Key): $($_.Value) requests ($percentage%)" -ForegroundColor Gray
}

# === FASE 3: EXECUÇÃO DO TESTE DE CARGA ===
Write-Host "`n🚀 FASE 3: EXECUÇÃO DO TESTE - $TotalMessages MENSAGENS" -ForegroundColor Yellow

$TestStartTime = Get-Date
$RequestQueue = @()

# Criar fila de requests
foreach ($endpoint in $EndpointConfig) {
    $requestsForEndpoint = $RequestDistribution[$endpoint.Name]
    for ($i = 0; $i -lt $requestsForEndpoint; $i++) {
        $RequestQueue += @{
            Index = $RequestQueue.Count + 1
            Endpoint = $endpoint
            Status = "Pending"
        }
    }
}

# Embaralhar requests para simular carga real
$RequestQueue = $RequestQueue | Sort-Object {Get-Random}

Write-Host "   Iniciando execução com $ParallelThreads threads..." -ForegroundColor White

if ($AppAvailable) {
    # EXECUÇÃO REAL COM PARALELIZAÇÃO SIMULADA
    $CompletedRequests = 0
    $BatchSize = [math]::Max(1, [math]::Floor($TotalMessages / 20)) # 20 batches
    
    for ($batch = 0; $batch -lt $RequestQueue.Count; $batch += $BatchSize) {
        $batchEndIndex = [math]::Min($batch + $BatchSize - 1, $RequestQueue.Count - 1)
        $currentBatch = $RequestQueue[$batch..$batchEndIndex]
        
        Write-Host "      Executando batch $([math]::Floor($batch / $BatchSize) + 1)/20..." -ForegroundColor Gray
        
        foreach ($request in $currentBatch) {
            $requestStart = Get-Date
            $TestResults.Metrics.TotalRequests++
            
            try {
                # Simular delay entre requests para não sobrecarregar
                if ($CompletedRequests % $ParallelThreads -eq 0) {
                    Start-Sleep -Milliseconds 10
                }
                
                $response = Invoke-RestMethod -Uri $request.Endpoint.URL -TimeoutSec 15
                $requestEnd = Get-Date
                $latency = ($requestEnd - $requestStart).TotalMilliseconds
                
                # Atualizar métricas
                $TestResults.Metrics.SuccessfulRequests++
                $TestResults.Metrics.TotalLatency += $latency
                $TestResults.Metrics.MinLatency = [Math]::Min($TestResults.Metrics.MinLatency, $latency)
                $TestResults.Metrics.MaxLatency = [Math]::Max($TestResults.Metrics.MaxLatency, $latency)
                
                # Métricas por endpoint
                $endpointName = $request.Endpoint.Name
                $TestResults.Metrics.ByEndpoint[$endpointName].Success++
                $TestResults.Metrics.ByEndpoint[$endpointName].Latencies += $latency
                
                # Métricas por tecnologia
                $techName = $request.Endpoint.Technology
                $TestResults.TechnologyStack[$techName].ResponseTimes += $latency
                
                # Distribuição de latência
                $TestResults.Metrics.LatencyDistribution += @{
                    RequestId = $request.Index
                    Endpoint = $endpointName
                    Latency = $latency
                    Timestamp = $requestStart
                    Technology = $techName
                }
                
                # Identificar requests lentos (>1000ms)
                if ($latency -gt 1000) {
                    $TestResults.Metrics.SlowRequests += @{
                        RequestId = $request.Index
                        Endpoint = $endpointName
                        Latency = $latency
                        Technology = $techName
                        Timestamp = $requestStart
                    }
                }
                
            } catch {
                $TestResults.Metrics.FailedRequests++
                $TestResults.Metrics.ByEndpoint[$request.Endpoint.Name].Failed++
                $TestResults.TechnologyStack[$request.Endpoint.Technology].Errors++
                
                $errorType = $_.Exception.GetType().Name
                if ($TestResults.Metrics.ErrorsByType.ContainsKey($errorType)) {
                    $TestResults.Metrics.ErrorsByType[$errorType]++
                } else {
                    $TestResults.Metrics.ErrorsByType[$errorType] = 1
                }
            }
            
            $CompletedRequests++
        }
        
        # Progress report
        if ($batch % ($BatchSize * 5) -eq 0 -or $batchEndIndex -eq ($RequestQueue.Count - 1)) {
            $percentage = [math]::Round(($CompletedRequests / $TotalMessages) * 100, 1)
            $successRate = if ($CompletedRequests -gt 0) { 
                [math]::Round(($TestResults.Metrics.SuccessfulRequests / $CompletedRequests) * 100, 1) 
            } else { 0 }
            $avgLatency = if ($TestResults.Metrics.SuccessfulRequests -gt 0) {
                [math]::Round($TestResults.Metrics.TotalLatency / $TestResults.Metrics.SuccessfulRequests, 1)
            } else { 0 }
            
            Write-Host "      ✅ Progress: $CompletedRequests/$TotalMessages ($percentage%) | Sucesso: $successRate% | Latência média: ${avgLatency}ms" -ForegroundColor Green
        }
    }
} else {
    # SIMULAÇÃO AVANÇADA
    Write-Host "   Executando simulação avançada..." -ForegroundColor Blue
    
    foreach ($request in $RequestQueue) {
        $TestResults.Metrics.TotalRequests++
        
        # Simular latência baseada no tipo de endpoint
        $expectedLatency = $request.Endpoint.ExpectedLatency
        $simulatedLatency = $expectedLatency + (Get-Random -Minimum -20 -Maximum 50)
        $simulatedLatency = [Math]::Max(10, $simulatedLatency) # Mínimo 10ms
        
        # Simular 95% de sucesso
        if ((Get-Random -Minimum 1 -Maximum 100) -le 95) {
            $TestResults.Metrics.SuccessfulRequests++
            $TestResults.Metrics.TotalLatency += $simulatedLatency
            $TestResults.Metrics.MinLatency = [Math]::Min($TestResults.Metrics.MinLatency, $simulatedLatency)
            $TestResults.Metrics.MaxLatency = [Math]::Max($TestResults.Metrics.MaxLatency, $simulatedLatency)
            
            $endpointName = $request.Endpoint.Name
            $TestResults.Metrics.ByEndpoint[$endpointName].Success++
            $TestResults.Metrics.ByEndpoint[$endpointName].Latencies += $simulatedLatency
            
            $techName = $request.Endpoint.Technology
            $TestResults.TechnologyStack[$techName].ResponseTimes += $simulatedLatency
            
            $TestResults.Metrics.LatencyDistribution += @{
                RequestId = $request.Index
                Endpoint = $endpointName
                Latency = $simulatedLatency
                Timestamp = (Get-Date)
                Technology = $techName
            }
            
            # Simular alguns requests lentos
            if ((Get-Random -Minimum 1 -Maximum 100) -le 2) { # 2% de requests lentos
                $slowLatency = Get-Random -Minimum 1000 -Maximum 3000
                $TestResults.Metrics.SlowRequests += @{
                    RequestId = $request.Index
                    Endpoint = $endpointName
                    Latency = $slowLatency
                    Technology = $techName
                    Timestamp = (Get-Date)
                }
            }
        } else {
            $TestResults.Metrics.FailedRequests++
            $TestResults.Metrics.ByEndpoint[$request.Endpoint.Name].Failed++
            $TestResults.TechnologyStack[$request.Endpoint.Technology].Errors++
        }
        
        # Progress report para simulação
        if ($TestResults.Metrics.TotalRequests % 100 -eq 0) {
            $percentage = [math]::Round(($TestResults.Metrics.TotalRequests / $TotalMessages) * 100, 1)
            Write-Host "      🔵 [SIMULADO] Progress: $($TestResults.Metrics.TotalRequests)/$TotalMessages ($percentage%)" -ForegroundColor Blue
        }
        
        Start-Sleep -Milliseconds 5 # Simulação mais rápida
    }
}

$TestEndTime = Get-Date
$TestResults.EndTime = $TestEndTime
$TestResults.TotalDuration = ($TestEndTime - $TestStartTime).TotalSeconds

# === FASE 4: CÁLCULO DE MÉTRICAS AVANÇADAS ===
Write-Host "`n📊 FASE 4: ANÁLISE DE MÉTRICAS AVANÇADAS" -ForegroundColor Yellow

# Métricas gerais
$TestResults.Metrics.RequestsPerSecond = if ($TestResults.TotalDuration -gt 0) {
    [math]::Round($TotalMessages / $TestResults.TotalDuration, 2)
} else { 0 }

$TestResults.Metrics.AverageLatency = if ($TestResults.Metrics.SuccessfulRequests -gt 0) {
    [math]::Round($TestResults.Metrics.TotalLatency / $TestResults.Metrics.SuccessfulRequests, 2)
} else { 0 }

$TestResults.Metrics.SuccessRate = [math]::Round(($TestResults.Metrics.SuccessfulRequests / $TotalMessages) * 100, 2)

# Métricas por tecnologia
$TestResults.TechnologyStack.GetEnumerator() | ForEach-Object {
    $tech = $_.Value
    if ($tech.ResponseTimes.Count -gt 0) {
        $tech.AverageResponseTime = [math]::Round(($tech.ResponseTimes | Measure-Object -Average).Average, 2)
        $tech.MinResponseTime = [math]::Round(($tech.ResponseTimes | Measure-Object -Minimum).Minimum, 2)
        $tech.MaxResponseTime = [math]::Round(($tech.ResponseTimes | Measure-Object -Maximum).Maximum, 2)
        $tech.TotalRequests = $tech.ResponseTimes.Count
    }
}

# Percentis de latência
if ($TestResults.Metrics.LatencyDistribution.Count -gt 0) {
    $sortedLatencies = $TestResults.Metrics.LatencyDistribution | Sort-Object Latency
    $p50Index = [math]::Floor($sortedLatencies.Count * 0.5)
    $p90Index = [math]::Floor($sortedLatencies.Count * 0.9)
    $p95Index = [math]::Floor($sortedLatencies.Count * 0.95)
    $p99Index = [math]::Floor($sortedLatencies.Count * 0.99)
    
    $TestResults.Metrics.Percentiles = @{
        P50 = [math]::Round($sortedLatencies[$p50Index].Latency, 2)
        P90 = [math]::Round($sortedLatencies[$p90Index].Latency, 2) 
        P95 = [math]::Round($sortedLatencies[$p95Index].Latency, 2)
        P99 = [math]::Round($sortedLatencies[$p99Index].Latency, 2)
    }
}

Write-Host "   Métricas calculadas:" -ForegroundColor White
Write-Host "      Throughput: $($TestResults.Metrics.RequestsPerSecond) req/s" -ForegroundColor Cyan
Write-Host "      Latência média: $($TestResults.Metrics.AverageLatency)ms" -ForegroundColor Cyan
Write-Host "      Taxa de sucesso: $($TestResults.Metrics.SuccessRate)%" -ForegroundColor Cyan
Write-Host "      Requests lentos: $($TestResults.Metrics.SlowRequests.Count)" -ForegroundColor Yellow

# === FASE 5: GERAÇÃO DE RELATÓRIOS ===
if ($GenerateReport) {
    Write-Host "`n📄 FASE 5: GERAÇÃO DE RELATÓRIOS" -ForegroundColor Yellow
    
    # Relatório JSON completo
    $jsonFile = Join-Path $OutputDir "advanced-load-test-$ExecutionId.json"
    $TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
    
    # Relatório CSV de latências
    $csvFile = Join-Path $OutputDir "latencies-$ExecutionId.csv"
    $TestResults.Metrics.LatencyDistribution | Export-Csv -Path $csvFile -NoTypeInformation
    
    # Relatório de requests lentos
    $slowRequestsFile = Join-Path $OutputDir "slow-requests-$ExecutionId.json"
    $TestResults.Metrics.SlowRequests | ConvertTo-Json -Depth 5 | Out-File -FilePath $slowRequestsFile -Encoding UTF8
    
    Write-Host "   ✅ Relatórios salvos:" -ForegroundColor Green
    Write-Host "      JSON: $jsonFile" -ForegroundColor Gray
    Write-Host "      CSV: $csvFile" -ForegroundColor Gray
    Write-Host "      Slow requests: $slowRequestsFile" -ForegroundColor Gray
}

# === RELATÓRIO FINAL ===
Write-Host "`n=================================================================" -ForegroundColor Magenta
Write-Host "              RELATÓRIO FINAL - TESTE DE $TotalMessages MENSAGENS" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

Write-Host "`n🎯 RESUMO EXECUTIVO:" -ForegroundColor White
Write-Host "   Execution ID: $ExecutionId" -ForegroundColor Gray
Write-Host "   Modo: $(if ($AppAvailable) {'REAL'} else {'SIMULAÇÃO'})" -ForegroundColor Gray
Write-Host "   Duração total: $([math]::Round($TestResults.TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Total de mensagens: $TotalMessages" -ForegroundColor White

Write-Host "`n📊 PERFORMANCE:" -ForegroundColor White
Write-Host "   Throughput: $($TestResults.Metrics.RequestsPerSecond) req/s" -ForegroundColor Cyan
Write-Host "   Taxa de sucesso: $($TestResults.Metrics.SuccessRate)%" -ForegroundColor $(if ($TestResults.Metrics.SuccessRate -ge 95) {"Green"} else {"Yellow"})
Write-Host "   Latência média: $($TestResults.Metrics.AverageLatency)ms" -ForegroundColor Cyan
Write-Host "   Latência min/max: $([math]::Round($TestResults.Metrics.MinLatency, 2))ms / $([math]::Round($TestResults.Metrics.MaxLatency, 2))ms" -ForegroundColor White

if ($TestResults.Metrics.Percentiles) {
    Write-Host "`n📈 PERCENTIS DE LATÊNCIA:" -ForegroundColor White
    Write-Host "   P50 (Mediana): $($TestResults.Metrics.Percentiles.P50)ms" -ForegroundColor Cyan
    Write-Host "   P90: $($TestResults.Metrics.Percentiles.P90)ms" -ForegroundColor Cyan
    Write-Host "   P95: $($TestResults.Metrics.Percentiles.P95)ms" -ForegroundColor Yellow
    Write-Host "   P99: $($TestResults.Metrics.Percentiles.P99)ms" -ForegroundColor Red
}

Write-Host "`n🔧 POR TECNOLOGIA:" -ForegroundColor White
$TestResults.TechnologyStack.GetEnumerator() | ForEach-Object {
    $techName = $_.Key
    $tech = $_.Value
    if ($tech.TotalRequests -gt 0) {
        Write-Host "   $techName:" -ForegroundColor Cyan
        Write-Host "      Requests: $($tech.TotalRequests) | Erros: $($tech.Errors)" -ForegroundColor White
        Write-Host "      Latência média: $($tech.AverageResponseTime)ms" -ForegroundColor White
        Write-Host "      Min/Max: $($tech.MinResponseTime)ms / $($tech.MaxResponseTime)ms" -ForegroundColor Gray
    }
}

Write-Host "`n⚡ REQUESTS LENTOS (>1000ms):" -ForegroundColor Yellow
if ($TestResults.Metrics.SlowRequests.Count -gt 0) {
    Write-Host "   Total de requests lentos: $($TestResults.Metrics.SlowRequests.Count)" -ForegroundColor Red
    $TestResults.Metrics.SlowRequests | Sort-Object Latency -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "      Request #$($_.RequestId): $($_.Endpoint) - $([math]::Round($_.Latency, 0))ms [$($_.Technology)]" -ForegroundColor Red
    }
} else {
    Write-Host "   ✅ Nenhum request lento detectado!" -ForegroundColor Green
}

Write-Host "`n=================================================================" -ForegroundColor Magenta
Write-Host "                TESTE DE $TotalMessages MENSAGENS CONCLUÍDO" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

return $TestResults
