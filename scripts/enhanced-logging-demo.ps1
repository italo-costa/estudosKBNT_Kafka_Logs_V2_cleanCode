# Enhanced Logging Demo Script
# Este script demonstra o sistema de logging melhorado com identificacao de componentes

Write-Host "=== ENHANCED LOGGING DEMO ===" -ForegroundColor Cyan
Write-Host "Demonstrando sistema de logging com identificacao de componentes e owner" -ForegroundColor Yellow
Write-Host ""

# Configurar variaveis
$DEMO_MESSAGES = 5
$RESULTS_DIR = "demo-results"
$LOG_DIR = "logs"

# Criar diretorios necessarios
Write-Host "Preparando ambiente de demonstracao..." -ForegroundColor Green
if (!(Test-Path $RESULTS_DIR)) {
    New-Item -ItemType Directory -Path $RESULTS_DIR -Force | Out-Null
}
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

Write-Host "✓ Diretórios preparados: $RESULTS_DIR, $LOG_DIR" -ForegroundColor Green

# Função para simular logs do Microservice A (Producer)
function Test-MicroserviceALogging {
    Write-Host "`n--- TESTANDO MICROSERVICE-A (PRODUCER) ---" -ForegroundColor Magenta
    
    $logEntries = @()
    for ($i = 1; $i -le $DEMO_MESSAGES; $i++) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $messageId = "msg-A-$i-$(Get-Random -Minimum 1000 -Maximum 9999)"
        $productId = "PROD-$(Get-Random -Minimum 100 -Maximum 999)"
        
        $logEntry = @{
            timestamp = $timestamp
            level = "INFO"
            owner = "LogProducerService"
            component = "MICROSERVICE-A"
            messageId = $messageId
            topic = "stock-updates"
            operation = "KAFKA_PUBLISH"
            details = "Publishing stock update for product $productId"
            performanceMs = Get-Random -Minimum 50 -Maximum 200
        }
        
        $logEntries += $logEntry
        
        # Simular log no formato estruturado
        $logLine = "$($logEntry.timestamp) [MICROSERVICE-A-THREAD] INFO  [$($logEntry.owner)] [$($logEntry.component)] [$($logEntry.messageId)] [$($logEntry.topic)] com.kbnt.logproducer.service.LogProducerService - [KAFKA_PUBLISH] $($logEntry.details) - Duration: $($logEntry.performanceMs)ms"
        Write-Host $logLine -ForegroundColor White
        
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
    }
    
    # Salvar logs do Microservice A
    $microserviceALog = "logs/microservice-a.log"
    $logEntries | ForEach-Object {
        "$($_.timestamp) [MICROSERVICE-A-THREAD] $($_.level) [$($_.owner)] [$($_.component)] [$($_.messageId)] [$($_.topic)] com.kbnt.logproducer.service.LogProducerService - [$($_.operation)] $($_.details) - Duration: $($_.performanceMs)ms"
    } | Out-File -FilePath $microserviceALog -Append -Encoding UTF8
    
    Write-Host "✓ Microservice A logs saved to: $microserviceALog" -ForegroundColor Green
    return $logEntries
}

# Função para simular logs do Kafka (Red Hat AMQ Streams)
function Test-KafkaLogging {
    param($messages)
    
    Write-Host "`n--- TESTANDO RED HAT AMQ STREAMS (KAFKA) ---" -ForegroundColor Magenta
    
    $kafkaLogEntries = @()
    foreach ($msg in $messages) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $partition = Get-Random -Minimum 0 -Maximum 3
        $offset = Get-Random -Minimum 1000 -Maximum 9999
        
        # Log de recebimento no tópico
        $kafkaReceiveEntry = @{
            timestamp = $timestamp
            level = "INFO"
            kafkaComponent = "KAFKA_TOPIC"
            topic = $msg.topic
            partition = $partition
            offset = $offset
            operation = "MESSAGE_RECEIVED"
            details = "Message received and stored in topic partition"
            messageId = $msg.messageId
        }
        
        $kafkaLogEntries += $kafkaReceiveEntry
        
        # Log de replicação
        Start-Sleep -Milliseconds 50
        $replicationTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $kafkaReplicationEntry = @{
            timestamp = $replicationTimestamp
            level = "INFO"
            kafkaComponent = "KAFKA_REPLICATION"
            topic = $msg.topic
            partition = $partition
            offset = $offset
            operation = "REPLICATION_SYNC"
            details = "Message replicated to follower brokers"
            leader = "broker-1"
            replicas = "broker-2,broker-3"
        }
        
        $kafkaLogEntries += $kafkaReplicationEntry
        
        # Simular logs no formato estruturado
        $receiveLogLine = "$($kafkaReceiveEntry.timestamp) [kafka-topic-thread] INFO  [$($kafkaReceiveEntry.kafkaComponent)] [$($kafkaReceiveEntry.topic)] [$($kafkaReceiveEntry.partition)] [$($kafkaReceiveEntry.offset)] kafka.log.Log - [TOPIC_RECEIVE] $($kafkaReceiveEntry.topic) Partition:$($kafkaReceiveEntry.partition) - $($kafkaReceiveEntry.details)"
        $replicationLogLine = "$($kafkaReplicationEntry.timestamp) [kafka-replication-thread] INFO  [$($kafkaReplicationEntry.kafkaComponent)] [$($kafkaReplicationEntry.topic)] [$($kafkaReplicationEntry.partition)] [$($kafkaReplicationEntry.offset)] kafka.coordinator.GroupCoordinator - [REPLICATION_SYNC] $($kafkaReplicationEntry.topic) Partition:$($kafkaReplicationEntry.partition) Leader:$($kafkaReplicationEntry.leader) Replicas:[$($kafkaReplicationEntry.replicas)] - $($kafkaReplicationEntry.details)"
        
        Write-Host $receiveLogLine -ForegroundColor Yellow
        Write-Host $replicationLogLine -ForegroundColor DarkYellow
        
        Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 150)
    }
    
    # Salvar logs do Kafka
    $kafkaLog = "logs/amq-streams-kafka.log"
    $kafkaLogEntries | ForEach-Object {
        if ($_.operation -eq "MESSAGE_RECEIVED") {
            "$($_.timestamp) [kafka-topic-thread] $($_.level) [$($_.kafkaComponent)] [$($_.topic)] [$($_.partition)] [$($_.offset)] kafka.log.Log - [TOPIC_RECEIVE] $($_.topic) Partition:$($_.partition) - $($_.details)"
        } else {
            "$($_.timestamp) [kafka-replication-thread] $($_.level) [$($_.kafkaComponent)] [$($_.topic)] [$($_.partition)] [$($_.offset)] kafka.coordinator.GroupCoordinator - [REPLICATION_SYNC] $($_.topic) Partition:$($_.partition) Leader:$($_.leader) Replicas:[$($_.replicas)] - $($_.details)"
        }
    } | Out-File -FilePath $kafkaLog -Append -Encoding UTF8
    
    Write-Host "✓ Kafka logs saved to: $kafkaLog" -ForegroundColor Green
    return $kafkaLogEntries
}

# Função para simular logs do Microservice B (Consumer)
function Test-MicroserviceBLogging {
    param($messages, $kafkaMessages)
    
    Write-Host "`n--- TESTANDO MICROSERVICE-B (CONSUMER) ---" -ForegroundColor Magenta
    
    $consumerLogEntries = @()
    for ($i = 0; $i -lt $messages.Count; $i++) {
        $msg = $messages[$i]
        $kafkaMsg = $kafkaMessages[$i * 2] # Pega a mensagem de recebimento do Kafka
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $processingDuration = Get-Random -Minimum 200 -Maximum 800
        
        # Log de consumo
        $consumeEntry = @{
            timestamp = $timestamp
            level = "INFO"
            owner = "KafkaConsumerService"
            component = "MICROSERVICE-B"
            messageId = $msg.messageId
            topic = $msg.topic
            partition = $kafkaMsg.partition
            offset = $kafkaMsg.offset
            operation = "KAFKA_CONSUMER"
            details = "Message consumed and processing started"
        }
        
        $consumerLogEntries += $consumeEntry
        
        # Log de processamento
        Start-Sleep -Milliseconds 100
        $processTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $processEntry = @{
            timestamp = $processTimestamp
            level = "INFO"
            owner = "MessageProcessor"
            component = "MICROSERVICE-B"
            messageId = $msg.messageId
            operation = "MESSAGE_PROCESSING"
            details = "Stock update processed successfully"
            performanceMs = $processingDuration
        }
        
        $consumerLogEntries += $processEntry
        
        # Log de operação de banco de dados
        Start-Sleep -Milliseconds 50
        $dbTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $dbEntry = @{
            timestamp = $dbTimestamp
            level = "INFO"
            owner = "MessageProcessor"
            component = "MICROSERVICE-B"
            messageId = $msg.messageId
            operation = "DATABASE_OPERATION"
            details = "Consumption log saved to database"
        }
        
        $consumerLogEntries += $dbEntry
        
        # Simular logs no formato estruturado
        $consumeLogLine = "$($consumeEntry.timestamp) [consumer-thread] INFO  [$($consumeEntry.owner)] [$($consumeEntry.component)] [$($consumeEntry.messageId)] [$($consumeEntry.topic)] com.estudoskbnt.consumer.service.KafkaConsumerService - [KAFKA_CONSUMER] Message received - Topic: $($consumeEntry.topic), Partition: $($consumeEntry.partition), Offset: $($consumeEntry.offset)"
        $processLogLine = "$($processEntry.timestamp) [consumer-thread] INFO  [$($processEntry.owner)] [$($processEntry.component)] [$($processEntry.messageId)] [] com.estudoskbnt.consumer.service.KafkaConsumerService - [MESSAGE_PROCESSING] $($processEntry.details) - Duration: $($processEntry.performanceMs)ms"
        $dbLogLine = "$($dbEntry.timestamp) [consumer-thread] INFO  [$($dbEntry.owner)] [$($dbEntry.component)] [$($dbEntry.messageId)] [] com.estudoskbnt.consumer.service.KafkaConsumerService - [DATABASE_OPERATION] $($dbEntry.details)"
        
        Write-Host $consumeLogLine -ForegroundColor Cyan
        Write-Host $processLogLine -ForegroundColor Blue
        Write-Host $dbLogLine -ForegroundColor DarkBlue
        
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 200)
    }
    
    # Salvar logs do Microservice B
    $microserviceBLog = "logs/microservice-b.log"
    $consumerLogEntries | ForEach-Object {
        if ($_.operation -eq "KAFKA_CONSUMER") {
            "$($_.timestamp) [consumer-thread] $($_.level) [$($_.owner)] [$($_.component)] [$($_.messageId)] [$($_.topic)] com.estudoskbnt.consumer.service.KafkaConsumerService - [$($_.operation)] Message received - Topic: $($_.topic), Partition: $($_.partition), Offset: $($_.offset)"
        } elseif ($_.operation -eq "MESSAGE_PROCESSING") {
            "$($_.timestamp) [consumer-thread] $($_.level) [$($_.owner)] [$($_.component)] [$($_.messageId)] [] com.estudoskbnt.consumer.service.KafkaConsumerService - [$($_.operation)] $($_.details) - Duration: $($_.performanceMs)ms"
        } else {
            "$($_.timestamp) [consumer-thread] $($_.level) [$($_.owner)] [$($_.component)] [$($_.messageId)] [] com.estudoskbnt.consumer.service.KafkaConsumerService - [$($_.operation)] $($_.details)"
        }
    } | Out-File -FilePath $microserviceBLog -Append -Encoding UTF8
    
    Write-Host "✓ Microservice B logs saved to: $microserviceBLog" -ForegroundColor Green
    return $consumerLogEntries
}

# Função para gerar relatório de componentes
function Generate-ComponentReport {
    param($producerLogs, $kafkaLogs, $consumerLogs)
    
    Write-Host "`n--- GERANDO RELATÓRIO DE COMPONENTES ---" -ForegroundColor Magenta
    
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        totalMessages = $DEMO_MESSAGES
        components = @{
            "MICROSERVICE-A" = @{
                logCount = $producerLogs.Count
                operations = ($producerLogs | Group-Object operation | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ", "
                avgPerformance = [math]::Round(($producerLogs | Where-Object { $_.performanceMs } | Measure-Object -Property performanceMs -Average).Average, 2)
            }
            "RED_HAT_AMQ_STREAMS" = @{
                logCount = $kafkaLogs.Count
                operations = ($kafkaLogs | Group-Object operation | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ", "
                topicsProcessed = ($kafkaLogs | Select-Object -Unique topic).Count
            }
            "MICROSERVICE-B" = @{
                logCount = $consumerLogs.Count
                operations = ($consumerLogs | Group-Object operation | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ", "
                avgPerformance = [math]::Round(($consumerLogs | Where-Object { $_.performanceMs } | Measure-Object -Property performanceMs -Average).Average, 2)
            }
        }
        workflow = @{
            totalDuration = "N/A"
            endToEndTraceability = "Enabled with MessageId and Component identification"
            logFileLocations = @(
                "logs/microservice-a.log",
                "logs/amq-streams-kafka.log",
                "logs/microservice-b.log"
            )
        }
    }
    
    # Salvar relatório
    $reportFile = "$RESULTS_DIR/component-logging-report.json"
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportFile -Encoding UTF8
    
    # Exibir relatório resumido
    Write-Host "`n=== RELATÓRIO DE COMPONENTES E LOGGING ===" -ForegroundColor Green
    Write-Host "Total de mensagens processadas: $($report.totalMessages)" -ForegroundColor White
    Write-Host "`nComponentes identificados nos logs:" -ForegroundColor Yellow
    
    foreach ($component in $report.components.Keys) {
        $data = $report.components[$component]
        Write-Host "  • $component" -ForegroundColor Cyan
        Write-Host "    - Logs gerados: $($data.logCount)" -ForegroundColor White
        Write-Host "    - Operações: $($data.operations)" -ForegroundColor White
        if ($data.avgPerformance) {
            Write-Host "    - Performance média: $($data.avgPerformance)ms" -ForegroundColor White
        }
        if ($data.topicsProcessed) {
            Write-Host "    - Tópicos processados: $($data.topicsProcessed)" -ForegroundColor White
        }
    }
    
    Write-Host "`nArquivos de log gerados:" -ForegroundColor Yellow
    foreach ($logFile in $report.workflow.logFileLocations) {
        if (Test-Path $logFile) {
            $size = [math]::Round((Get-Item $logFile).Length / 1KB, 2)
            Write-Host "  • $logFile ($size KB)" -ForegroundColor Green
        } else {
            Write-Host "  • $logFile (não encontrado)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n✓ Relatório salvo em: $reportFile" -ForegroundColor Green
    return $report
}

# Executar demonstração completa
try {
    $startTime = Get-Date
    
    # Testar cada componente
    $producerLogs = Test-MicroserviceALogging
    $kafkaLogs = Test-KafkaLogging -messages $producerLogs
    $consumerLogs = Test-MicroserviceBLogging -messages $producerLogs -kafkaMessages $kafkaLogs
    
    # Gerar relatório final
    $report = Generate-ComponentReport -producerLogs $producerLogs -kafkaLogs $kafkaLogs -consumerLogs $consumerLogs
    
    $endTime = Get-Date
    $totalDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)
    
    Write-Host "`n=== DEMONSTRAÇÃO CONCLUÍDA ===" -ForegroundColor Green
    Write-Host "Duração total: $totalDuration segundos" -ForegroundColor White
    Write-Host "Rastreabilidade end-to-end habilitada com:" -ForegroundColor Yellow
    Write-Host "  • Identificação de componente (MICROSERVICE-A, RED_HAT_AMQ_STREAMS, MICROSERVICE-B)" -ForegroundColor White
    Write-Host "  • Owner do processo (LogProducerService, KafkaConsumerService, etc.)" -ForegroundColor White
    Write-Host "  • MessageId para correlação entre componentes" -ForegroundColor White
    Write-Host "  • Métricas de performance por operação" -ForegroundColor White
    Write-Host "  • Logs estruturados com contexto MDC" -ForegroundColor White
    
    Write-Host "`nPara verificar os logs detalhados:" -ForegroundColor Cyan
    Write-Host "  Get-Content logs/microservice-a.log | Select-Object -Last 10" -ForegroundColor Gray
    Write-Host "  Get-Content logs/amq-streams-kafka.log | Select-Object -Last 10" -ForegroundColor Gray
    Write-Host "  Get-Content logs/microservice-b.log | Select-Object -Last 10" -ForegroundColor Gray
    
} catch {
    Write-Host "`n❌ ERRO durante a demonstração: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
}

Write-Host "`n=== FIM DA DEMONSTRAÇÃO ===" -ForegroundColor Cyan
