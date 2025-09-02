# Script de Teste Realístico - Infraestrutura KBNT Completa
param(
    [int]$TotalRequests = 100,
    [int]$ConcurrentUsers = 5,
    [int]$TestDurationSeconds = 30,
    [switch]$IncludeDatabaseOps = $true,
    [switch]$IncludeKafkaIntegration = $true,
    [string]$Environment = "local"
)

$ErrorActionPreference = "Continue"
Write-Host "🏗️ KBNT INFRASTRUCTURE REALISTIC TEST" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Configuração da infraestrutura real KBNT
$Infrastructure = @{
    VirtualStockService = @{
        BaseUrl = "http://localhost:8080"
        Endpoints = @(
            "/api/stock/update"
            "/api/stock/query"
            "/actuator/health"
            "/actuator/metrics"
            "/actuator/info"
        )
        RequiresDatabase = $true
        ProducesToKafka = $true
    }
    
    StockConsumerService = @{
        BaseUrl = "http://localhost:8081"
        Endpoints = @(
            "/actuator/health"
            "/actuator/metrics"
            "/api/consumer/monitoring/statistics"
            "/api/consumer/monitoring/logs"
            "/api/consumer/monitoring/performance/slowest"
        )
        RequiresDatabase = $true
        ConsumesFromKafka = $true
    }
    
    LogService = @{
        BaseUrl = "http://localhost:8082"
        Endpoints = @(
            "/actuator/health"
            "/actuator/metrics"
            "/api/v1/logs"
            "/api/v1/analytics/summary"
            "/api/v1/analytics/errors"
        )
        RequiresDatabase = $false
        ProducesToKafka = $true
        ConsumesFromKafka = $true
    }
    
    ApiGateway = @{
        BaseUrl = "http://localhost:8083"
        Endpoints = @(
            "/health"
            "/routes"
            "/gateway/stock/*"
            "/gateway/consumer/*"
            "/gateway/logs/*"
        )
        RequiresDatabase = $false
        RoutesToServices = $true
    }
}

# Kafka Topics que devem existir na infraestrutura real
$KafkaTopics = @(
    "kbnt-stock-updates"
    "kbnt-stock-events"
    "kbnt-application-logs"
    "kbnt-error-logs"
    "kbnt-audit-logs"
    "kbnt-financial-logs"
    "kbnt-dead-letter-queue"
)

# Estruturas de dados para coleta
$TestResults = @{}
$InfrastructureHealth = @{}
$ServiceMetrics = @{}
$KafkaMetrics = @{}
$DatabaseMetrics = @{}

# Função para verificar saúde da infraestrutura
function Test-InfrastructureHealth {
    Write-Host "`n🔍 Verificando Saúde da Infraestrutura..." -ForegroundColor Yellow
    
    foreach ($service in $Infrastructure.Keys) {
        $config = $Infrastructure[$service]
        Write-Host "Testando $service..." -ForegroundColor Gray
        
        $healthResults = @{
            ServiceName = $service
            BaseUrl = $config.BaseUrl
            IsHealthy = $false
            ResponseTime = 0
            Endpoints = @{}
            LastError = $null
        }
        
        # Testar endpoint de health
        try {
            $healthUrl = "$($config.BaseUrl)/actuator/health"
            $start = Get-Date
            $response = Invoke-WebRequest -Uri $healthUrl -Method Get -TimeoutSec 10
            $end = Get-Date
            
            $healthResults.IsHealthy = ($response.StatusCode -eq 200)
            $healthResults.ResponseTime = ($end - $start).TotalMilliseconds
            
            if ($response.StatusCode -eq 200) {
                $healthData = $response.Content | ConvertFrom-Json
                Write-Host "✅ $service - Health OK ($($healthResults.ResponseTime)ms)" -ForegroundColor Green
            }
        }
        catch {
            $healthResults.LastError = $_.Exception.Message
            Write-Host "❌ $service - Health FAILED: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $InfrastructureHealth[$service] = $healthResults
    }
}

# Função para coletar métricas dos serviços
function Collect-ServiceMetrics {
    param($ServiceName, $BaseUrl)
    
    try {
        $metricsUrl = "$BaseUrl/actuator/metrics"
        $response = Invoke-WebRequest -Uri $metricsUrl -Method Get -TimeoutSec 5
        
        if ($response.StatusCode -eq 200) {
            $metricsData = $response.Content | ConvertFrom-Json
            return @{
                Available = $true
                TotalMetrics = $metricsData.names.Count
                KeyMetrics = $metricsData.names | Select-Object -First 10
            }
        }
    }
    catch {
        return @{
            Available = $false
            Error = $_.Exception.Message
        }
    }
}

# Função para executar operações de negócio realísticas
function Invoke-BusinessOperation {
    param(
        [int]$OperationId,
        [string]$OperationType,
        [hashtable]$ServiceConfig
    )
    
    $operation = @{
        Id = $OperationId
        Type = $OperationType
        StartTime = Get-Date
        Success = $false
        ResponseTime = 0
        StatusCode = 0
        Hash = $null
        ComponentsInvolved = @()
        BusinessData = @{}
    }
    
    # Gerar hash único para a operação
    $timestamp = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss-fff")
    $operationData = "BusinessOp_$OperationId`_$OperationType`_$timestamp`_$(Get-Random)"
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($operationData)
    $hashBytes = $sha256.ComputeHash($bytes)
    $operation.Hash = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join "" | ForEach-Object { $_.Substring(0, 8) }
    $sha256.Dispose()
    
    try {
        switch ($OperationType) {
            "StockUpdate" {
                # Operação real de atualização de estoque
                $stockData = @{
                    symbol = @("AAPL", "GOOGL", "MSFT", "TSLA", "AMZN") | Get-Random
                    quantity = Get-Random -Minimum 1 -Maximum 1000
                    operation = @("BUY", "SELL") | Get-Random
                    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    operationId = $operation.Hash
                }
                
                $response = Invoke-WebRequest -Uri "$($ServiceConfig.BaseUrl)/api/stock/update" `
                    -Method Post `
                    -Body ($stockData | ConvertTo-Json) `
                    -ContentType "application/json" `
                    -TimeoutSec 15
                
                $operation.ComponentsInvolved += @("VirtualStockService", "Database", "KafkaProducer")
                $operation.BusinessData = $stockData
            }
            
            "LogQuery" {
                # Consulta de logs analíticos
                $response = Invoke-WebRequest -Uri "$($ServiceConfig.BaseUrl)/api/v1/analytics/summary" `
                    -Method Get `
                    -TimeoutSec 10
                
                $operation.ComponentsInvolved += @("LogService", "Analytics")
            }
            
            "HealthCheck" {
                # Health check detalhado
                $response = Invoke-WebRequest -Uri "$($ServiceConfig.BaseUrl)/actuator/health" `
                    -Method Get `
                    -TimeoutSec 5
                
                $operation.ComponentsInvolved += @("Actuator", "HealthIndicators")
            }
            
            "ConsumerStats" {
                # Estatísticas do consumer
                $response = Invoke-WebRequest -Uri "$($ServiceConfig.BaseUrl)/api/consumer/monitoring/statistics" `
                    -Method Get `
                    -TimeoutSec 10
                
                $operation.ComponentsInvolved += @("ConsumerService", "KafkaConsumer", "Monitoring")
            }
        }
        
        $operation.EndTime = Get-Date
        $operation.ResponseTime = ($operation.EndTime - $operation.StartTime).TotalMilliseconds
        $operation.StatusCode = $response.StatusCode
        $operation.Success = ($response.StatusCode -eq 200)
        
        if ($operation.Success) {
            try {
                $responseData = $response.Content | ConvertFrom-Json
                $operation.ResponseData = $responseData
            }
            catch {
                $operation.ResponseData = $response.Content
            }
        }
    }
    catch {
        $operation.EndTime = Get-Date
        $operation.ResponseTime = ($operation.EndTime - $operation.StartTime).TotalMilliseconds
        $operation.Error = $_.Exception.Message
        $operation.Success = $false
    }
    
    return $operation
}

# Função principal de teste
function Start-RealisticTest {
    Write-Host "`n🚀 Iniciando Teste Realístico da Infraestrutura KBNT..." -ForegroundColor Green
    Write-Host "Parâmetros:" -ForegroundColor Gray
    Write-Host "- Total de operações: $TotalRequests" -ForegroundColor Gray
    Write-Host "- Usuários concorrentes: $ConcurrentUsers" -ForegroundColor Gray
    Write-Host "- Duração: $TestDurationSeconds segundos" -ForegroundColor Gray
    Write-Host "- Incluir DB: $IncludeDatabaseOps" -ForegroundColor Gray
    Write-Host "- Incluir Kafka: $IncludeKafkaIntegration" -ForegroundColor Gray
    
    # Verificar infraestrutura
    Test-InfrastructureHealth
    
    # Definir cenários de teste baseados nos serviços disponíveis
    $TestScenarios = @()
    
    foreach ($service in $InfrastructureHealth.Keys) {
        if ($InfrastructureHealth[$service].IsHealthy) {
            $config = $Infrastructure[$service]
            
            switch ($service) {
                "VirtualStockService" {
                    $TestScenarios += @{
                        Service = $service
                        Config = $config
                        Operations = @("StockUpdate", "HealthCheck")
                        Weight = 30
                    }
                }
                "StockConsumerService" {
                    $TestScenarios += @{
                        Service = $service
                        Config = $config
                        Operations = @("ConsumerStats", "HealthCheck")
                        Weight = 25
                    }
                }
                "LogService" {
                    $TestScenarios += @{
                        Service = $service
                        Config = $config
                        Operations = @("LogQuery", "HealthCheck")
                        Weight = 25
                    }
                }
                "ApiGateway" {
                    $TestScenarios += @{
                        Service = $service
                        Config = $config
                        Operations = @("HealthCheck")
                        Weight = 20
                    }
                }
            }
        }
    }
    
    if ($TestScenarios.Count -eq 0) {
        Write-Host "❌ Nenhum serviço disponível para teste!" -ForegroundColor Red
        return
    }
    
    Write-Host "`n📊 Executando Operações de Negócio..." -ForegroundColor Yellow
    $allOperations = @()
    $startTime = Get-Date
    
    for ($i = 1; $i -le $TotalRequests; $i++) {
        # Selecionar cenário baseado no peso
        $selectedScenario = $TestScenarios | Get-Random
        $selectedOperation = $selectedScenario.Operations | Get-Random
        
        # Executar operação
        $operation = Invoke-BusinessOperation -OperationId $i -OperationType $selectedOperation -ServiceConfig $selectedScenario.Config
        $operation.ServiceName = $selectedScenario.Service
        
        $allOperations += $operation
        
        # Progress
        if ($i % 20 -eq 0) {
            $successRate = ($allOperations | Where-Object { $_.Success }).Count / $allOperations.Count * 100
            $avgResponseTime = ($allOperations | Measure-Object -Property ResponseTime -Average).Average
            Write-Host "Progresso: $i/$TotalRequests - Sucesso: $([math]::Round($successRate, 1))% - Latência Média: $([math]::Round($avgResponseTime, 2))ms" -ForegroundColor Green
        }
        
        # Delay realístico entre operações
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
    }
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalSeconds
    
    # Análise dos resultados
    Write-Host "`n📈 Análise dos Resultados..." -ForegroundColor Cyan
    
    $successfulOps = $allOperations | Where-Object { $_.Success }
    $failedOps = $allOperations | Where-Object { -not $_.Success }
    
    Write-Host "`nRESUMO EXECUTIVO:" -ForegroundColor Yellow
    Write-Host "Total de operações: $($allOperations.Count)"
    Write-Host "Operações bem-sucedidas: $($successfulOps.Count)"
    Write-Host "Operações falharam: $($failedOps.Count)"
    Write-Host "Taxa de sucesso: $([math]::Round($successfulOps.Count / $allOperations.Count * 100, 1))%"
    Write-Host "Duração total: $([math]::Round($totalDuration, 2))s"
    Write-Host "Throughput: $([math]::Round($allOperations.Count / $totalDuration, 2)) ops/s"
    
    # Análise por serviço
    Write-Host "`nANÁLISE POR SERVIÇO:" -ForegroundColor Yellow
    $serviceStats = $allOperations | Group-Object -Property ServiceName
    foreach ($serviceGroup in $serviceStats) {
        $serviceOps = $serviceGroup.Group
        $serviceSuccessRate = ($serviceOps | Where-Object { $_.Success }).Count / $serviceOps.Count * 100
        $avgLatency = ($serviceOps | Measure-Object -Property ResponseTime -Average).Average
        
        Write-Host "$($serviceGroup.Name):" -ForegroundColor Cyan
        Write-Host "  Operações: $($serviceOps.Count)"
        Write-Host "  Taxa de sucesso: $([math]::Round($serviceSuccessRate, 1))%"
        Write-Host "  Latência média: $([math]::Round($avgLatency, 2))ms"
        
        # Mostrar hashes de algumas operações
        $sampleHashes = $serviceOps | Select-Object -First 3 | ForEach-Object { 
            $status = if ($_.Success) { "✅" } else { "❌" }
            "    $($_.Hash) -> $status ($($_.ResponseTime)ms)"
        }
        if ($sampleHashes) {
            Write-Host "  Hashes de amostra:"
            $sampleHashes | ForEach-Object { Write-Host $_ }
        }
    }
    
    # Análise por tipo de operação
    Write-Host "`nANÁLISE POR TIPO DE OPERAÇÃO:" -ForegroundColor Yellow
    $operationStats = $allOperations | Group-Object -Property Type
    foreach ($opGroup in $operationStats) {
        $ops = $opGroup.Group
        $successRate = ($ops | Where-Object { $_.Success }).Count / $ops.Count * 100
        $avgLatency = ($ops | Measure-Object -Property ResponseTime -Average).Average
        
        Write-Host "$($opGroup.Name): $($ops.Count) ops, $([math]::Round($successRate, 1))% sucesso, $([math]::Round($avgLatency, 2))ms latência"
    }
    
    # Salvar resultados
    $reportData = @{
        TestConfiguration = @{
            TotalRequests = $TotalRequests
            ConcurrentUsers = $ConcurrentUsers
            TestDurationSeconds = $TestDurationSeconds
            IncludeDatabaseOps = $IncludeDatabaseOps
            IncludeKafkaIntegration = $IncludeKafkaIntegration
            Environment = $Environment
        }
        InfrastructureHealth = $InfrastructureHealth
        TestResults = @{
            TotalOperations = $allOperations.Count
            SuccessfulOperations = $successfulOps.Count
            FailedOperations = $failedOps.Count
            SuccessRate = [math]::Round($successfulOps.Count / $allOperations.Count * 100, 2)
            TotalDuration = [math]::Round($totalDuration, 2)
            Throughput = [math]::Round($allOperations.Count / $totalDuration, 2)
        }
        ServiceMetrics = @{}
        Operations = $allOperations
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    # Adicionar métricas por serviço
    foreach ($serviceGroup in $serviceStats) {
        $serviceOps = $serviceGroup.Group
        $reportData.ServiceMetrics[$serviceGroup.Name] = @{
            OperationCount = $serviceOps.Count
            SuccessCount = ($serviceOps | Where-Object { $_.Success }).Count
            SuccessRate = [math]::Round(($serviceOps | Where-Object { $_.Success }).Count / $serviceOps.Count * 100, 2)
            AvgLatency = [math]::Round(($serviceOps | Measure-Object -Property ResponseTime -Average).Average, 2)
            Hashes = $serviceOps | ForEach-Object { $_.Hash }
            ComponentsInvolved = ($serviceOps | ForEach-Object { $_.ComponentsInvolved } | Sort-Object -Unique)
        }
    }
    
    # Salvar arquivo
    if (-not (Test-Path "dashboard\data")) {
        New-Item -ItemType Directory -Path "dashboard\data" -Force | Out-Null
    }
    
    $reportPath = "dashboard\data\realistic-test-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
    $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "`n💾 Relatório salvo: $reportPath" -ForegroundColor Green
    
    # Score final
    $infraScore = ($InfrastructureHealth.Values | Where-Object { $_.IsHealthy }).Count / $InfrastructureHealth.Count * 100
    $performanceScore = if ($successfulOps.Count -gt 0) {
        $avgLatency = ($successfulOps | Measure-Object -Property ResponseTime -Average).Average
        $latencyScore = if ($avgLatency -le 100) { 100 } elseif ($avgLatency -le 500) { 80 } elseif ($avgLatency -le 1000) { 60 } else { 40 }
        ($reportData.TestResults.SuccessRate + $latencyScore) / 2
    } else { 0 }
    
    $finalScore = [math]::Round(($infraScore + $performanceScore) / 2, 0)
    
    Write-Host "`n🏆 SCORE FINAL: $finalScore/100" -ForegroundColor Cyan
    
    if ($finalScore -ge 90) {
        Write-Host "✅ EXCELENTE - Infraestrutura funcionando perfeitamente!" -ForegroundColor Green
    } elseif ($finalScore -ge 70) {
        Write-Host "✅ BOM - Infraestrutura estável com algumas melhorias necessárias" -ForegroundColor Yellow
    } elseif ($finalScore -ge 50) {
        Write-Host "⚠️ REGULAR - Infraestrutura precisa de otimizações" -ForegroundColor Yellow
    } else {
        Write-Host "❌ CRÍTICO - Infraestrutura com problemas sérios" -ForegroundColor Red
    }
    
    return $reportData
}

# Executar teste
try {
    $results = Start-RealisticTest
    Write-Host "`n🎯 Teste realístico da infraestrutura KBNT concluído!" -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Erro durante o teste: $($_.Exception.Message)" -ForegroundColor Red
}
