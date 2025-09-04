# Advanced Load Test - 1200 mensagens
param(
    [int]$TotalMessages = 1200,
    [int]$Port = 8080
)

Write-Host "ADVANCED LOAD TEST - 1200 MENSAGENS" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

$TestStartTime = Get-Date
$Results = @{
    TotalRequests = 0
    SuccessfulRequests = 0
    FailedRequests = 0
    AllLatencies = @()
    SlowRequests = @()
    TechStats = @{
        "Spring Boot" = @{ Count = 0; TotalTime = 0; Errors = 0 }
        "Actuator" = @{ Count = 0; TotalTime = 0; Errors = 0 }
        "REST API" = @{ Count = 0; TotalTime = 0; Errors = 0 }
        "Test" = @{ Count = 0; TotalTime = 0; Errors = 0 }
    }
}

# Verificar aplicacao
try {
    Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 3 | Out-Null
    Write-Host "Aplicacao Spring Boot detectada" -ForegroundColor Green
    $UseReal = $true
} catch {
    Write-Host "Usando simulacao" -ForegroundColor Yellow  
    $UseReal = $false
}

# Endpoints
$Endpoints = @(
    @{ Name = "health"; Url = "http://localhost:$Port/actuator/health"; Tech = "Actuator"; Weight = 30 }
    @{ Name = "stocks"; Url = "http://localhost:$Port/api/stocks/AAPL"; Tech = "REST API"; Weight = 40 }  
    @{ Name = "test"; Url = "http://localhost:$Port/test"; Tech = "Test"; Weight = 20 }
    @{ Name = "info"; Url = "http://localhost:$Port/actuator/info"; Tech = "Spring Boot"; Weight = 10 }
)

Write-Host "Executando $TotalMessages requests..." -ForegroundColor Cyan

# Loop principal
for ($i = 1; $i -le $TotalMessages; $i++) {
    # Selecionar endpoint
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
    
    # Executar request
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    
    try {
        if ($UseReal) {
            Invoke-RestMethod -Uri $selectedEndpoint.Url -Method Get -TimeoutSec 5 | Out-Null
            $success = $true
        } else {
            # Simulacao
            $delay = switch ($selectedEndpoint.Name) {
                "health" { Get-Random -Minimum 25 -Maximum 80 }
                "stocks" { Get-Random -Minimum 60 -Maximum 180 }
                "test" { Get-Random -Minimum 40 -Maximum 120 }
                "info" { Get-Random -Minimum 20 -Maximum 65 }
            }
            Start-Sleep -Milliseconds $delay
            $success = (Get-Random -Maximum 100) -lt 95
        }
    } catch {
        $success = $false
    }
    
    $stopwatch.Stop()
    $latency = $stopwatch.ElapsedMilliseconds
    
    # Processar resultado
    $Results.TotalRequests++
    
    if ($success) {
        $Results.SuccessfulRequests++
        $Results.AllLatencies += $latency
        
        $techStats = $Results.TechStats[$selectedEndpoint.Tech]
        $techStats.Count++
        $techStats.TotalTime += $latency
        
        if ($latency -gt 1000) {
            $Results.SlowRequests += @{
                Id = $i
                Endpoint = $selectedEndpoint.Name
                Tech = $selectedEndpoint.Tech
                Latency = $latency
            }
        }
    } else {
        $Results.FailedRequests++
        $Results.TechStats[$selectedEndpoint.Tech].Errors++
    }
    
    # Progress
    if ($i % 100 -eq 0) {
        $pct = [math]::Round(($i / $TotalMessages) * 100, 1)
        Write-Host "Progress: $i/$TotalMessages ($pct)" -ForegroundColor Blue
    }
}

$TestEndTime = Get-Date
$Duration = ($TestEndTime - $TestStartTime).TotalSeconds

# Calcular metricas
$throughput = [math]::Round($Results.TotalRequests / $Duration, 2)
$successRate = [math]::Round(($Results.SuccessfulRequests / $Results.TotalRequests) * 100, 2)

$avgLatency = 0
$minLatency = 0
$maxLatency = 0

if ($Results.AllLatencies.Count -gt 0) {
    $avgLatency = [math]::Round(($Results.AllLatencies | Measure-Object -Average).Average, 2)
    $minLatency = ($Results.AllLatencies | Measure-Object -Minimum).Minimum
    $maxLatency = ($Results.AllLatencies | Measure-Object -Maximum).Maximum
    
    $sorted = $Results.AllLatencies | Sort-Object
    $p95Index = [math]::Floor($sorted.Count * 0.95)
    $p99Index = [math]::Floor($sorted.Count * 0.99)
    $p95 = $sorted[$p95Index]
    $p99 = $sorted[$p99Index]
} else {
    $p95 = 0
    $p99 = 0
}

# Relatorio
Write-Host "`nRELATORIO FINAL" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green

Write-Host "`nMETRICAS PRINCIPAIS:" -ForegroundColor White
Write-Host "Total requests: $($Results.TotalRequests)" -ForegroundColor Cyan
Write-Host "Sucessos: $($Results.SuccessfulRequests)" -ForegroundColor Green
Write-Host "Falhas: $($Results.FailedRequests)" -ForegroundColor Red
Write-Host "Taxa de sucesso: $successRate%" -ForegroundColor Green
Write-Host "Throughput: $throughput req/s" -ForegroundColor Cyan
Write-Host "Duracao: $([math]::Round($Duration, 2))s" -ForegroundColor White

Write-Host "`nLATENCIA:" -ForegroundColor White
Write-Host "Minima: ${minLatency}ms" -ForegroundColor Green
Write-Host "Maxima: ${maxLatency}ms" -ForegroundColor Red
Write-Host "Media: ${avgLatency}ms" -ForegroundColor Cyan
Write-Host "P95: ${p95}ms" -ForegroundColor Yellow
Write-Host "P99: ${p99}ms" -ForegroundColor Red

Write-Host "`nPOR TECNOLOGIA:" -ForegroundColor White
$Results.TechStats.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $stats = $_.Value
    if ($stats.Count -gt 0) {
        $avg = [math]::Round($stats.TotalTime / $stats.Count, 2)
        Write-Host "$name - Requests: $($stats.Count), Erros: $($stats.Errors), Latencia Media: ${avg}ms" -ForegroundColor Cyan
    }
}

Write-Host "`nREQUESTS LENTOS (>1000ms):" -ForegroundColor Yellow
if ($Results.SlowRequests.Count -gt 0) {
    Write-Host "Total: $($Results.SlowRequests.Count)" -ForegroundColor Red
    $Results.SlowRequests | Sort-Object Latency -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "Request #$($_.Id): $($_.Endpoint) - $($_.Latency)ms [$($_.Tech)]" -ForegroundColor Red
    }
} else {
    Write-Host "Nenhum request lento!" -ForegroundColor Green
}

# Salvar JSON
$reportData = @{
    TestConfig = @{
        TotalMessages = $TotalMessages
        Port = $Port
        TestType = if ($UseReal) { "real" } else { "simulation" }
    }
    Results = @{
        TotalRequests = $Results.TotalRequests
        SuccessfulRequests = $Results.SuccessfulRequests
        FailedRequests = $Results.FailedRequests
        SuccessRate = $successRate
        Throughput = $throughput
        Duration = $Duration
        Latency = @{
            Average = $avgLatency
            Minimum = $minLatency
            Maximum = $maxLatency
            P95 = $p95
            P99 = $p99
        }
        SlowRequestsCount = $Results.SlowRequests.Count
        TechStats = $Results.TechStats
    }
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

if (-not (Test-Path "dashboard\data")) {
    New-Item -Path "dashboard\data" -ItemType Directory -Force | Out-Null
}

$json = $reportData | ConvertTo-Json -Depth 5
$reportPath = "dashboard\data\test-results-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRelatorio salvo: $reportPath" -ForegroundColor Green

# Qualidade
$quality = 0
if ($successRate -ge 95) { $quality += 30 }
elseif ($successRate -ge 90) { $quality += 25 }

if ($throughput -ge 20) { $quality += 25 }
elseif ($throughput -ge 10) { $quality += 20 }

if ($avgLatency -le 100) { $quality += 25 }
elseif ($avgLatency -le 200) { $quality += 20 }

if ($Results.SlowRequests.Count -eq 0) { $quality += 20 }

$qualityColor = if ($quality -ge 85) { "Green" } elseif ($quality -ge 70) { "Yellow" } else { "Red" }
Write-Host "`nPONTUACAO DE QUALIDADE: $quality/100" -ForegroundColor $qualityColor

Write-Host "`nTESTE FINALIZADO!" -ForegroundColor Green
