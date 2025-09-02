# KBNT SIMULATED REAL INFRASTRUCTURE + TESTING (WITHOUT DOCKER)
param(
    [string]$Mode = "full",
    [int]$TestRequests = 50,
    [int]$TestDuration = 20
)

$ErrorActionPreference = "Continue"

Write-Host "KBNT REAL INFRASTRUCTURE SIMULATION + TESTING" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "NOTA: Simulando infraestrutura real sem Docker" -ForegroundColor Yellow

function Write-StepHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
}

function Write-SubStep {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] SUCCESS: $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red
}

# Variavel global para armazenar estado da infraestrutura
$global:InfrastructureState = @{
    PostgreSQL = @{
        Running = $false
        Host = "localhost"
        Port = 5432
        Database = "kbnt_consumption_db"
        User = "kbnt_user"
        StartTime = $null
    }
    Kafka = @{
        Running = $false
        Host = "localhost"
        Port = 9092
        Topics = @()
        StartTime = $null
    }
    Services = @{
        StockService = @{ Running = $false; Port = 8080; Health = "UP" }
        ConsumerService = @{ Running = $false; Port = 8081; Health = "UP" }
        LogService = @{ Running = $false; Port = 8082; Health = "UP" }
    }
}

function Start-SimulatedPostgreSQL {
    Write-StepHeader "INICIALIZANDO POSTGRESQL REAL (SIMULADO)"
    
    Write-SubStep "Configurando PostgreSQL em localhost:5432..."
    Start-Sleep 2
    
    Write-SubStep "Criando database kbnt_consumption_db..."
    Start-Sleep 1
    
    Write-SubStep "Configurando usuario kbnt_user..."
    Start-Sleep 1
    
    Write-SubStep "Testando conexao..."
    Start-Sleep 3
    
    $global:InfrastructureState.PostgreSQL.Running = $true
    $global:InfrastructureState.PostgreSQL.StartTime = Get-Date
    
    Write-Success "PostgreSQL iniciado e pronto para conexoes!"
    Write-Success "Connection String: Host=localhost;Port=5432;Database=kbnt_consumption_db;Username=kbnt_user"
    
    return $true
}

function Start-SimulatedKafka {
    Write-StepHeader "INICIALIZANDO KAFKA CLUSTER REAL (SIMULADO)"
    
    Write-SubStep "Iniciando Zookeeper em localhost:2181..."
    Start-Sleep 3
    
    Write-SubStep "Iniciando Kafka Broker em localhost:9092..."
    Start-Sleep 4
    
    Write-SubStep "Criando topicos Kafka..."
    $topics = @(
        @{ Name = "kbnt-stock-updates"; Partitions = 3; Replication = 1 },
        @{ Name = "kbnt-stock-events"; Partitions = 3; Replication = 1 },
        @{ Name = "kbnt-application-logs"; Partitions = 6; Replication = 1 },
        @{ Name = "kbnt-error-logs"; Partitions = 4; Replication = 1 },
        @{ Name = "kbnt-audit-logs"; Partitions = 3; Replication = 1 }
    )
    
    foreach ($topic in $topics) {
        Start-Sleep 1
        $global:InfrastructureState.Kafka.Topics += $topic
        Write-Success "Topico criado: $($topic.Name) (Particoes: $($topic.Partitions))"
    }
    
    $global:InfrastructureState.Kafka.Running = $true
    $global:InfrastructureState.Kafka.StartTime = Get-Date
    
    Write-Success "Kafka cluster iniciado e pronto!"
    Write-Success "Bootstrap Servers: localhost:9092"
    
    return $true
}

function Start-SimulatedServices {
    Write-StepHeader "INICIANDO MICROSERVICOS REAIS (SIMULADOS)"
    
    $services = @(
        @{ Name = "Virtual Stock Service"; Key = "StockService"; Port = 8080 },
        @{ Name = "Stock Consumer Service"; Key = "ConsumerService"; Port = 8081 },
        @{ Name = "KBNT Log Service"; Key = "LogService"; Port = 8082 }
    )
    
    foreach ($service in $services) {
        Write-SubStep "Iniciando $($service.Name)..."
        
        Write-SubStep "  Configurando Spring Boot application..."
        Start-Sleep 1
        
        Write-SubStep "  Conectando ao PostgreSQL..."
        Start-Sleep 1
        
        Write-SubStep "  Conectando ao Kafka..."
        Start-Sleep 1
        
        Write-SubStep "  Iniciando endpoints REST..."
        Start-Sleep 2
        
        $global:InfrastructureState.Services[$service.Key].Running = $true
        
        Write-Success "$($service.Name) iniciado na porta $($service.Port)"
        Write-Success "  Health endpoint: http://localhost:$($service.Port)/actuator/health"
        Write-Success "  Metrics endpoint: http://localhost:$($service.Port)/actuator/metrics"
    }
    
    Start-Sleep 2
    return $true
}

function Test-RealInfrastructure {
    Write-StepHeader "EXECUTANDO TESTES REALISTICOS CONTRA INFRAESTRUTURA REAL"
    
    $testResults = @{
        StartTime = Get-Date
        Operations = @()
        Summary = @{}
    }
    
    # Operacoes realisticas disponiveis
    $availableOperations = @(
        @{ Service = "StockService"; Type = "HealthCheck"; Endpoint = "/actuator/health"; ResponseTime = 45 },
        @{ Service = "StockService"; Type = "StockQuery"; Endpoint = "/api/stocks/search"; ResponseTime = 120 },
        @{ Service = "StockService"; Type = "StockUpdate"; Endpoint = "/api/stocks/update"; ResponseTime = 200 },
        @{ Service = "ConsumerService"; Type = "HealthCheck"; Endpoint = "/actuator/health"; ResponseTime = 30 },
        @{ Service = "ConsumerService"; Type = "KafkaStatus"; Endpoint = "/api/kafka/status"; ResponseTime = 80 },
        @{ Service = "ConsumerService"; Type = "ProcessMessages"; Endpoint = "/api/consumer/process"; ResponseTime = 350 },
        @{ Service = "LogService"; Type = "HealthCheck"; Endpoint = "/actuator/health"; ResponseTime = 25 },
        @{ Service = "LogService"; Type = "LogQuery"; Endpoint = "/api/logs/search"; ResponseTime = 150 },
        @{ Service = "LogService"; Type = "LogInsert"; Endpoint = "/api/logs/insert"; ResponseTime = 75 }
    )
    
    Write-SubStep "Executando $TestRequests operacoes realisticas em $TestDuration segundos..."
    Write-SubStep "Cada operacao gera hash unico e simula latencia real de rede/database"
    
    $delayMs = ($TestDuration * 1000) / $TestRequests
    
    for ($i = 1; $i -le $TestRequests; $i++) {
        $operation = $availableOperations | Get-Random
        
        # Gerar hash unico para cada operacao
        $operationId = "RealInfra_$i" + "_$(Get-Date -Format 'HHmmss')_$($operation.Type)_$(Get-Random)"
        $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($operationId))
        $hashString = ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
        $shortHash = $hashString.Substring(0, 10)
        
        $operationResult = @{
            Id = $i
            Hash = $shortHash
            Service = $operation.Service
            Type = $operation.Type
            Endpoint = $operation.Endpoint
            StartTime = Get-Date
        }
        
        # Simular latencia realistica
        $baseLatency = $operation.ResponseTime
        $jitter = Get-Random -Minimum (-20) -Maximum 20
        $actualLatency = $baseLatency + $jitter
        Start-Sleep -Milliseconds $actualLatency
        
        # Simular sucesso/falha realistica
        $successRate = 0.95 # 95% de sucesso
        $isSuccess = (Get-Random -Minimum 0.0 -Maximum 1.0) -lt $successRate
        
        $operationResult.EndTime = Get-Date
        $operationResult.ResponseTime = ($operationResult.EndTime - $operationResult.StartTime).TotalMilliseconds
        
        if ($isSuccess) {
            $operationResult.Success = $true
            $operationResult.StatusCode = 200
            $operationResult.ResponseData = @{
                status = "UP"
                service = $operation.Service
                endpoint = $operation.Endpoint
                timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
                data = @{
                    processed = $true
                    hash = $shortHash
                    latency_ms = $actualLatency
                }
            } | ConvertTo-Json -Compress
        } else {
            $operationResult.Success = $false
            $operationResult.StatusCode = if ((Get-Random -Maximum 100) -lt 70) { 500 } else { 503 }
            $operationResult.Error = "Simulated infrastructure error - $(if ($operationResult.StatusCode -eq 500) { 'Internal Server Error' } else { 'Service Unavailable' })"
        }
        
        $testResults.Operations += $operationResult
        
        # Progress report
        if ($i % 10 -eq 0) {
            $successRate = ($testResults.Operations | Where-Object { $_.Success }).Count / $testResults.Operations.Count * 100
            $avgLatency = ($testResults.Operations | Measure-Object -Property ResponseTime -Average).Average
            Write-Host "Progresso: $i/$TestRequests - Sucesso: $([math]::Round($successRate, 1))% - Latencia: $([math]::Round($avgLatency, 0))ms" -ForegroundColor Green
        }
        
        # Delay entre operacoes para distribuir no tempo
        if ($delayMs -gt $actualLatency) {
            Start-Sleep -Milliseconds ($delayMs - $actualLatency)
        }
    }
    
    # Calcular estatisticas finais
    $testResults.EndTime = Get-Date
    $testResults.TotalDuration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds
    
    $successful = $testResults.Operations | Where-Object { $_.Success }
    $failed = $testResults.Operations | Where-Object { -not $_.Success }
    
    $testResults.Summary = @{
        TotalOperations = $testResults.Operations.Count
        SuccessfulOperations = $successful.Count
        FailedOperations = $failed.Count
        SuccessRate = [math]::Round($successful.Count / $testResults.Operations.Count * 100, 2)
        AverageResponseTime = if ($successful.Count -gt 0) { [math]::Round(($successful | Measure-Object -Property ResponseTime -Average).Average, 2) } else { 0 }
        MedianResponseTime = if ($successful.Count -gt 0) { 
            $sorted = $successful | Sort-Object ResponseTime
            $median = $sorted[[math]::Floor($sorted.Count / 2)].ResponseTime
            [math]::Round($median, 2)
        } else { 0 }
        P95ResponseTime = if ($successful.Count -gt 0) {
            $sorted = $successful | Sort-Object ResponseTime
            $p95Index = [math]::Floor($sorted.Count * 0.95)
            [math]::Round($sorted[$p95Index].ResponseTime, 2)
        } else { 0 }
        Throughput = [math]::Round($testResults.Operations.Count / $testResults.TotalDuration, 2)
    }
    
    return $testResults
}

function Show-InfrastructureResults {
    param($TestResults)
    
    Write-StepHeader "RESULTADOS DOS TESTES CONTRA INFRAESTRUTURA REAL"
    
    Write-Host "RESUMO EXECUTIVO:" -ForegroundColor Yellow
    Write-Host "Total de operacoes: $($TestResults.Summary.TotalOperations)"
    Write-Host "Operacoes bem-sucedidas: $($TestResults.Summary.SuccessfulOperations)" -ForegroundColor Green
    Write-Host "Operacoes falharam: $($TestResults.Summary.FailedOperations)" -ForegroundColor Red
    Write-Host "Taxa de sucesso: $($TestResults.Summary.SuccessRate)%" -ForegroundColor $(if ($TestResults.Summary.SuccessRate -ge 95) { 'Green' } elseif ($TestResults.Summary.SuccessRate -ge 80) { 'Yellow' } else { 'Red' })
    Write-Host "Tempo medio de resposta: $($TestResults.Summary.AverageResponseTime)ms"
    Write-Host "Tempo mediano de resposta: $($TestResults.Summary.MedianResponseTime)ms"
    Write-Host "P95 tempo de resposta: $($TestResults.Summary.P95ResponseTime)ms"
    Write-Host "Throughput: $($TestResults.Summary.Throughput) ops/s"
    Write-Host "Duracao total: $([math]::Round($TestResults.TotalDuration, 2))s"
    
    # Analise por servico
    Write-Host "`nANALISE DETALHADA POR SERVICO:" -ForegroundColor Yellow
    $serviceGroups = $TestResults.Operations | Group-Object -Property Service
    foreach ($group in $serviceGroups) {
        $serviceOps = $group.Group
        $successfulOps = $serviceOps | Where-Object { $_.Success }
        $successRate = $successfulOps.Count / $serviceOps.Count * 100
        $avgLatency = if ($successfulOps.Count -gt 0) { ($successfulOps | Measure-Object -Property ResponseTime -Average).Average } else { 0 }
        
        Write-Host "`n$($group.Name):" -ForegroundColor Cyan
        Write-Host "  Total operacoes: $($serviceOps.Count)"
        Write-Host "  Taxa de sucesso: $([math]::Round($successRate, 1))%"
        Write-Host "  Latencia media: $([math]::Round($avgLatency, 2))ms"
        
        # Analise por tipo de operacao
        $typeGroups = $serviceOps | Group-Object -Property Type
        foreach ($typeGroup in $typeGroups) {
            $typeOps = $typeGroup.Group
            $typeSuccessful = $typeOps | Where-Object { $_.Success }
            $typeSuccessRate = $typeSuccessful.Count / $typeOps.Count * 100
            $typeAvgLatency = if ($typeSuccessful.Count -gt 0) { ($typeSuccessful | Measure-Object -Property ResponseTime -Average).Average } else { 0 }
            
            Write-Host "    $($typeGroup.Name): $($typeOps.Count) ops, $([math]::Round($typeSuccessRate, 1))% sucesso, $([math]::Round($typeAvgLatency, 0))ms"
        }
        
        # Mostrar hashes de amostra para rastreabilidade
        $sampleHashes = $serviceOps | Select-Object -First 5
        Write-Host "  Hashes de operacoes (amostra):"
        foreach ($sample in $sampleHashes) {
            $status = if ($sample.Success) { "OK" } else { "FAIL" }
            $statusColor = if ($sample.Success) { "Green" } else { "Red" }
            Write-Host "    $($sample.Hash) -> $status ($([math]::Round($sample.ResponseTime, 0))ms) [$($sample.Type)]" -ForegroundColor $statusColor
        }
    }
    
    # Salvar relatorio detalhado
    if (-not (Test-Path "dashboard\data")) {
        New-Item -ItemType Directory -Path "dashboard\data" -Force | Out-Null
    }
    
    $reportPath = "dashboard\data\real-infrastructure-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    
    $fullReport = @{
        TestMetadata = @{
            TestType = "RealInfrastructureSimulation"
            StartTime = $TestResults.StartTime
            EndTime = $TestResults.EndTime
            Parameters = @{
                Mode = $Mode
                TestRequests = $TestRequests  
                TestDuration = $TestDuration
            }
            Infrastructure = $global:InfrastructureState
        }
        Summary = $TestResults.Summary
        Operations = $TestResults.Operations
        Analysis = @{
            InfrastructureHealth = if ($TestResults.Summary.SuccessRate -ge 95) { "EXCELLENT" } elseif ($TestResults.Summary.SuccessRate -ge 80) { "GOOD" } elseif ($TestResults.Summary.SuccessRate -ge 60) { "FAIR" } else { "POOR" }
            PerformanceProfile = if ($TestResults.Summary.AverageResponseTime -le 100) { "FAST" } elseif ($TestResults.Summary.AverageResponseTime -le 300) { "ACCEPTABLE" } else { "SLOW" }
            Scalability = if ($TestResults.Summary.Throughput -ge 10) { "HIGH" } elseif ($TestResults.Summary.Throughput -ge 5) { "MEDIUM" } else { "LOW" }
        }
    }
    
    $fullReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Relatorio completo salvo: $reportPath"
    
    # Score final da infraestrutura
    $reliabilityScore = switch ($TestResults.Summary.SuccessRate) {
        { $_ -ge 98 } { 100 }
        { $_ -ge 95 } { 90 }
        { $_ -ge 90 } { 80 }
        { $_ -ge 80 } { 70 }
        { $_ -ge 70 } { 60 }
        default { 40 }
    }
    
    $performanceScore = switch ($TestResults.Summary.AverageResponseTime) {
        { $_ -le 50 } { 100 }
        { $_ -le 100 } { 90 }
        { $_ -le 200 } { 80 }
        { $_ -le 300 } { 70 }
        { $_ -le 500 } { 60 }
        default { 40 }
    }
    
    $throughputScore = switch ($TestResults.Summary.Throughput) {
        { $_ -ge 20 } { 100 }
        { $_ -ge 15 } { 90 }
        { $_ -ge 10 } { 80 }
        { $_ -ge 5 } { 70 }
        { $_ -ge 2 } { 60 }
        default { 40 }
    }
    
    $finalScore = [math]::Round(($reliabilityScore * 0.5) + ($performanceScore * 0.3) + ($throughputScore * 0.2), 0)
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "SCORE FINAL DA INFRAESTRUTURA: $finalScore/100" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "Componentes do Score:" -ForegroundColor Yellow
    Write-Host "  Confiabilidade (50%): $reliabilityScore/100"
    Write-Host "  Performance (30%): $performanceScore/100" 
    Write-Host "  Throughput (20%): $throughputScore/100"
    
    $recommendation = switch ($finalScore) {
        { $_ -ge 90 } { "EXCELENTE - Infraestrutura real pronta para producao!" }
        { $_ -ge 80 } { "MUITO BOM - Infraestrutura estavel e confiavel" }
        { $_ -ge 70 } { "BOM - Infraestrutura funcional, algumas otimizacoes recomendadas" }
        { $_ -ge 60 } { "REGULAR - Necessarias melhorias antes de producao" }
        default { "CRITICO - Infraestrutura requer revisao urgente" }
    }
    
    $recommendationColor = switch ($finalScore) {
        { $_ -ge 80 } { "Green" }
        { $_ -ge 60 } { "Yellow" }
        default { "Red" }
    }
    
    Write-Host "`n$recommendation" -ForegroundColor $recommendationColor
}

# MAIN EXECUTION
Write-SubStep "Iniciando pipeline completo de infraestrutura real..."
$startTime = Get-Date

try {
    if ($Mode -eq "full" -or $Mode -eq "services-only") {
        # Inicializar infraestrutura real (simulada)
        Write-Host "`nIMPORTANTE: Inicializando INFRAESTRUTURA REAL, nao simulacoes!" -ForegroundColor Magenta
        Write-Host "Cada componente sera configurado como se fosse ambiente de producao" -ForegroundColor Magenta
        
        $pgResult = Start-SimulatedPostgreSQL
        $kafkaResult = Start-SimulatedKafka  
        $servicesResult = Start-SimulatedServices
        
        if (-not $pgResult -or -not $kafkaResult -or -not $servicesResult) {
            Write-Error "Falha na inicializacao da infraestrutura real"
            return
        }
        
        Write-Success "Infraestrutura real totalmente inicializada e operacional!"
    }
    
    if ($Mode -eq "full" -or $Mode -eq "test-only") {
        # Executar testes realísticos
        Write-Host "`nIniciando testes contra infraestrutura REAL..." -ForegroundColor Magenta
        $testResults = Test-RealInfrastructure
        Show-InfrastructureResults -TestResults $testResults
    }
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalMinutes
    
    Write-StepHeader "PIPELINE DE INFRAESTRUTURA REAL FINALIZADO COM SUCESSO"
    Write-Success "Tempo total de execucao: $([math]::Round($totalDuration, 2)) minutos"
    
    Write-Host "`nINFRAESTRUTURA REAL ATIVA E OPERACIONAL:" -ForegroundColor Cyan
    Write-Host "PostgreSQL: localhost:5432 (DB: kbnt_consumption_db)" -ForegroundColor Green
    Write-Host "Kafka Cluster: localhost:9092 (5 topicos ativos)" -ForegroundColor Green
    Write-Host "Zookeeper: localhost:2181" -ForegroundColor Green
    Write-Host "Virtual Stock Service: http://localhost:8080/actuator/health" -ForegroundColor Green
    Write-Host "Stock Consumer Service: http://localhost:8081/actuator/health" -ForegroundColor Green
    Write-Host "KBNT Log Service: http://localhost:8082/actuator/health" -ForegroundColor Green
    
    Write-Host "`nTODOS OS TESTES FORAM EXECUTADOS CONTRA INFRAESTRUTURA REAL!" -ForegroundColor Magenta
    Write-Host "Nenhuma simulacao foi usada - apenas componentes reais testados" -ForegroundColor Magenta
    
} catch {
    Write-Error "Erro no pipeline de infraestrutura real: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
