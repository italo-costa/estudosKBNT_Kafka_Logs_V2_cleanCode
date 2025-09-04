# KBNT Traffic Test with Dashboard Integration
param(
    [int]$Messages = 50,
    [switch]$OpenDashboard,
    [switch]$ContinuousTest
)

function Write-Status {
    param([string]$Text, [string]$Type = "INFO")
    $time = Get-Date -Format "HH:mm:ss"
    $color = switch($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "HEADER" { "Magenta" }
        default { "Cyan" }
    }
    
    if ($Type -eq "HEADER") {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor $color
        Write-Host $Text -ForegroundColor $color
        Write-Host "========================================" -ForegroundColor $color
    } else {
        Write-Host "[$time] [$Type] $Text" -ForegroundColor $color
    }
}

function Start-TrafficTest {
    param([int]$MessageCount)
    
    Write-Status "INICIANDO TESTE DE TRAFEGO KBNT" "HEADER"
    Write-Status "Configuracao:" "INFO"
    Write-Status "  Mensagens: $MessageCount" "INFO"
    Write-Status "  Produtos: 8 diferentes" "INFO"
    Write-Status "  Operacoes: INCREASE, DECREASE, SET, SYNC" "INFO"
    
    $products = @(
        @{ Id = "TRAFFIC-SMARTPHONE-001"; Price = 599.99; Category = "Electronics" },
        @{ Id = "TRAFFIC-TABLET-002"; Price = 399.99; Category = "Electronics" },
        @{ Id = "TRAFFIC-LAPTOP-003"; Price = 1299.99; Category = "Computers" },
        @{ Id = "TRAFFIC-WATCH-004"; Price = 299.99; Category = "Wearables" },
        @{ Id = "TRAFFIC-HEADPHONES-005"; Price = 149.99; Category = "Audio" },
        @{ Id = "TRAFFIC-SPEAKER-006"; Price = 89.99; Category = "Audio" },
        @{ Id = "TRAFFIC-CAMERA-007"; Price = 799.99; Category = "Photography" },
        @{ Id = "TRAFFIC-MONITOR-008"; Price = 249.99; Category = "Computers" }
    )
    
    $operations = @("INCREASE", "DECREASE", "SET", "SYNC")
    $priorities = @("LOW", "NORMAL", "HIGH", "CRITICAL")
    $exchanges = @("NYSE", "NASDAQ", "LSE", "TSE", "BOVESPA")
    
    $results = @()
    $successCount = 0
    $failCount = 0
    $totalProcessingTime = 0
    $startTime = Get-Date
    
    for ($i = 1; $i -le $MessageCount; $i++) {
        $correlationId = "TRAFFIC-$(Get-Date -UFormat %s)-$('{0:D4}' -f $i)"
        $product = $products | Get-Random
        $operation = $operations | Get-Random
        $priority = $priorities | Get-Random
        $exchange = $exchanges | Get-Random
        $quantity = Get-Random -Minimum 100 -Maximum 2000
        
        # Simulate realistic processing time based on operation
        $processingTime = switch ($operation) {
            "INCREASE" { Get-Random -Minimum 50 -Maximum 120 }
            "DECREASE" { Get-Random -Minimum 45 -Maximum 110 }
            "SET" { Get-Random -Minimum 80 -Maximum 180 }
            "SYNC" { Get-Random -Minimum 120 -Maximum 250 }
            default { Get-Random -Minimum 60 -Maximum 150 }
        }
        
        # Simulate success/failure (95% success rate)
        $isSuccess = (Get-Random -Minimum 1 -Maximum 100) -le 95
        
        # Simulate network delay
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
        
        $result = @{
            Id = $i
            CorrelationId = $correlationId
            ProductId = $product.Id
            ProductCategory = $product.Category
            Operation = $operation
            Priority = $priority
            Exchange = $exchange
            Quantity = $quantity
            Price = $product.Price
            ProcessingTime = $processingTime
            Status = if ($isSuccess) { "SUCCESS" } else { "FAILED" }
            ErrorMessage = if (-not $isSuccess) { 
                $errors = @("Timeout", "Invalid quantity", "Product not found", "Network error", "Database connection failed")
                $errors | Get-Random
            } else { $null }
            Timestamp = Get-Date
        }
        
        $results += $result
        $totalProcessingTime += $processingTime
        
        if ($isSuccess) {
            $successCount++
            Write-Status "Msg $i: $($result.CorrelationId) - $($product.Id) [$operation] - SUCCESS ($($processingTime)ms)" "SUCCESS"
        } else {
            $failCount++
            Write-Status "Msg $i: $($result.CorrelationId) - $($product.Id) [$operation] - FAILED ($($result.ErrorMessage))" "ERROR"
        }
        
        # Progress update every 10 messages
        if ($i % 10 -eq 0) {
            $currentRate = [Math]::Round(($successCount * 100 / $i), 1)
            Write-Status "Progresso: $i/$MessageCount mensagens (Taxa de Sucesso: $currentRate%)" "INFO"
        }
    }
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalSeconds
    $throughput = [Math]::Round($MessageCount / $totalDuration, 2)
    $avgProcessingTime = [Math]::Round($totalProcessingTime / $MessageCount, 2)
    
    # Final Results
    Write-Status "RESULTADO FINAL DO TESTE" "HEADER"
    Write-Status "Duracao Total: $([Math]::Round($totalDuration, 2)) segundos" "SUCCESS"
    Write-Status "Total de Mensagens: $MessageCount" "INFO"
    Write-Status "Mensagens com Sucesso: $successCount" "SUCCESS"
    Write-Status "Mensagens com Falha: $failCount" "$(if ($failCount -gt 0) { 'WARNING' } else { 'SUCCESS' })"
    Write-Status "Taxa de Sucesso: $([Math]::Round($successCount * 100 / $MessageCount, 2))%" "SUCCESS"
    Write-Status "Throughput: $throughput mensagens/segundo" "SUCCESS"
    Write-Status "Tempo Medio de Processamento: $avgProcessingTime ms" "INFO"
    
    # Detailed Analysis
    Write-Status "ANALISE DETALHADA" "HEADER"
    
    # By Operation
    $operationStats = $results | Group-Object Operation | ForEach-Object {
        $opResults = $_.Group
        $opSuccess = ($opResults | Where-Object { $_.Status -eq "SUCCESS" }).Count
        $opTotal = $opResults.Count
        $opAvgTime = [Math]::Round(($opResults | Measure-Object ProcessingTime -Average).Average, 2)
        
        Write-Status "Operacao $($_.Name): $opSuccess/$opTotal (Taxa: $([Math]::Round($opSuccess * 100 / $opTotal, 1))%, Tempo Medio: $opAvgTime ms)" "INFO"
    }
    
    # By Priority
    $priorityStats = $results | Group-Object Priority | ForEach-Object {
        $priResults = $_.Group
        $priSuccess = ($priResults | Where-Object { $_.Status -eq "SUCCESS" }).Count
        $priTotal = $priResults.Count
        
        Write-Status "Prioridade $($_.Name): $priSuccess/$priTotal (Taxa: $([Math]::Round($priSuccess * 100 / $priTotal, 1))%)" "INFO"
    }
    
    return @{
        TotalMessages = $MessageCount
        SuccessCount = $successCount
        FailCount = $failCount
        Duration = $totalDuration
        Throughput = $throughput
        AvgProcessingTime = $avgProcessingTime
        Results = $results
        StartTime = $startTime
        EndTime = $endTime
    }
}

function Export-TestResults {
    param([object]$TestData, [string]$OutputPath)
    
    Write-Status "Exportando resultados do teste..." "INFO"
    
    # Create JSON report
    $report = @{
        TestSummary = @{
            TotalMessages = $TestData.TotalMessages
            SuccessCount = $TestData.SuccessCount
            FailCount = $TestData.FailCount
            SuccessRate = [Math]::Round($TestData.SuccessCount * 100 / $TestData.TotalMessages, 2)
            Duration = $TestData.Duration
            Throughput = $TestData.Throughput
            AvgProcessingTime = $TestData.AvgProcessingTime
            StartTime = $TestData.StartTime.ToString("yyyy-MM-dd HH:mm:ss")
            EndTime = $TestData.EndTime.ToString("yyyy-MM-dd HH:mm:ss")
        }
        DetailedResults = $TestData.Results
        GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TestType = "KBNT_Traffic_Load_Test"
    }
    
    $jsonFile = Join-Path $OutputPath "traffic-test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonFile -Encoding UTF8
    
    Write-Status "Resultados exportados para: $jsonFile" "SUCCESS"
    
    # Create CSV for detailed analysis
    $csvFile = Join-Path $OutputPath "traffic-test-details-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $TestData.Results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
    
    Write-Status "Detalhes exportados para: $csvFile" "SUCCESS"
    
    return @{ JsonFile = $jsonFile; CsvFile = $csvFile }
}

function Open-TrafficDashboard {
    Write-Status "Abrindo dashboard de monitoramento..." "INFO"
    
    $dashboardPath = "c:\workspace\estudosKBNT_Kafka_Logs\dashboard\traffic-dashboard.html"
    
    if (Test-Path $dashboardPath) {
        try {
            Start-Process $dashboardPath
            Write-Status "Dashboard aberto no navegador padrao" "SUCCESS"
            Write-Status "URL: file:///$($dashboardPath -replace '\\', '/')" "INFO"
        } catch {
            Write-Status "Erro ao abrir dashboard: $($_.Exception.Message)" "ERROR"
            Write-Status "Abra manualmente: $dashboardPath" "INFO"
        }
    } else {
        Write-Status "Arquivo de dashboard nao encontrado: $dashboardPath" "ERROR"
    }
}

# Main execution
Write-Status "KBNT TRAFFIC TEST E DASHBOARD" "HEADER"

# Open dashboard first if requested
if ($OpenDashboard) {
    Open-TrafficDashboard
    Start-Sleep -Seconds 3
}

# Run traffic test
if ($ContinuousTest) {
    Write-Status "Modo continuo ativo - executando testes a cada 2 minutos..." "WARNING"
    Write-Status "Pressione Ctrl+C para parar" "INFO"
    
    $testCount = 1
    while ($true) {
        Write-Status "Executando teste #$testCount..." "INFO"
        $testResults = Start-TrafficTest -MessageCount $Messages
        
        # Export results
        $outputDir = "c:\workspace\estudosKBNT_Kafka_Logs\test-results"
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        Export-TestResults -TestData $testResults -OutputPath $outputDir
        
        Write-Status "Teste #$testCount concluido. Aguardando 2 minutos para o proximo teste..." "INFO"
        Start-Sleep -Seconds 120
        $testCount++
    }
} else {
    # Single test run
    $testResults = Start-TrafficTest -MessageCount $Messages
    
    # Export results
    $outputDir = "c:\workspace\estudosKBNT_Kafka_Logs\test-results"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    $exportedFiles = Export-TestResults -TestData $testResults -OutputPath $outputDir
    
    Write-Status "TESTE CONCLUIDO COM SUCESSO" "HEADER"
    Write-Status "Dashboard: Acesse o arquivo HTML para visualizacao interativa" "INFO"
    Write-Status "Resultados JSON: $($exportedFiles.JsonFile)" "INFO"
    Write-Status "Detalhes CSV: $($exportedFiles.CsvFile)" "INFO"
    
    if (-not $OpenDashboard) {
        Write-Status "Use -OpenDashboard para abrir automaticamente o dashboard visual" "INFO"
    }
}

Write-Status "Obrigado por usar o KBNT Traffic Testing System!" "SUCCESS"
