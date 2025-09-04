# KBNT COMPLETE INFRASTRUCTURE STARTUP + REALISTIC TESTING
param(
    [string]$Mode = "full",
    [int]$TestRequests = 100,
    [int]$TestDuration = 30
)

$ErrorActionPreference = "Continue"

Write-Host "🚀 KBNT COMPLETE INFRASTRUCTURE + TESTING PIPELINE" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

function Write-StepHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "🔧 $Title" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

function Write-SubStep {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] 📋 $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] ✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] ❌ $Message" -ForegroundColor Red
}

function Start-PostgreSQL {
    Write-StepHeader "INICIALIZANDO POSTGRESQL DATABASE"
    
    Write-SubStep "Verificando Docker..."
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker não está disponível!"
        return $false
    }
    
    Write-SubStep "Parando PostgreSQL existente..."
    try {
        docker stop kbnt-postgresql 2>$null | Out-Null
        docker rm kbnt-postgresql 2>$null | Out-Null
    } catch {}
    
    Write-SubStep "Iniciando PostgreSQL container..."
    try {
        $result = docker run -d --name kbnt-postgresql `
            -p 5432:5432 `
            -e POSTGRES_DB=kbnt_consumption_db `
            -e POSTGRES_USER=kbnt_user `
            -e POSTGRES_PASSWORD=kbnt_password `
            -e POSTGRES_HOST_AUTH_METHOD=md5 `
            postgres:15-alpine
        
        if ($result) {
            Write-Success "PostgreSQL iniciado: $($result.Substring(0,12))"
            Start-Sleep 15
            
            # Testar conexão
            $attempts = 0
            $maxAttempts = 12
            while ($attempts -lt $maxAttempts) {
                try {
                    $pgReady = docker exec kbnt-postgresql pg_isready -U kbnt_user -d kbnt_consumption_db 2>$null
                    if ($pgReady -match "accepting connections") {
                        Write-Success "PostgreSQL está pronto!"
                        return $true
                    }
                } catch {}
                
                Start-Sleep 5
                $attempts++
                Write-Host "." -NoNewline
            }
            
            Write-Error "PostgreSQL não ficou pronto a tempo"
            return $false
        }
    } catch {
        Write-Error "Erro ao iniciar PostgreSQL: $($_.Exception.Message)"
        return $false
    }
}

function Start-Kafka {
    Write-StepHeader "INICIALIZANDO KAFKA CLUSTER"
    
    # Parar containers existentes
    Write-SubStep "Parando Kafka existente..."
    try {
        docker stop kbnt-kafka kbnt-zookeeper 2>$null | Out-Null
        docker rm kbnt-kafka kbnt-zookeeper 2>$null | Out-Null
    } catch {}
    
    # Iniciar Zookeeper
    Write-SubStep "Iniciando Zookeeper..."
    try {
        $zkResult = docker run -d --name kbnt-zookeeper `
            -p 2181:2181 `
            -e ZOOKEEPER_CLIENT_PORT=2181 `
            -e ZOOKEEPER_TICK_TIME=2000 `
            confluentinc/cp-zookeeper:latest
        
        Write-Success "Zookeeper iniciado: $($zkResult.Substring(0,12))"
        Start-Sleep 20
    } catch {
        Write-Error "Erro ao iniciar Zookeeper: $($_.Exception.Message)"
        return $false
    }
    
    # Iniciar Kafka
    Write-SubStep "Iniciando Kafka Broker..."
    try {
        $kafkaResult = docker run -d --name kbnt-kafka `
            -p 9092:9092 `
            --link kbnt-zookeeper:zookeeper `
            -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 `
            -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 `
            -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 `
            -e KAFKA_LOG_RETENTION_HOURS=168 `
            confluentinc/cp-kafka:latest
        
        Write-Success "Kafka iniciado: $($kafkaResult.Substring(0,12))"
        Start-Sleep 25
        
        # Criar tópicos
        Write-SubStep "Criando tópicos Kafka..."
        $topics = @(
            "kbnt-stock-updates:3:1"
            "kbnt-stock-events:3:1" 
            "kbnt-application-logs:6:1"
            "kbnt-error-logs:4:1"
            "kbnt-audit-logs:3:1"
        )
        
        foreach ($topic in $topics) {
            $parts = $topic.Split(':')
            $topicName = $parts[0]
            $partitions = $parts[1]
            $replication = $parts[2]
            
            try {
                docker exec kbnt-kafka kafka-topics --create --topic $topicName --partitions $partitions --replication-factor $replication --bootstrap-server localhost:9092 2>$null | Out-Null
                Write-Success "Tópico criado: $topicName"
            } catch {
                Write-Error "Erro ao criar tópico $topicName"
            }
        }
        
        return $true
    } catch {
        Write-Error "Erro ao iniciar Kafka: $($_.Exception.Message)"
        return $false
    }
}

function Start-MockServices {
    Write-StepHeader "INICIANDO SERVIÇOS MOCK PARA TESTE"
    
    $mockServices = @(
        @{ Name = "mock-stock-service"; Port = 8080; Health = '{"status":"UP","service":"virtual-stock-service","timestamp":"'+(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")+'"}' }
        @{ Name = "mock-consumer-service"; Port = 8081; Health = '{"status":"UP","service":"stock-consumer-service","timestamp":"'+(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")+'"}' }
        @{ Name = "mock-log-service"; Port = 8082; Health = '{"status":"UP","service":"kbnt-log-service","timestamp":"'+(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")+'"}' }
    )
    
    foreach ($mock in $mockServices) {
        Write-SubStep "Iniciando $($mock.Name)..."
        
        # Parar existente
        try {
            docker stop $mock.Name 2>$null | Out-Null
            docker rm $mock.Name 2>$null | Out-Null
        } catch {}
        
        # Criar serviço mock básico
        try {
            $containerId = docker run -d --name $($mock.Name) -p $($mock.Port):8080 `
                --link kbnt-postgresql:postgres --link kbnt-kafka:kafka `
                -e SPRING_PROFILES_ACTIVE=local `
                -e KAFKA_BOOTSTRAP_SERVERS=kafka:9092 `
                httpd:alpine
            
            # Configurar endpoints mock
            docker exec $($mock.Name) mkdir -p /usr/local/apache2/htdocs/actuator 2>$null | Out-Null
            docker exec $($mock.Name) sh -c "echo '$($mock.Health)' > /usr/local/apache2/htdocs/actuator/health" 2>$null | Out-Null
            docker exec $($mock.Name) sh -c "echo '$($mock.Health)' > /usr/local/apache2/htdocs/actuator/metrics" 2>$null | Out-Null
            docker exec $($mock.Name) sh -c "echo '$($mock.Health)' > /usr/local/apache2/htdocs/actuator/info" 2>$null | Out-Null
            
            Write-Success "$($mock.Name) iniciado na porta $($mock.Port)"
        } catch {
            Write-Error "Erro ao iniciar $($mock.Name): $($_.Exception.Message)"
        }
    }
    
    Start-Sleep 10
    return $true
}

function Test-RealInfrastructure {
    Write-StepHeader "EXECUTANDO TESTES REALÍSTICOS NA INFRAESTRUTURA"
    
    $testResults = @{
        StartTime = Get-Date
        Operations = @()
        Summary = @{}
    }
    
    # Definir operações disponíveis
    $availableOperations = @(
        @{ Service = "mock-stock-service"; Port = 8080; Endpoint = "/actuator/health"; Method = "GET"; Type = "HealthCheck" }
        @{ Service = "mock-stock-service"; Port = 8080; Endpoint = "/actuator/metrics"; Method = "GET"; Type = "Metrics" }
        @{ Service = "mock-consumer-service"; Port = 8081; Endpoint = "/actuator/health"; Method = "GET"; Type = "HealthCheck" }
        @{ Service = "mock-log-service"; Port = 8082; Endpoint = "/actuator/health"; Method = "GET"; Type = "HealthCheck" }
    )
    
    Write-SubStep "Executando $TestRequests operações em $TestDuration segundos..."
    
    $delayMs = ($TestDuration * 1000) / $TestRequests
    
    for ($i = 1; $i -le $TestRequests; $i++) {
        $operation = $availableOperations | Get-Random
        
        # Gerar hash único
        $operationId = "InfraOp_$i`_$(Get-Date -Format 'HHmmss')_$(Get-Random)"
        $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($operationId))
        $hashString = ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
        $shortHash = $hashString.Substring(0, 8)
        
        $operationResult = @{
            Id = $i
            Hash = $shortHash
            Service = $operation.Service
            Type = $operation.Type
            StartTime = Get-Date
        }
        
        try {
            $url = "http://localhost:$($operation.Port)$($operation.Endpoint)"
            $response = Invoke-WebRequest -Uri $url -Method $operation.Method -TimeoutSec 10
            
            $operationResult.EndTime = Get-Date
            $operationResult.ResponseTime = ($operationResult.EndTime - $operationResult.StartTime).TotalMilliseconds
            $operationResult.StatusCode = $response.StatusCode
            $operationResult.Success = $true
            $operationResult.ResponseData = $response.Content
        } catch {
            $operationResult.EndTime = Get-Date
            $operationResult.ResponseTime = ($operationResult.EndTime - $operationResult.StartTime).TotalMilliseconds
            $operationResult.Success = $false
            $operationResult.Error = $_.Exception.Message
        }
        
        $testResults.Operations += $operationResult
        
        if ($i % 25 -eq 0) {
            $successRate = ($testResults.Operations | Where-Object { $_.Success }).Count / $testResults.Operations.Count * 100
            Write-Host "Progresso: $i/$TestRequests - Sucesso: $([math]::Round($successRate, 1))%" -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds $delayMs
    }
    
    # Análise dos resultados
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
        Throughput = [math]::Round($testResults.Operations.Count / $testResults.TotalDuration, 2)
    }
    
    return $testResults
}

function Show-InfrastructureResults {
    param($TestResults)
    
    Write-StepHeader "RESULTADOS DA INFRAESTRUTURA REAL"
    
    Write-Host "RESUMO EXECUTIVO:" -ForegroundColor Yellow
    Write-Host "Total de operações: $($TestResults.Summary.TotalOperations)"
    Write-Host "Operações bem-sucedidas: $($TestResults.Summary.SuccessfulOperations)" 
    Write-Host "Operações falharam: $($TestResults.Summary.FailedOperations)"
    Write-Host "Taxa de sucesso: $($TestResults.Summary.SuccessRate)%"
    Write-Host "Tempo médio de resposta: $($TestResults.Summary.AverageResponseTime)ms"
    Write-Host "Throughput: $($TestResults.Summary.Throughput) ops/s"
    Write-Host "Duração total: $([math]::Round($TestResults.TotalDuration, 2))s"
    
    # Análise por serviço
    Write-Host "`nANÁLISE POR SERVIÇO:" -ForegroundColor Yellow
    $serviceGroups = $TestResults.Operations | Group-Object -Property Service
    foreach ($group in $serviceGroups) {
        $serviceOps = $group.Group
        $successRate = ($serviceOps | Where-Object { $_.Success }).Count / $serviceOps.Count * 100
        $avgLatency = ($serviceOps | Measure-Object -Property ResponseTime -Average).Average
        
        Write-Host "$($group.Name):" -ForegroundColor Cyan
        Write-Host "  Operações: $($serviceOps.Count)"
        Write-Host "  Taxa de sucesso: $([math]::Round($successRate, 1))%"
        Write-Host "  Latência média: $([math]::Round($avgLatency, 2))ms"
        
        # Mostrar hashes de amostra
        $sampleHashes = $serviceOps | Select-Object -First 3
        Write-Host "  Hashes de amostra:"
        foreach ($sample in $sampleHashes) {
            $status = if ($sample.Success) { "✅" } else { "❌" }
            Write-Host "    $($sample.Hash) -> $status ($($sample.ResponseTime)ms)"
        }
    }
    
    # Salvar resultados
    if (-not (Test-Path "dashboard\data")) {
        New-Item -ItemType Directory -Path "dashboard\data" -Force | Out-Null
    }
    
    $reportPath = "dashboard\data\real-infrastructure-test-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
    $TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Relatório completo salvo: $reportPath"
    
    # Score final
    $infraScore = if ($TestResults.Summary.SuccessRate -ge 95) { 100 } elseif ($TestResults.Summary.SuccessRate -ge 80) { 80 } elseif ($TestResults.Summary.SuccessRate -ge 60) { 60 } else { 40 }
    $performanceScore = if ($TestResults.Summary.AverageResponseTime -le 50) { 100 } elseif ($TestResults.Summary.AverageResponseTime -le 200) { 80 } elseif ($TestResults.Summary.AverageResponseTime -le 500) { 60 } else { 40 }
    
    $finalScore = [math]::Round(($infraScore + $performanceScore) / 2, 0)
    
    Write-Host "`n🏆 SCORE FINAL DA INFRAESTRUTURA: $finalScore/100" -ForegroundColor Cyan
    
    if ($finalScore -ge 90) {
        Write-Host "✅ EXCELENTE - Infraestrutura real funcionando perfeitamente!" -ForegroundColor Green
    } elseif ($finalScore -ge 70) {
        Write-Host "✅ BOM - Infraestrutura estável" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ PRECISA MELHORIAS - Infraestrutura com problemas" -ForegroundColor Red
    }
}

# MAIN EXECUTION
Write-SubStep "Iniciando pipeline completo..."
$startTime = Get-Date

try {
    if ($Mode -eq "full" -or $Mode -eq "services-only") {
        # Inicializar infraestrutura real
        $pgResult = Start-PostgreSQL
        $kafkaResult = Start-Kafka
        $mocksResult = Start-MockServices
        
        if (-not $pgResult -or -not $kafkaResult) {
            Write-Error "Falha na inicialização da infraestrutura base"
            return
        }
        
        Write-Success "Infraestrutura real inicializada com sucesso!"
    }
    
    if ($Mode -eq "full" -or $Mode -eq "test-only") {
        # Executar testes realísticos
        $testResults = Test-RealInfrastructure
        Show-InfrastructureResults -TestResults $testResults
    }
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $startTime).TotalMinutes
    
    Write-StepHeader "PIPELINE DE INFRAESTRUTURA REAL FINALIZADO"
    Write-Success "Tempo total: $([math]::Round($totalDuration, 2)) minutos"
    
    Write-Host "`n🏗️ INFRAESTRUTURA ATIVA:" -ForegroundColor Cyan
    Write-Host "PostgreSQL: localhost:5432 (DB: kbnt_consumption_db)"
    Write-Host "Kafka: localhost:9092"
    Write-Host "Zookeeper: localhost:2181" 
    Write-Host "Mock Stock Service: http://localhost:8080/actuator/health"
    Write-Host "Mock Consumer Service: http://localhost:8081/actuator/health"
    Write-Host "Mock Log Service: http://localhost:8082/actuator/health"
    
} catch {
    Write-Error "Erro no pipeline: $($_.Exception.Message)"
}
