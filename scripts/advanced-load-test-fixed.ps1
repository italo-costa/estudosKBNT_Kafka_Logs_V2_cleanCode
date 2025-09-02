# ===================================================
# 🚀 ADVANCED LOAD TEST - TESTE AVANÇADO (1000+ MENSAGENS)
# ===================================================
# Versão melhorada do teste com análise detalhada por tecnologia
# e identificação de requests lentos

param(
    [int]$TotalMessages = 1000,
    [int]$ParallelThreads = 8,
    [int]$Port = 8080,
    [string]$TestType = "mixed",  # real, simulation, mixed
    [bool]$GenerateReport = $true
)

Write-Host "🚀 ADVANCED LOAD TEST - SISTEMA INTEGRADO" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "📋 CONFIGURAÇÃO:" -ForegroundColor White
Write-Host "   • Total de mensagens: $TotalMessages" -ForegroundColor Cyan
Write-Host "   • Threads paralelas: $ParallelThreads" -ForegroundColor Cyan
Write-Host "   • Porta de teste: $Port" -ForegroundColor Cyan
Write-Host "   • Tipo de teste: $TestType" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Green

# === INICIALIZAÇÃO DE ESTRUTURAS DE DADOS ===
$TestStartTime = Get-Date
$TestResults = @{
    StartTime = $TestStartTime
    EndTime = $null
    TotalDuration = 0
    Metrics = @{
        TotalRequests = 0
        SuccessfulRequests = 0
        FailedRequests = 0
        AverageLatency = 0
        MinLatency = 9999
        MaxLatency = 0
        TotalLatency = 0
        SlowRequests = @()
        Percentiles = @{}
        ByEndpoint = @{}
    }
    TechnologyStack = @{
        "Spring Boot" = @{
            TotalRequests = 0
            Errors = 0
            TotalResponseTime = 0
            MinResponseTime = 9999
            MaxResponseTime = 0
            AverageResponseTime = 0
        }
        "Actuator Health" = @{
            TotalRequests = 0
            Errors = 0
            TotalResponseTime = 0
            MinResponseTime = 9999
            MaxResponseTime = 0
            AverageResponseTime = 0
        }
        "REST API" = @{
            TotalRequests = 0
            Errors = 0
            TotalResponseTime = 0
            MinResponseTime = 9999
            MaxResponseTime = 0
            AverageResponseTime = 0
        }
        "Test Endpoint" = @{
            TotalRequests = 0
            Errors = 0
            TotalResponseTime = 0
            MinResponseTime = 9999
            MaxResponseTime = 0
            AverageResponseTime = 0
        }
    }
}

# === DEFINIÇÃO DOS ENDPOINTS ===
$Endpoints = @(
    @{ 
        Name = "health"
        Url = "http://localhost:$Port/actuator/health"
        Technology = "Actuator Health"
        Weight = 0.3
    },
    @{ 
        Name = "stocks"
        Url = "http://localhost:$Port/api/stocks/AAPL"
        Technology = "REST API"
        Weight = 0.4
    },
    @{ 
        Name = "test"
        Url = "http://localhost:$Port/test"
        Technology = "Test Endpoint"
        Weight = 0.2
    },
    @{ 
        Name = "info"
        Url = "http://localhost:$Port/actuator/info"
        Technology = "Spring Boot"
        Weight = 0.1
    }
)

# Inicializar métricas por endpoint
foreach ($endpoint in $Endpoints) {
    $TestResults.Metrics.ByEndpoint[$endpoint.Name] = @{
        Successful = 0
        Failed = 0
        TotalLatency = 0
        MinLatency = 9999
        MaxLatency = 0
    }
}

# === FUNÇÃO PARA CRIAR FILA DE REQUESTS ===
function Create-RequestQueue {
    param(
        [int]$TotalCount,
        [array]$EndpointList
    )
    
    $queue = @()
    for ($i = 0; $i -lt $TotalCount; $i++) {
        $random = Get-Random -Maximum 1.0
        $cumulative = 0
        
        foreach ($endpoint in $EndpointList) {
            $cumulative += $endpoint.Weight
            if ($random -le $cumulative) {
                $queue += @{
                    Id = $i + 1
                    Endpoint = $endpoint
                    Timestamp = Get-Date
                }
                break
            }
        }
    }
    return $queue
}

# === FUNÇÃO PARA FAZER REQUEST HTTP ===
function Invoke-LoadTestRequest {
    param(
        [hashtable]$Request
    )
    
    $result = @{
        Success = $false
        Latency = 0
        Error = $null
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Simular request baseado no tipo de teste
        if ($TestType -eq "real" -or ($TestType -eq "mixed" -and (Get-Random -Maximum 2) -eq 0)) {
            # Request real
            try {
                $response = Invoke-RestMethod -Uri $Request.Endpoint.Url -Method Get -TimeoutSec 30
                $result.Success = $true
            } catch {
                $result.Error = $_.Exception.Message
                $result.Success = $false
            }
        } else {
            # Simulação de request
            $simulatedDelay = switch ($Request.Endpoint.Name) {
                "health" { Get-Random -Minimum 20 -Maximum 80 }
                "stocks" { Get-Random -Minimum 50 -Maximum 200 }
                "test" { Get-Random -Minimum 30 -Maximum 120 }
                "info" { Get-Random -Minimum 15 -Maximum 60 }
                default { Get-Random -Minimum 40 -Maximum 100 }
            }
            
            Start-Sleep -Milliseconds $simulatedDelay
            $result.Success = (Get-Random -Maximum 100) -lt 95 # 95% de sucesso
        }
        
        $stopwatch.Stop()
        $result.Latency = $stopwatch.ElapsedMilliseconds
        
    } catch {
        $result.Error = $_.Exception.Message
        $result.Latency = 0
        $result.Success = $false
    }
    
    return $result
}

# === FASE 1: VERIFICAÇÃO DO AMBIENTE ===
Write-Host "`n🔍 FASE 1: VERIFICAÇÃO DO AMBIENTE" -ForegroundColor Yellow

try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 5
    Write-Host "   ✅ Aplicação Spring Boot está rodando" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Aplicação não detectada - usando apenas simulação" -ForegroundColor Yellow
    $TestType = "simulation"
}

# === FASE 2: CRIAÇÃO DA FILA DE REQUESTS ===
Write-Host "`n📋 FASE 2: PREPARAÇÃO DOS REQUESTS" -ForegroundColor Yellow

$RequestQueue = Create-RequestQueue -TotalCount $TotalMessages -EndpointList $Endpoints

Write-Host "   📊 Distribuição de requests:" -ForegroundColor Cyan
$Endpoints | ForEach-Object {
    $count = ($RequestQueue | Where-Object { $_.Endpoint.Name -eq $_.Name }).Count
    $percentage = [math]::Round(($count / $TotalMessages) * 100, 1)
    Write-Host "      $($_.Name): $count requests ($percentage%)" -ForegroundColor White
}

# === FASE 3: EXECUÇÃO DO TESTE ===
Write-Host "`n🚀 FASE 3: EXECUÇÃO DO TESTE DE CARGA" -ForegroundColor Yellow
Write-Host "   Iniciando teste com $ParallelThreads threads paralelas..." -ForegroundColor Cyan

$AllLatencies = @()

if ($ParallelThreads -gt 1) {
    # Processamento paralelo
    $batchSize = [math]::Ceiling($RequestQueue.Count / $ParallelThreads)
    $batches = @()
    
    for ($i = 0; $i -lt $RequestQueue.Count; $i += $batchSize) {
        $end = [math]::Min($i + $batchSize - 1, $RequestQueue.Count - 1)
        $batches += ,($RequestQueue[$i..$end])
    }
    
    $jobs = @()
    foreach ($batch in $batches) {
        $job = Start-Job -ScriptBlock {
            param($batch, $endpoints, $testType, $port)
            
            $results = @()
            foreach ($request in $batch) {
                # Lógica similar à função Invoke-LoadTestRequest mas inline para o job
                $result = @{
                    RequestId = $request.Id
                    Success = $false
                    Latency = 0
                    Endpoint = $request.Endpoint.Name
                    Technology = $request.Endpoint.Technology
                }
                
                try {
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    
                    if ($testType -eq "real") {
                        try {
                            $response = Invoke-RestMethod -Uri $request.Endpoint.Url -Method Get -TimeoutSec 10
                            $result.Success = $true
                        } catch {
                            $result.Success = $false
                        }
                    } else {
                        # Simulação
                        $simulatedDelay = switch ($request.Endpoint.Name) {
                            "health" { Get-Random -Minimum 20 -Maximum 80 }
                            "stocks" { Get-Random -Minimum 50 -Maximum 200 }
                            "test" { Get-Random -Minimum 30 -Maximum 120 }
                            "info" { Get-Random -Minimum 15 -Maximum 60 }
                            default { Get-Random -Minimum 40 -Maximum 100 }
                        }
                        
                        Start-Sleep -Milliseconds $simulatedDelay
                        $result.Success = (Get-Random -Maximum 100) -lt 95
                    }
                    
                    $stopwatch.Stop()
                    $result.Latency = $stopwatch.ElapsedMilliseconds
                    
                } catch {
                    $result.Latency = 0
                    $result.Success = $false
                }
                
                $results += $result
            }
            return $results
        } -ArgumentList $batch, $Endpoints, $TestType, $Port
        
        $jobs += $job
    }
    
    # Aguardar completion dos jobs
    $allResults = @()
    $completed = 0
    
    while ($completed -lt $jobs.Count) {
        foreach ($job in $jobs) {
            if ($job.State -eq "Completed" -and $job.Id -notin $processedJobs) {
                $jobResults = Receive-Job -Job $job
                $allResults += $jobResults
                $completed++
                Remove-Job -Job $job
                
                Write-Host "      ✅ Batch processado: $completed/$($jobs.Count)" -ForegroundColor Green
            }
        }
        Start-Sleep -Milliseconds 100
    }
} else {
    # Processamento sequencial para debugging
    Write-Host "   🔄 Processamento sequencial..." -ForegroundColor Cyan
    $allResults = @()
    
    foreach ($request in $RequestQueue) {
        $result = Invoke-LoadTestRequest -Request $request
        
        $resultObj = @{
            RequestId = $request.Id
            Success = $result.Success
            Latency = $result.Latency
            Endpoint = $request.Endpoint.Name
            Technology = $request.Endpoint.Technology
        }
        
        $allResults += $resultObj
        
        # Progress report
        if ($request.Id % 100 -eq 0) {
            $percentage = [math]::Round(($request.Id / $TotalMessages) * 100, 1)
            Write-Host "      🔄 Progress: $($request.Id)/$TotalMessages ($percentage%)" -ForegroundColor Blue
        }
    }
}

# === FASE 4: PROCESSAMENTO DOS RESULTADOS ===
Write-Host "`n📊 FASE 4: ANÁLISE DOS RESULTADOS" -ForegroundColor Yellow

foreach ($result in $allResults) {
    $TestResults.Metrics.TotalRequests++
    
    if ($result.Success) {
        $TestResults.Metrics.SuccessfulRequests++
        $TestResults.Metrics.ByEndpoint[$result.Endpoint].Successful++
        
        # Estatísticas de latência
        $latency = [double]$result.Latency
        $AllLatencies += $latency
        
        $TestResults.Metrics.TotalLatency += $latency
        $TestResults.Metrics.ByEndpoint[$result.Endpoint].TotalLatency += $latency
        
        if ($latency -lt $TestResults.Metrics.MinLatency) {
            $TestResults.Metrics.MinLatency = $latency
        }
        
        if ($latency -gt $TestResults.Metrics.MaxLatency) {
            $TestResults.Metrics.MaxLatency = $latency
        }
        
        # Estatísticas por tecnologia
        $tech = $TestResults.TechnologyStack[$result.Technology]
        $tech.TotalRequests++
        $tech.TotalResponseTime += $latency
        
        if ($latency -lt $tech.MinResponseTime) {
            $tech.MinResponseTime = $latency
        }
        if ($latency -gt $tech.MaxResponseTime) {
            $tech.MaxResponseTime = $latency
        }
        
        # Detectar requests lentos (> 1000ms)
        if ($latency -gt 1000) {
            $TestResults.Metrics.SlowRequests += @{
                RequestId = $result.RequestId
                Endpoint = $result.Endpoint
                Technology = $result.Technology
                Latency = $latency
            }
        }
        
    } else {
        $TestResults.Metrics.FailedRequests++
        $TestResults.Metrics.ByEndpoint[$result.Endpoint].Failed++
        $TestResults.TechnologyStack[$result.Technology].Errors++
    }
}

$TestEndTime = Get-Date
$TestResults.EndTime = $TestEndTime
$TestResults.TotalDuration = ($TestEndTime - $TestStartTime).TotalSeconds

# Calcular métricas finais
if ($TestResults.Metrics.SuccessfulRequests -gt 0) {
    $TestResults.Metrics.AverageLatency = $TestResults.Metrics.TotalLatency / $TestResults.Metrics.SuccessfulRequests
    
    # Calcular percentis
    $sortedLatencies = $AllLatencies | Sort-Object
    if ($sortedLatencies.Count -gt 0) {
        $TestResults.Metrics.Percentiles = @{
            P50 = [math]::Round($sortedLatencies[[math]::Floor($sortedLatencies.Count * 0.5)], 2)
            P90 = [math]::Round($sortedLatencies[[math]::Floor($sortedLatencies.Count * 0.9)], 2)
            P95 = [math]::Round($sortedLatencies[[math]::Floor($sortedLatencies.Count * 0.95)], 2)
            P99 = [math]::Round($sortedLatencies[[math]::Floor($sortedLatencies.Count * 0.99)], 2)
        }
    }
}

# Calcular médias por tecnologia
foreach ($tech in $TestResults.TechnologyStack.GetEnumerator()) {
    if ($tech.Value.TotalRequests -gt 0) {
        $tech.Value.AverageResponseTime = [math]::Round($tech.Value.TotalResponseTime / $tech.Value.TotalRequests, 2)
    }
}

# === RELATÓRIO FINAL ===
Write-Host "`n🎯 RELATÓRIO FINAL DO TESTE AVANÇADO" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$throughput = [math]::Round($TestResults.Metrics.TotalRequests / $TestResults.TotalDuration, 2)
$successRate = [math]::Round(($TestResults.Metrics.SuccessfulRequests / $TestResults.Metrics.TotalRequests) * 100, 2)

Write-Host "`n📈 MÉTRICAS PRINCIPAIS:" -ForegroundColor White
Write-Host "   Total de requests: $($TestResults.Metrics.TotalRequests)" -ForegroundColor Cyan
Write-Host "   Requests bem-sucedidos: $($TestResults.Metrics.SuccessfulRequests)" -ForegroundColor Green
Write-Host "   Requests falharam: $($TestResults.Metrics.FailedRequests)" -ForegroundColor Red
Write-Host "   Taxa de sucesso: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } else { "Yellow" })
Write-Host "   Throughput: $throughput req/s" -ForegroundColor Cyan
Write-Host "   Duração total: $([math]::Round($TestResults.TotalDuration, 2))s" -ForegroundColor White

Write-Host "`n⏱️ LATÊNCIA:" -ForegroundColor White
Write-Host "   Mínima: $([math]::Round($TestResults.Metrics.MinLatency, 2))ms" -ForegroundColor Green
Write-Host "   Máxima: $([math]::Round($TestResults.Metrics.MaxLatency, 2))ms" -ForegroundColor Red
Write-Host "   Média: $([math]::Round($TestResults.Metrics.AverageLatency, 2))ms" -ForegroundColor Cyan

if ($TestResults.Metrics.Percentiles.Count -gt 0) {
    Write-Host "`n📊 PERCENTIS DE LATÊNCIA:" -ForegroundColor White
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
        Write-Host "   ${techName}:" -ForegroundColor Cyan
        Write-Host "      Requests: $($tech.TotalRequests) | Erros: $($tech.Errors)" -ForegroundColor White
        Write-Host "      Latência média: $($tech.AverageResponseTime)ms" -ForegroundColor White
        Write-Host "      Min/Max: $($tech.MinResponseTime)ms / $($tech.MaxResponseTime)ms" -ForegroundColor Gray
    }
}

Write-Host "`n🐌 REQUESTS LENTOS (>1000ms):" -ForegroundColor Yellow
if ($TestResults.Metrics.SlowRequests.Count -gt 0) {
    Write-Host "   Total de requests lentos: $($TestResults.Metrics.SlowRequests.Count)" -ForegroundColor Red
    $TestResults.Metrics.SlowRequests | Sort-Object Latency -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "      Request #$($_.RequestId): $($_.Endpoint) - $([math]::Round($_.Latency, 0))ms [$($_.Technology)]" -ForegroundColor Red
    }
} else {
    Write-Host "   ✅ Nenhum request lento detectado!" -ForegroundColor Green
}

# === GERAÇÃO DO RELATÓRIO JSON ===
if ($GenerateReport) {
    Write-Host "`n💾 GERANDO RELATÓRIO JSON..." -ForegroundColor Yellow
    
    $reportData = @{
        TestConfiguration = @{
            TotalMessages = $TotalMessages
            ParallelThreads = $ParallelThreads
            Port = $Port
            TestType = $TestType
        }
        Results = $TestResults
        GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $reportJson = $reportData | ConvertTo-Json -Depth 10
    $reportPath = "dashboard\data\advanced-test-results-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"
    
    if (-not (Test-Path "dashboard\data")) {
        New-Item -Path "dashboard\data" -ItemType Directory -Force | Out-Null
    }
    
    $reportJson | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "   📄 Relatório salvo em: $reportPath" -ForegroundColor Green
}

# === ANÁLISE DE QUALIDADE ===
$qualityScore = 0
if ($successRate -ge 95) { $qualityScore += 30 }
elseif ($successRate -ge 90) { $qualityScore += 20 }
elseif ($successRate -ge 80) { $qualityScore += 10 }

if ($throughput -ge 30) { $qualityScore += 25 }
elseif ($throughput -ge 20) { $qualityScore += 20 }
elseif ($throughput -ge 10) { $qualityScore += 15 }

if ($TestResults.Metrics.AverageLatency -le 100) { $qualityScore += 25 }
elseif ($TestResults.Metrics.AverageLatency -le 200) { $qualityScore += 20 }
elseif ($TestResults.Metrics.AverageLatency -le 500) { $qualityScore += 15 }

if ($TestResults.Metrics.SlowRequests.Count -eq 0) { $qualityScore += 20 }
elseif ($TestResults.Metrics.SlowRequests.Count -le 5) { $qualityScore += 15 }

Write-Host "`n🏆 PONTUAÇÃO DE QUALIDADE: $qualityScore/100" -ForegroundColor $(
    if ($qualityScore -ge 90) { "Green" }
    elseif ($qualityScore -ge 70) { "Yellow" }
    else { "Red" }
)

Write-Host "`n✅ TESTE AVANÇADO FINALIZADO!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
