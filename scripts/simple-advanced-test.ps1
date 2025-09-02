# ===================================================
# 🚀 TESTE AVANÇADO - 1200 MENSAGENS
# ===================================================

param(
    [int]$TotalMessages = 1200,
    [int]$ParallelThreads = 6,
    [int]$Port = 8080
)

Write-Host "🚀 ADVANCED LOAD TEST - SISTEMA INTEGRADO" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$TestStartTime = Get-Date
$AllLatencies = @()
$Results = @{
    TotalRequests = 0
    SuccessfulRequests = 0
    FailedRequests = 0
    SlowRequests = @()
    TechnologyStats = @{
        "Spring Boot" = @{ Requests = 0; TotalTime = 0; Errors = 0 }
        "Actuator Health" = @{ Requests = 0; TotalTime = 0; Errors = 0 }
        "REST API" = @{ Requests = 0; TotalTime = 0; Errors = 0 }
        "Test Endpoint" = @{ Requests = 0; TotalTime = 0; Errors = 0 }
    }
}

# Verificar se aplicação está rodando
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 3
    Write-Host "   ✅ Aplicação Spring Boot detectada" -ForegroundColor Green
    $UseRealRequests = $true
} catch {
    Write-Host "   ⚠️  Aplicação não detectada - usando simulação" -ForegroundColor Yellow  
    $UseRealRequests = $false
}

# Definir endpoints
$Endpoints = @(
    @{ Name = "health"; Url = "http://localhost:$Port/actuator/health"; Tech = "Actuator Health"; Weight = 0.3 }
    @{ Name = "stocks"; Url = "http://localhost:$Port/api/stocks/AAPL"; Tech = "REST API"; Weight = 0.4 }  
    @{ Name = "test"; Url = "http://localhost:$Port/test"; Tech = "Test Endpoint"; Weight = 0.2 }
    @{ Name = "info"; Url = "http://localhost:$Port/actuator/info"; Tech = "Spring Boot"; Weight = 0.1 }
)

Write-Host "`n🚀 Iniciando teste com $TotalMessages mensagens usando $ParallelThreads threads..." -ForegroundColor Cyan

# Função para simular request
function Test-Request {
    param($RequestId, $Endpoint)
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    
    try {
        if ($UseRealRequests) {
            $response = Invoke-RestMethod -Uri $Endpoint.Url -Method Get -TimeoutSec 10
            $success = $true
        } else {
            # Simulação baseada no tipo de endpoint
            $delay = switch ($Endpoint.Name) {
                "health" { Get-Random -Minimum 25 -Maximum 80 }
                "stocks" { Get-Random -Minimum 60 -Maximum 180 }
                "test" { Get-Random -Minimum 40 -Maximum 120 }
                "info" { Get-Random -Minimum 20 -Maximum 65 }
                default { Get-Random -Minimum 50 -Maximum 100 }
            }
            
            Start-Sleep -Milliseconds $delay
            $success = (Get-Random -Maximum 100) -lt 95  # 95% de sucesso
        }
    } catch {
        $success = $false
    }
    
    $stopwatch.Stop()
    $latency = $stopwatch.ElapsedMilliseconds
    
    return @{
        RequestId = $RequestId
        Success = $success
        Latency = $latency
        Endpoint = $Endpoint.Name
        Technology = $Endpoint.Tech
    }
}

# Executar teste
$processedRequests = 0
$batchSize = [math]::Ceiling($TotalMessages / 10)

for ($batch = 0; $batch -lt 10; $batch++) {
    $startIdx = $batch * $batchSize
    $endIdx = [math]::Min($startIdx + $batchSize - 1, $TotalMessages - 1)
    $batchCount = $endIdx - $startIdx + 1
    
    Write-Host "   📦 Processando batch $($batch + 1)/10 ($batchCount requests)..." -ForegroundColor Blue
    
    $batchResults = @()
    
    for ($i = $startIdx; $i -le $endIdx; $i++) {
        # Selecionar endpoint baseado no peso
        $random = Get-Random -Maximum 1.0
        $cumulative = 0
        $selectedEndpoint = $Endpoints[0]
        
        foreach ($endpoint in $Endpoints) {
            $cumulative += $endpoint.Weight
            if ($random -le $cumulative) {
                $selectedEndpoint = $endpoint
                break
            }
        }
        
        $result = Test-Request -RequestId ($i + 1) -Endpoint $selectedEndpoint
        $batchResults += $result
        
        $processedRequests++
    }
    
    # Processar resultados do batch
    foreach ($result in $batchResults) {
        $Results.TotalRequests++
        
        if ($result.Success) {
            $Results.SuccessfulRequests++
            $AllLatencies += [double]$result.Latency
            
            # Atualizar stats por tecnologia
            $techStats = $Results.TechnologyStats[$result.Technology]
            $techStats.Requests++
            $techStats.TotalTime += $result.Latency
            
            # Detectar requests lentos (>1000ms)
            if ($result.Latency -gt 1000) {
                $Results.SlowRequests += @{
                    Id = $result.RequestId
                    Endpoint = $result.Endpoint
                    Technology = $result.Technology
                    Latency = $result.Latency
                }
            }
        } else {
            $Results.FailedRequests++
            $Results.TechnologyStats[$result.Technology].Errors++
        }
    }
    
    $progress = [math]::Round(($processedRequests / $TotalMessages) * 100, 1)
    Write-Host "      ✅ Batch concluído - Progress: $processedRequests/$TotalMessages ($progress%)" -ForegroundColor Green
    
    Start-Sleep -Milliseconds 200  # Pausa entre batches
}

$TestEndTime = Get-Date
$TotalDuration = ($TestEndTime - $TestStartTime).TotalSeconds

# Calcular métricas finais
$throughput = [math]::Round($Results.TotalRequests / $TotalDuration, 2)
$successRate = [math]::Round(($Results.SuccessfulRequests / $Results.TotalRequests) * 100, 2)

$avgLatency = 0
$minLatency = 0
$maxLatency = 0
$p95Latency = 0
$p99Latency = 0

if ($AllLatencies.Count -gt 0) {
    $avgLatency = [math]::Round(($AllLatencies | Measure-Object -Average).Average, 2)
    $minLatency = [math]::Round(($AllLatencies | Measure-Object -Minimum).Minimum, 2)
    $maxLatency = [math]::Round(($AllLatencies | Measure-Object -Maximum).Maximum, 2)
    
    $sortedLatencies = $AllLatencies | Sort-Object
    $p95Index = [math]::Floor($sortedLatencies.Count * 0.95)
    $p99Index = [math]::Floor($sortedLatencies.Count * 0.99)
    $p95Latency = [math]::Round($sortedLatencies[$p95Index], 2)
    $p99Latency = [math]::Round($sortedLatencies[$p99Index], 2)
}

# Relatório Final
Write-Host "`n🎯 RELATÓRIO FINAL DO TESTE AVANÇADO" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`n📈 MÉTRICAS PRINCIPAIS:" -ForegroundColor White
Write-Host "   Total de requests: $($Results.TotalRequests)" -ForegroundColor Cyan
Write-Host "   Requests bem-sucedidos: $($Results.SuccessfulRequests)" -ForegroundColor Green
Write-Host "   Requests falharam: $($Results.FailedRequests)" -ForegroundColor Red
Write-Host "   Taxa de sucesso: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } else { "Yellow" })
Write-Host "   Throughput: $throughput req/s" -ForegroundColor Cyan
Write-Host "   Duração total: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White

Write-Host "`n⏱️ LATÊNCIA:" -ForegroundColor White
Write-Host "   Mínima: ${minLatency}ms" -ForegroundColor Green
Write-Host "   Máxima: ${maxLatency}ms" -ForegroundColor Red
Write-Host "   Média: ${avgLatency}ms" -ForegroundColor Cyan
Write-Host "   P95: ${p95Latency}ms" -ForegroundColor Yellow
Write-Host "   P99: ${p99Latency}ms" -ForegroundColor Red

Write-Host "`n🔧 POR TECNOLOGIA:" -ForegroundColor White
$Results.TechnologyStats.GetEnumerator() | ForEach-Object {
    $techName = $_.Key
    $stats = $_.Value
    if ($stats.Requests -gt 0) {
        $avgTime = [math]::Round($stats.TotalTime / $stats.Requests, 2)
        Write-Host "   ${techName}:" -ForegroundColor Cyan
        Write-Host "      Requests: $($stats.Requests) | Erros: $($stats.Errors)" -ForegroundColor White
        Write-Host "      Latência média: ${avgTime}ms" -ForegroundColor White
    }
}

Write-Host "`n🐌 REQUESTS LENTOS (>1000ms):" -ForegroundColor Yellow
if ($Results.SlowRequests.Count -gt 0) {
    Write-Host "   Total de requests lentos: $($Results.SlowRequests.Count)" -ForegroundColor Red
    $Results.SlowRequests | Sort-Object Latency -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "      Request #$($_.Id): $($_.Endpoint) - $([math]::Round($_.Latency, 0))ms [$($_.Technology)]" -ForegroundColor Red
    }
} else {
    Write-Host "   ✅ Nenhum request lento detectado!" -ForegroundColor Green
}

# Gerar JSON para dashboard
$reportData = @{
    TestConfiguration = @{
        TotalMessages = $TotalMessages
        ParallelThreads = $ParallelThreads
        Port = $Port
        TestType = if ($UseRealRequests) { "real" } else { "simulation" }
    }
    Metrics = @{
        TotalRequests = $Results.TotalRequests
        SuccessfulRequests = $Results.SuccessfulRequests
        FailedRequests = $Results.FailedRequests
        SuccessRate = $successRate
        Throughput = $throughput
        TotalDuration = $TotalDuration
        Latency = @{
            Average = $avgLatency
            Minimum = $minLatency
            Maximum = $maxLatency
            P95 = $p95Latency
            P99 = $p99Latency
        }
        SlowRequestsCount = $Results.SlowRequests.Count
        SlowRequests = $Results.SlowRequests
        TechnologyStack = $Results.TechnologyStats
    }
    GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    TestStartTime = $TestStartTime.ToString("yyyy-MM-dd HH:mm:ss")
    TestEndTime = $TestEndTime.ToString("yyyy-MM-dd HH:mm:ss")
}

# Salvar relatório
if (-not (Test-Path "dashboard\data")) {
    New-Item -Path "dashboard\data" -ItemType Directory -Force | Out-Null
}

$reportJson = $reportData | ConvertTo-Json -Depth 10
$reportPath = "dashboard\data\advanced-test-results-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"
$reportJson | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n💾 Relatório salvo em: $reportPath" -ForegroundColor Green

# Calcular pontuação de qualidade
$qualityScore = 0
if ($successRate -ge 95) { $qualityScore += 30 }
elseif ($successRate -ge 90) { $qualityScore += 25 }
elseif ($successRate -ge 80) { $qualityScore += 15 }

if ($throughput -ge 25) { $qualityScore += 25 }
elseif ($throughput -ge 15) { $qualityScore += 20 }
elseif ($throughput -ge 8) { $qualityScore += 15 }

if ($avgLatency -le 100) { $qualityScore += 25 }
elseif ($avgLatency -le 200) { $qualityScore += 20 }
elseif ($avgLatency -le 500) { $qualityScore += 15 }

if ($Results.SlowRequests.Count -eq 0) { $qualityScore += 20 }
elseif ($Results.SlowRequests.Count -le 3) { $qualityScore += 15 }

Write-Host "`n🏆 PONTUAÇÃO DE QUALIDADE: $qualityScore/100" -ForegroundColor $(
    if ($qualityScore -ge 90) { "Green" }
    elseif ($qualityScore -ge 70) { "Yellow" }
    else { "Red" }
)

Write-Host "`n✅ TESTE AVANÇADO FINALIZADO!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
