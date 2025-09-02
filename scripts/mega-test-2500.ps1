# MEGA TEST - 2500 mensagens com análise detalhada
param(
    [int]$TotalMessages = 2500,
    [int]$Port = 8080
)

Write-Host "MEGA LOAD TEST - 2500 MENSAGENS" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta

$TestStartTime = Get-Date
$Results = @{
    TotalRequests = 0
    SuccessfulRequests = 0
    FailedRequests = 0
    AllLatencies = @()
    SlowRequests = @()
    RequestsByMinute = @()
    TechStats = @{
        "Spring Boot Info" = @{ Count = 0; TotalTime = 0; Errors = 0; MinTime = 999; MaxTime = 0 }
        "Actuator Health" = @{ Count = 0; TotalTime = 0; Errors = 0; MinTime = 999; MaxTime = 0 }
        "REST API Stocks" = @{ Count = 0; TotalTime = 0; Errors = 0; MinTime = 999; MaxTime = 0 }
        "Test Endpoint" = @{ Count = 0; TotalTime = 0; Errors = 0; MinTime = 999; MaxTime = 0 }
    }
    Timeline = @()
}

# Verificar aplicacao
Write-Host "Verificando aplicacao na porta $Port..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 5
    Write-Host "✅ Aplicacao Spring Boot ativa - Status: $($health.status)" -ForegroundColor Green
    $UseReal = $true
} catch {
    Write-Host "⚠️ Aplicacao nao detectada - modo simulacao ativado" -ForegroundColor Yellow  
    $UseReal = $false
}

# Endpoints com pesos diferenciados
$Endpoints = @(
    @{ Name = "health"; Url = "http://localhost:$Port/actuator/health"; Tech = "Actuator Health"; Weight = 35; Priority = "HIGH" }
    @{ Name = "stocks"; Url = "http://localhost:$Port/api/stocks/AAPL"; Tech = "REST API Stocks"; Weight = 30; Priority = "CRITICAL" }  
    @{ Name = "test"; Url = "http://localhost:$Port/test"; Tech = "Test Endpoint"; Weight = 25; Priority = "MEDIUM" }
    @{ Name = "info"; Url = "http://localhost:$Port/actuator/info"; Tech = "Spring Boot Info"; Weight = 10; Priority = "LOW" }
)

Write-Host "`nDistribuicao planejada:" -ForegroundColor White
$Endpoints | ForEach-Object {
    $expectedCount = [math]::Round($TotalMessages * ($_.Weight / 100))
    Write-Host "  $($_.Name): $expectedCount requests ($($_.Weight)%) - Priority: $($_.Priority)" -ForegroundColor Cyan
}

Write-Host "`nIniciando MEGA TEST com $TotalMessages requests..." -ForegroundColor Magenta
$startTime = Get-Date

# Loop principal com medição de tempo mais precisa
for ($i = 1; $i -le $TotalMessages; $i++) {
    $requestStart = Get-Date
    
    # Selecionar endpoint baseado em peso
    $random = Get-Random -Maximum 100
    $selectedEndpoint = $Endpoints[0]
    
    $cumulative = 0
    foreach ($endpoint in $Endpoints) {
        $cumulative += $endpoint.Weight
        if ($random -le $cumulative) {
            $selectedEndpoint = $endpoint
            break
        }
    }
    
    # Executar request com medição precisa
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    $errorMsg = ""
    
    try {
        if ($UseReal) {
            $response = Invoke-RestMethod -Uri $selectedEndpoint.Url -Method Get -TimeoutSec 8
            $success = $true
        } else {
            # Simulacao baseada no endpoint e prioridade
            $baseDelay = switch ($selectedEndpoint.Name) {
                "health" { Get-Random -Minimum 15 -Maximum 50 }
                "stocks" { Get-Random -Minimum 45 -Maximum 120 }
                "test" { Get-Random -Minimum 25 -Maximum 80 }
                "info" { Get-Random -Minimum 10 -Maximum 40 }
            }
            
            # Adicionar variação baseada na carga (requests já processados)
            $loadFactor = 1 + ($i / $TotalMessages) * 0.3  # Até 30% mais lento conforme a carga
            $adjustedDelay = [math]::Round($baseDelay * $loadFactor)
            
            Start-Sleep -Milliseconds $adjustedDelay
            
            # Taxa de sucesso varia por prioridade
            $successRate = switch ($selectedEndpoint.Priority) {
                "CRITICAL" { 92 }
                "HIGH" { 96 }
                "MEDIUM" { 94 }
                "LOW" { 98 }
            }
            
            $success = (Get-Random -Maximum 100) -lt $successRate
        }
    } catch {
        $success = $false
        $errorMsg = $_.Exception.Message
    }
    
    $stopwatch.Stop()
    $latency = $stopwatch.ElapsedMilliseconds
    $requestEnd = Get-Date
    
    # Processar resultado
    $Results.TotalRequests++
    
    # Adicionar à timeline
    $Results.Timeline += @{
        RequestId = $i
        Timestamp = $requestEnd
        Endpoint = $selectedEndpoint.Name
        Technology = $selectedEndpoint.Tech
        Latency = $latency
        Success = $success
        Priority = $selectedEndpoint.Priority
    }
    
    if ($success) {
        $Results.SuccessfulRequests++
        $Results.AllLatencies += $latency
        
        # Atualizar estatísticas por tecnologia
        $techStats = $Results.TechStats[$selectedEndpoint.Tech]
        $techStats.Count++
        $techStats.TotalTime += $latency
        
        if ($latency -lt $techStats.MinTime) { $techStats.MinTime = $latency }
        if ($latency -gt $techStats.MaxTime) { $techStats.MaxTime = $latency }
        
        # Detectar requests lentos
        if ($latency -gt 500) {  # Lowered threshold for more detection
            $Results.SlowRequests += @{
                Id = $i
                Endpoint = $selectedEndpoint.Name
                Tech = $selectedEndpoint.Tech
                Priority = $selectedEndpoint.Priority
                Latency = $latency
                Timestamp = $requestEnd
            }
        }
    } else {
        $Results.FailedRequests++
        $Results.TechStats[$selectedEndpoint.Tech].Errors++
    }
    
    # Progress report detalhado
    if ($i % 250 -eq 0) {
        $elapsed = (Get-Date) - $startTime
        $currentRate = $i / $elapsed.TotalSeconds
        $pct = [math]::Round(($i / $TotalMessages) * 100, 1)
        $eta = if ($currentRate -gt 0) { 
            $remaining = ($TotalMessages - $i) / $currentRate
            [math]::Round($remaining, 0)
        } else { 0 }
        
        Write-Host "Progress: $i/$TotalMessages ($pct pct) | Rate: $([math]::Round($currentRate, 1)) req/s | ETA: ${eta}s" -ForegroundColor Green
    }
    
    # Pequena pausa para simular condições reais
    if ($i % 50 -eq 0) {
        Start-Sleep -Milliseconds 10
    }
}

$TestEndTime = Get-Date
$TotalDuration = ($TestEndTime - $TestStartTime).TotalSeconds

# === ANÁLISE AVANÇADA DOS RESULTADOS ===
Write-Host "`n🎯 ANÁLISE AVANÇADA DOS RESULTADOS" -ForegroundColor Magenta
Write-Host "===================================" -ForegroundColor Magenta

# Métricas básicas
$throughput = [math]::Round($Results.TotalRequests / $TotalDuration, 2)
$successRate = [math]::Round(($Results.SuccessfulRequests / $Results.TotalRequests) * 100, 2)

# Análise de latência
$avgLatency = 0
$medianLatency = 0
$p95Latency = 0
$p99Latency = 0
$minLatency = 0
$maxLatency = 0

if ($Results.AllLatencies.Count -gt 0) {
    $stats = $Results.AllLatencies | Measure-Object -Average -Minimum -Maximum
    $avgLatency = [math]::Round($stats.Average, 2)
    $minLatency = $stats.Minimum
    $maxLatency = $stats.Maximum
    
    $sorted = $Results.AllLatencies | Sort-Object
    $medianIdx = [math]::Floor($sorted.Count / 2)
    $p95Idx = [math]::Floor($sorted.Count * 0.95)
    $p99Idx = [math]::Floor($sorted.Count * 0.99)
    
    $medianLatency = $sorted[$medianIdx]
    $p95Latency = $sorted[$p95Idx]
    $p99Latency = $sorted[$p99Idx]
}

Write-Host "`n📊 MÉTRICAS GERAIS:" -ForegroundColor White
Write-Host "Total de requests: $($Results.TotalRequests)" -ForegroundColor Cyan
Write-Host "Sucessos: $($Results.SuccessfulRequests) ($successRate pct)" -ForegroundColor Green
Write-Host "Falhas: $($Results.FailedRequests)" -ForegroundColor Red
Write-Host "Throughput: $throughput req/s" -ForegroundColor Yellow
Write-Host "Duração total: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White

Write-Host "`n⏱️ ANÁLISE DE LATÊNCIA:" -ForegroundColor White
Write-Host "Mínima: ${minLatency}ms" -ForegroundColor Green
Write-Host "Mediana: ${medianLatency}ms" -ForegroundColor Cyan
Write-Host "Média: ${avgLatency}ms" -ForegroundColor Yellow
Write-Host "P95: ${p95Latency}ms" -ForegroundColor Yellow
Write-Host "P99: ${p99Latency}ms" -ForegroundColor Red
Write-Host "Máxima: ${maxLatency}ms" -ForegroundColor Red

Write-Host "`n🔧 PERFORMANCE POR TECNOLOGIA:" -ForegroundColor White
$Results.TechStats.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object {
    $name = $_.Key
    $stats = $_.Value
    if ($stats.Count -gt 0) {
        $avg = [math]::Round($stats.TotalTime / $stats.Count, 2)
        $errorRate = [math]::Round(($stats.Errors / ($stats.Count + $stats.Errors)) * 100, 1)
        Write-Host "📌 $name" -ForegroundColor Cyan
        Write-Host "   Requests: $($stats.Count) | Erros: $($stats.Errors) ($errorRate pct)" -ForegroundColor White
        Write-Host "   Latência: Min=${stats.MinTime}ms, Avg=${avg}ms, Max=${stats.MaxTime}ms" -ForegroundColor Gray
    }
}

# Análise de requests lentos
Write-Host "`n🐌 REQUESTS LENTOS (>500ms):" -ForegroundColor Yellow
if ($Results.SlowRequests.Count -gt 0) {
    Write-Host "Total detectados: $($Results.SlowRequests.Count)" -ForegroundColor Red
    Write-Host "Top 10 mais lentos:" -ForegroundColor Yellow
    
    $Results.SlowRequests | Sort-Object Latency -Descending | Select-Object -First 10 | ForEach-Object {
        $time = $_.Timestamp.ToString("HH:mm:ss.fff")
        Write-Host "   #$($_.Id): $($_.Endpoint) [$($_.Priority)] - $($_.Latency)ms at $time" -ForegroundColor Red
    }
    
    # Análise por prioridade
    $slowByPriority = $Results.SlowRequests | Group-Object Priority
    Write-Host "`nDistribuição por prioridade:" -ForegroundColor Yellow
    $slowByPriority | ForEach-Object {
        Write-Host "   $($_.Name): $($_.Count) requests lentos" -ForegroundColor Red
    }
} else {
    Write-Host "✅ Nenhum request lento detectado!" -ForegroundColor Green
}

# Análise temporal
$timeGroups = $Results.Timeline | Group-Object { $_.Timestamp.ToString("HH:mm") }
Write-Host "`n⏰ DISTRIBUIÇÃO TEMPORAL:" -ForegroundColor White
$timeGroups | ForEach-Object {
    $minute = $_.Name
    $count = $_.Count
    $successes = ($_.Group | Where-Object { $_.Success }).Count
    $rate = [math]::Round(($successes / $count) * 100, 1)
    Write-Host "   $minute - $count requests ($rate pct sucesso)" -ForegroundColor Cyan
}

# Salvar relatório JSON detalhado
$megaReport = @{
    TestConfig = @{
        TotalMessages = $TotalMessages
        Port = $Port
        TestType = if ($UseReal) { "real" } else { "simulation" }
        StartTime = $TestStartTime.ToString("yyyy-MM-dd HH:mm:ss")
        EndTime = $TestEndTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
    Summary = @{
        TotalRequests = $Results.TotalRequests
        SuccessfulRequests = $Results.SuccessfulRequests
        FailedRequests = $Results.FailedRequests
        SuccessRate = $successRate
        Throughput = $throughput
        Duration = $TotalDuration
    }
    Latency = @{
        Minimum = $minLatency
        Median = $medianLatency
        Average = $avgLatency
        P95 = $p95Latency
        P99 = $p99Latency
        Maximum = $maxLatency
    }
    TechnologyStats = $Results.TechStats
    SlowRequests = @{
        Count = $Results.SlowRequests.Count
        Details = $Results.SlowRequests | Select-Object -First 20
    }
    Timeline = $Results.Timeline | Select-Object -First 100  # Sample for size
    GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

if (-not (Test-Path "dashboard\data")) {
    New-Item -Path "dashboard\data" -ItemType Directory -Force | Out-Null
}

$json = $megaReport | ConvertTo-Json -Depth 6
$reportPath = "dashboard\data\mega-test-results-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n💾 Relatório completo salvo: $reportPath" -ForegroundColor Green

# Pontuação de qualidade avançada
$qualityScore = 0

# Success rate (40 pontos)
if ($successRate -ge 95) { $qualityScore += 40 }
elseif ($successRate -ge 90) { $qualityScore += 35 }
elseif ($successRate -ge 85) { $qualityScore += 30 }
elseif ($successRate -ge 80) { $qualityScore += 25 }

# Throughput (25 pontos)
if ($throughput -ge 50) { $qualityScore += 25 }
elseif ($throughput -ge 30) { $qualityScore += 20 }
elseif ($throughput -ge 20) { $qualityScore += 15 }
elseif ($throughput -ge 10) { $qualityScore += 10 }

# Latência (25 pontos)
if ($avgLatency -le 50) { $qualityScore += 25 }
elseif ($avgLatency -le 100) { $qualityScore += 20 }
elseif ($avgLatency -le 200) { $qualityScore += 15 }
elseif ($avgLatency -le 500) { $qualityScore += 10 }

# Requests lentos (10 pontos)
$slowRequestsPercentage = ($Results.SlowRequests.Count / $Results.TotalRequests) * 100
if ($slowRequestsPercentage -eq 0) { $qualityScore += 10 }
elseif ($slowRequestsPercentage -le 1) { $qualityScore += 8 }
elseif ($slowRequestsPercentage -le 3) { $qualityScore += 5 }

$qualityColor = if ($qualityScore -ge 90) { "Green" } elseif ($qualityScore -ge 75) { "Yellow" } else { "Red" }
$qualityLevel = if ($qualityScore -ge 90) { "EXCELENTE" } elseif ($qualityScore -ge 75) { "BOM" } elseif ($qualityScore -ge 60) { "SATISFATORIO" } else { "PRECISA MELHORAR" }

Write-Host "`n🏆 AVALIAÇÃO FINAL:" -ForegroundColor Magenta
Write-Host "Pontuação: $qualityScore/100 - $qualityLevel" -ForegroundColor $qualityColor

Write-Host "`n✅ MEGA TEST FINALIZADO COM SUCESSO!" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
