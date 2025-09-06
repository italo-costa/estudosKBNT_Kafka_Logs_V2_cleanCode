# KBNT Kafka Logs - Teste de Performance Simples (PowerShell)
# Executa 1000 requisições contra uma aplicação usando PowerShell nativo

param(
    [string]$Url = "http://httpbin.org/status/200",
    [int]$TotalRequests = 1000,
    [int]$ConcurrentJobs = 50
)

Write-Host "🎯 KBNT Kafka Logs - Performance Test (PowerShell)" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "Target: $Url" -ForegroundColor Yellow
Write-Host "Total Requests: $TotalRequests" -ForegroundColor Yellow
Write-Host "Concurrent Jobs: $ConcurrentJobs" -ForegroundColor Yellow
Write-Host ""

# Função para fazer uma requisição
function Test-SingleRequest {
    param($RequestId, $Url)
    
    $startTime = Get-Date
    $success = $false
    $statusCode = 0
    $error = $null
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10
        $statusCode = $response.StatusCode
        $success = $true
    }
    catch {
        $error = $_.Exception.Message
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
    }
    
    $endTime = Get-Date
    $responseTime = ($endTime - $startTime).TotalMilliseconds
    
    return @{
        RequestId = $RequestId
        StatusCode = $statusCode
        ResponseTime = $responseTime
        Success = $success
        Error = $error
        Timestamp = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fff")
    }
}

Write-Host "🔍 Testing connectivity..." -ForegroundColor Green
$testResult = Test-SingleRequest -RequestId 0 -Url $Url

if (-not $testResult.Success) {
    Write-Host "❌ Service not available: $($testResult.Error)" -ForegroundColor Red
    Write-Host "💡 Make sure the target service is running" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Service is available (response time: $($testResult.ResponseTime.ToString('F2'))ms)" -ForegroundColor Green
Write-Host ""

# Preparar array para armazenar resultados
$results = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
$completed = 0

# Função para executar lote de requisições
$scriptBlock = {
    param($BatchStart, $BatchEnd, $Url)
    
    $batchResults = @()
    for ($i = $BatchStart; $i -le $BatchEnd; $i++) {
        $result = & (Get-Command Test-SingleRequest) -RequestId $i -Url $Url
        $batchResults += $result
    }
    return $batchResults
}

Write-Host "🚀 Starting load test..." -ForegroundColor Green
$startTime = Get-Date

# Calcular lotes
$batchSize = [Math]::Ceiling($TotalRequests / $ConcurrentJobs)
$jobs = @()

for ($i = 0; $i -lt $ConcurrentJobs; $i++) {
    $batchStart = ($i * $batchSize) + 1
    $batchEnd = [Math]::Min(($i + 1) * $batchSize, $TotalRequests)
    
    if ($batchStart -le $TotalRequests) {
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $batchStart, $batchEnd, $Url -InitializationScript {
            function Test-SingleRequest {
                param($RequestId, $Url)
                
                $startTime = Get-Date
                $success = $false
                $statusCode = 0
                $error = $null
                
                try {
                    $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10
                    $statusCode = $response.StatusCode
                    $success = $true
                }
                catch {
                    $error = $_.Exception.Message
                    if ($_.Exception.Response) {
                        $statusCode = $_.Exception.Response.StatusCode.value__
                    }
                }
                
                $endTime = Get-Date
                $responseTime = ($endTime - $startTime).TotalMilliseconds
                
                return @{
                    RequestId = $RequestId
                    StatusCode = $statusCode
                    ResponseTime = $responseTime
                    Success = $success
                    Error = $error
                    Timestamp = $startTime.ToString("yyyy-MM-ddTHH:mm:ss.fff")
                }
            }
        }
        $jobs += $job
    }
}

# Aguardar conclusão dos jobs
$totalJobs = $jobs.Count
$completedJobs = 0

Write-Host "📊 Monitoring progress..." -ForegroundColor Green

while ($completedJobs -lt $totalJobs) {
    Start-Sleep -Seconds 2
    $currentCompleted = ($jobs | Where-Object { $_.State -eq "Completed" }).Count
    
    if ($currentCompleted -gt $completedJobs) {
        $completedJobs = $currentCompleted
        $progress = ($completedJobs / $totalJobs) * 100
        Write-Host "📊 Progress: $completedJobs/$totalJobs jobs completed ($($progress.ToString('F1'))%)" -ForegroundColor Yellow
    }
}

# Coletar resultados
Write-Host "📊 Collecting results..." -ForegroundColor Green
$allResults = @()

foreach ($job in $jobs) {
    $jobResults = Receive-Job -Job $job
    $allResults += $jobResults
    Remove-Job -Job $job
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

# Análise dos resultados
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Gray
Write-Host "📊 PERFORMANCE TEST RESULTS" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

$totalRequests = $allResults.Count
$successfulRequests = ($allResults | Where-Object { $_.Success }).Count
$failedRequests = $totalRequests - $successfulRequests
$successRate = ($successfulRequests / $totalRequests) * 100

Write-Host "📈 General Metrics:" -ForegroundColor Green
Write-Host "   Total Requests: $totalRequests"
Write-Host "   Successful: $successfulRequests"
Write-Host "   Failed: $failedRequests"
Write-Host "   Success Rate: $($successRate.ToString('F2'))%"
Write-Host "   Total Duration: $($totalDuration.ToString('F2'))s"

$requestsPerSecond = $totalRequests / $totalDuration
Write-Host "   Requests/Second: $($requestsPerSecond.ToString('F2')) RPS"

# Métricas de tempo de resposta
$successfulResponseTimes = ($allResults | Where-Object { $_.Success }).ResponseTime

if ($successfulResponseTimes.Count -gt 0) {
    $avgResponseTime = ($successfulResponseTimes | Measure-Object -Average).Average
    $minResponseTime = ($successfulResponseTimes | Measure-Object -Minimum).Minimum
    $maxResponseTime = ($successfulResponseTimes | Measure-Object -Maximum).Maximum
    
    $sortedTimes = $successfulResponseTimes | Sort-Object
    $p95Index = [Math]::Floor(0.95 * $sortedTimes.Count)
    $p99Index = [Math]::Floor(0.99 * $sortedTimes.Count)
    $p95ResponseTime = $sortedTimes[$p95Index]
    $p99ResponseTime = $sortedTimes[$p99Index]
    
    Write-Host ""
    Write-Host "⏱️  Response Time Metrics:" -ForegroundColor Green
    Write-Host "   Average: $($avgResponseTime.ToString('F2'))ms"
    Write-Host "   Min: $($minResponseTime.ToString('F2'))ms"
    Write-Host "   Max: $($maxResponseTime.ToString('F2'))ms"
    Write-Host "   95th Percentile: $($p95ResponseTime.ToString('F2'))ms"
    Write-Host "   99th Percentile: $($p99ResponseTime.ToString('F2'))ms"
}

# Análise de erros
if ($failedRequests -gt 0) {
    Write-Host ""
    Write-Host "❌ Error Analysis:" -ForegroundColor Red
    $errorGroups = $allResults | Where-Object { -not $_.Success } | Group-Object Error
    foreach ($group in $errorGroups) {
        Write-Host "   $($group.Name): $($group.Count) occurrences"
    }
}

# Salvar relatório
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportFile = "performance_report_$timestamp.json"

$report = @{
    test_info = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fff")
        target_url = $Url
        total_requests = $totalRequests
        total_duration_seconds = $totalDuration
    }
    performance_metrics = @{
        requests_per_second = $requestsPerSecond
        success_rate_percent = $successRate
        avg_response_time_ms = if ($successfulResponseTimes.Count -gt 0) { ($successfulResponseTimes | Measure-Object -Average).Average } else { 0 }
        p95_response_time_ms = if ($successfulResponseTimes.Count -gt 0) { $p95ResponseTime } else { 0 }
        p99_response_time_ms = if ($successfulResponseTimes.Count -gt 0) { $p99ResponseTime } else { 0 }
    }
    detailed_results = $allResults
}

$report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host ""
Write-Host "📄 Detailed report saved: $reportFile" -ForegroundColor Green

# Conclusão
Write-Host ""
Write-Host "🎯 Performance Assessment:" -ForegroundColor Cyan
if ($requestsPerSecond -gt 1000) {
    Write-Host "   ✅ EXCELLENT: $($requestsPerSecond.ToString('F0')) RPS - High performance system" -ForegroundColor Green
} elseif ($requestsPerSecond -gt 500) {
    Write-Host "   ✅ GOOD: $($requestsPerSecond.ToString('F0')) RPS - Good performance" -ForegroundColor Green
} elseif ($requestsPerSecond -gt 100) {
    Write-Host "   ⚠️  MODERATE: $($requestsPerSecond.ToString('F0')) RPS - Acceptable performance" -ForegroundColor Yellow
} else {
    Write-Host "   ❌ LOW: $($requestsPerSecond.ToString('F0')) RPS - Performance needs improvement" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Test completed successfully!" -ForegroundColor Green
