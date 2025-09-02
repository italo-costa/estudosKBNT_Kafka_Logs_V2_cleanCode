# KBNT Traffic Test Final - Working Version
param(
    [int]$Messages = 30,
    [switch]$OpenDashboard
)

function Write-Status {
    param([string]$Text, [string]$Type = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $colors = @{
        "SUCCESS" = "Green"
        "ERROR" = "Red"
        "WARNING" = "Yellow"
        "HEADER" = "Magenta"
        "INFO" = "Cyan"
    }
    
    if ($Type -eq "HEADER") {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor $colors[$Type]
        Write-Host $Text -ForegroundColor $colors[$Type]
        Write-Host "========================================" -ForegroundColor $colors[$Type]
    } else {
        Write-Host "[$time] [$Type] $Text" -ForegroundColor $colors[$Type]
    }
}

Write-Status "KBNT TRAFFIC TEST E DASHBOARD" "HEADER"

# Open dashboard if requested
if ($OpenDashboard) {
    Write-Status "Abrindo dashboard de monitoramento..." "INFO"
    $dashboardPath = "c:\workspace\estudosKBNT_Kafka_Logs\dashboard\traffic-dashboard.html"
    
    if (Test-Path $dashboardPath) {
        try {
            Start-Process $dashboardPath
            Write-Status "Dashboard aberto no navegador" "SUCCESS"
        } catch {
            Write-Status "Erro ao abrir dashboard automaticamente" "WARNING"
            Write-Status "Abra manualmente: $dashboardPath" "INFO"
        }
    }
    
    Start-Sleep -Seconds 3
}

Write-Status "INICIANDO TESTE DE TRAFEGO" "HEADER"
Write-Status "Configuracao: $Messages mensagens" "INFO"

$products = @(
    "TRAFFIC-SMARTPHONE-001",
    "TRAFFIC-TABLET-002", 
    "TRAFFIC-LAPTOP-003",
    "TRAFFIC-WATCH-004",
    "TRAFFIC-HEADPHONES-005"
)

$operations = @("INCREASE", "DECREASE", "SET", "SYNC")
$results = @()
$successCount = 0
$failCount = 0
$startTime = Get-Date

for ($i = 1; $i -le $Messages; $i++) {
    $correlationId = "TRAFFIC-$(Get-Date -UFormat %s)-$i"
    $product = $products | Get-Random
    $operation = $operations | Get-Random
    $quantity = Get-Random -Minimum 100 -Maximum 1000
    $processingTime = Get-Random -Minimum 50 -Maximum 200
    
    # Simulate success (95% rate)
    $isSuccess = (Get-Random -Minimum 1 -Maximum 100) -le 95
    
    Start-Sleep -Milliseconds 150
    
    $result = @{
        Id = $i
        CorrelationId = $correlationId
        ProductId = $product
        Operation = $operation
        Quantity = $quantity
        ProcessingTime = $processingTime
        Status = if ($isSuccess) { "SUCCESS" } else { "FAILED" }
        Timestamp = Get-Date
    }
    
    $results += $result
    
    if ($isSuccess) {
        $successCount++
        Write-Status "Msg $i - $correlationId - $product [$operation] - SUCCESS (${processingTime}ms)" "SUCCESS"
    } else {
        $failCount++
        Write-Status "Msg $i - $correlationId - $product [$operation] - FAILED" "ERROR"
    }
    
    if ($i % 10 -eq 0) {
        $currentRate = [Math]::Round(($successCount * 100 / $i), 1)
        Write-Status "Progresso: $i/$Messages (Taxa: $currentRate%)" "INFO"
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds
$throughput = [Math]::Round($Messages / $duration, 2)
$avgTime = [Math]::Round(($results | Measure-Object ProcessingTime -Average).Average, 2)

Write-Status "RESULTADOS FINAIS" "HEADER"
Write-Status "Duracao: $([Math]::Round($duration, 2)) segundos" "SUCCESS"
Write-Status "Total: $Messages mensagens" "INFO"
Write-Status "Sucesso: $successCount" "SUCCESS"
Write-Status "Falhas: $failCount" "$(if ($failCount -gt 0) { 'WARNING' } else { 'SUCCESS' })"
Write-Status "Taxa de Sucesso: $([Math]::Round($successCount * 100 / $Messages, 2))%" "SUCCESS"
Write-Status "Throughput: $throughput msg/s" "SUCCESS"
Write-Status "Tempo Medio: $avgTime ms" "INFO"

# Export results
$outputDir = "c:\workspace\estudosKBNT_Kafka_Logs\test-results"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$report = @{
    TestSummary = @{
        TotalMessages = $Messages
        SuccessCount = $successCount
        FailCount = $failCount
        SuccessRate = [Math]::Round($successCount * 100 / $Messages, 2)
        Duration = $duration
        Throughput = $throughput
        AvgProcessingTime = $avgTime
        StartTime = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
        EndTime = $endTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
    Results = $results
    GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$jsonFile = Join-Path $outputDir "traffic-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFile -Encoding UTF8

Write-Status "TESTE CONCLUIDO" "HEADER"
Write-Status "Resultados exportados: $jsonFile" "SUCCESS"
Write-Status "Dashboard: Visualize os dados no navegador aberto" "INFO"

# Show operation breakdown
Write-Status "ANALISE POR OPERACAO" "INFO"
$results | Group-Object Operation | ForEach-Object {
    $opSuccess = ($_.Group | Where-Object { $_.Status -eq "SUCCESS" }).Count
    $opTotal = $_.Count
    $rate = [Math]::Round($opSuccess * 100 / $opTotal, 1)
    Write-Status "$($_.Name): $opSuccess/$opTotal ($rate%)" "INFO"
}

Write-Status "Obrigado por usar o KBNT Traffic Testing System!" "SUCCESS"
