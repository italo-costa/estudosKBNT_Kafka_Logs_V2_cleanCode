# MEGA TEST - 2500 mensagens
param([int]$TotalMessages = 2500, [int]$Port = 8080)

Write-Host "MEGA LOAD TEST - 2500 MENSAGENS" -ForegroundColor Magenta

$TestStart = Get-Date
$Results = @{
    Total = 0; Success = 0; Failed = 0; Latencies = @(); Slow = @()
    Tech = @{
        "Actuator" = @{ Count = 0; Time = 0; Errors = 0 }
        "REST API" = @{ Count = 0; Time = 0; Errors = 0 }
        "Test" = @{ Count = 0; Time = 0; Errors = 0 }
        "Info" = @{ Count = 0; Time = 0; Errors = 0 }
    }
}

# Check app
try {
    Invoke-RestMethod "http://localhost:$Port/actuator/health" -TimeoutSec 3 | Out-Null
    Write-Host "App detectada na porta $Port" -ForegroundColor Green
    $UseReal = $true
} catch {
    Write-Host "Modo simulacao" -ForegroundColor Yellow
    $UseReal = $false
}

# Endpoints
$Endpoints = @(
    @{ Name = "health"; Url = "http://localhost:$Port/actuator/health"; Tech = "Actuator"; Weight = 35 }
    @{ Name = "stocks"; Url = "http://localhost:$Port/api/stocks/AAPL"; Tech = "REST API"; Weight = 30 }
    @{ Name = "test"; Url = "http://localhost:$Port/test"; Tech = "Test"; Weight = 25 }
    @{ Name = "info"; Url = "http://localhost:$Port/actuator/info"; Tech = "Info"; Weight = 10 }
)

Write-Host "Executando $TotalMessages requests..." -ForegroundColor Cyan

# Main loop
for ($i = 1; $i -le $TotalMessages; $i++) {
    # Select endpoint
    $rand = Get-Random -Maximum 100
    $selected = $Endpoints[0]
    $cum = 0
    
    foreach ($ep in $Endpoints) {
        $cum += $ep.Weight
        if ($rand -le $cum) { $selected = $ep; break }
    }
    
    # Execute request
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    
    try {
        if ($UseReal) {
            Invoke-RestMethod $selected.Url -TimeoutSec 5 | Out-Null
            $success = $true
        } else {
            $delay = switch ($selected.Name) {
                "health" { Get-Random -Min 20 -Max 60 }
                "stocks" { Get-Random -Min 50 -Max 150 }
                "test" { Get-Random -Min 30 -Max 100 }
                "info" { Get-Random -Min 15 -Max 50 }
            }
            Start-Sleep -Milliseconds $delay
            $success = (Get-Random -Max 100) -lt 94
        }
    } catch { $success = $false }
    
    $sw.Stop()
    $latency = $sw.ElapsedMilliseconds
    
    # Process result
    $Results.Total++
    
    if ($success) {
        $Results.Success++
        $Results.Latencies += $latency
        
        $tech = $Results.Tech[$selected.Tech]
        $tech.Count++
        $tech.Time += $latency
        
        if ($latency -gt 400) {
            $Results.Slow += @{ Id = $i; Endpoint = $selected.Name; Latency = $latency }
        }
    } else {
        $Results.Failed++
        $Results.Tech[$selected.Tech].Errors++
    }
    
    # Progress
    if ($i % 250 -eq 0) {
        $pct = [math]::Round(($i / $TotalMessages) * 100, 1)
        $elapsed = (Get-Date) - $TestStart
        $rate = [math]::Round($i / $elapsed.TotalSeconds, 1)
        Write-Host "Progress: $i/$TotalMessages ($pct) - $rate req/s" -ForegroundColor Blue
    }
}

$TestEnd = Get-Date
$Duration = ($TestEnd - $TestStart).TotalSeconds

# Results
$throughput = [math]::Round($Results.Total / $Duration, 2)
$successRate = [math]::Round(($Results.Success / $Results.Total) * 100, 2)

$avgLatency = 0
$minLatency = 0
$maxLatency = 0

if ($Results.Latencies.Count -gt 0) {
    $stats = $Results.Latencies | Measure-Object -Average -Min -Max
    $avgLatency = [math]::Round($stats.Average, 2)
    $minLatency = $stats.Minimum
    $maxLatency = $stats.Maximum
    
    $sorted = $Results.Latencies | Sort-Object
    $p95 = $sorted[[math]::Floor($sorted.Count * 0.95)]
    $p99 = $sorted[[math]::Floor($sorted.Count * 0.99)]
}

Write-Host "`nMEGA TEST RESULTS" -ForegroundColor Magenta
Write-Host "=================" -ForegroundColor Magenta

Write-Host "`nMETRICS:" -ForegroundColor White
Write-Host "Total: $($Results.Total)" -ForegroundColor Cyan
Write-Host "Success: $($Results.Success) ($successRate)" -ForegroundColor Green
Write-Host "Failed: $($Results.Failed)" -ForegroundColor Red
Write-Host "Throughput: $throughput req/s" -ForegroundColor Yellow
Write-Host "Duration: $([math]::Round($Duration, 2))s" -ForegroundColor White

Write-Host "`nLATENCY:" -ForegroundColor White
Write-Host "Min: ${minLatency}ms" -ForegroundColor Green
Write-Host "Avg: ${avgLatency}ms" -ForegroundColor Yellow
Write-Host "Max: ${maxLatency}ms" -ForegroundColor Red
if ($Results.Latencies.Count -gt 0) {
    Write-Host "P95: ${p95}ms" -ForegroundColor Yellow
    Write-Host "P99: ${p99}ms" -ForegroundColor Red
}

Write-Host "`nBY TECHNOLOGY:" -ForegroundColor White
$Results.Tech.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $tech = $_.Value
    if ($tech.Count -gt 0) {
        $avg = [math]::Round($tech.Time / $tech.Count, 2)
        Write-Host "$name - Count: $($tech.Count), Avg: ${avg}ms, Errors: $($tech.Errors)" -ForegroundColor Cyan
    }
}

Write-Host "`nSLOW REQUESTS (>400ms):" -ForegroundColor Yellow
if ($Results.Slow.Count -gt 0) {
    Write-Host "Total: $($Results.Slow.Count)" -ForegroundColor Red
    $Results.Slow | Sort-Object Latency -Desc | Select-Object -First 10 | ForEach-Object {
        Write-Host "  #$($_.Id): $($_.Endpoint) - $($_.Latency)ms" -ForegroundColor Red
    }
} else {
    Write-Host "None detected!" -ForegroundColor Green
}

# Save report
$report = @{
    Config = @{ TotalMessages = $TotalMessages; Port = $Port; Type = if($UseReal){"real"}else{"sim"} }
    Results = @{
        Total = $Results.Total; Success = $Results.Success; Failed = $Results.Failed
        SuccessRate = $successRate; Throughput = $throughput; Duration = $Duration
        Latency = @{ Min = $minLatency; Avg = $avgLatency; Max = $maxLatency; P95 = $p95; P99 = $p99 }
        SlowCount = $Results.Slow.Count; TechStats = $Results.Tech
    }
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

if (-not (Test-Path "dashboard\data")) { New-Item -Path "dashboard\data" -Type Directory -Force | Out-Null }

$json = $report | ConvertTo-Json -Depth 4
$path = "dashboard\data\mega-results-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File $path -Encoding UTF8

Write-Host "`nReport saved: $path" -ForegroundColor Green

# Quality score
$quality = 0
if ($successRate -ge 95) { $quality += 40 } elseif ($successRate -ge 90) { $quality += 35 }
if ($throughput -ge 50) { $quality += 25 } elseif ($throughput -ge 30) { $quality += 20 }
if ($avgLatency -le 50) { $quality += 25 } elseif ($avgLatency -le 100) { $quality += 20 }
if ($Results.Slow.Count -eq 0) { $quality += 10 }

$level = if ($quality -ge 90) { "EXCELLENT" } elseif ($quality -ge 75) { "GOOD" } else { "NEEDS WORK" }
$color = if ($quality -ge 90) { "Green" } elseif ($quality -ge 75) { "Yellow" } else { "Red" }

Write-Host "`nQUALITY SCORE: $quality/100 - $level" -ForegroundColor $color
Write-Host "MEGA TEST COMPLETED!" -ForegroundColor Magenta
