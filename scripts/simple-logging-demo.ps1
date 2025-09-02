# Enhanced Logging Demo - Simple Version
Write-Host "=== ENHANCED LOGGING DEMO ===" -ForegroundColor Cyan
Write-Host "Demonstrando sistema de logging com identificacao de componentes" -ForegroundColor Yellow

# Criar diretorios
$RESULTS_DIR = "demo-results"
$LOG_DIR = "logs"

if (!(Test-Path $RESULTS_DIR)) { New-Item -ItemType Directory -Path $RESULTS_DIR -Force | Out-Null }
if (!(Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null }

Write-Host "Diretorios preparados" -ForegroundColor Green

# Simular logs do Microservice A
Write-Host "`n--- MICROSERVICE-A (PRODUCER) ---" -ForegroundColor Magenta
$producerLogs = @()
for ($i = 1; $i -le 3; $i++) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $messageId = "msg-A-$i-$(Get-Random -Minimum 1000 -Maximum 9999)"
    $duration = Get-Random -Minimum 50 -Maximum 200
    
    $logLine = "$timestamp [THREAD] INFO [LogProducerService] [MICROSERVICE-A] [$messageId] [stock-updates] - [KAFKA_PUBLISH] Publishing message - Duration: ${duration}ms"
    Write-Host $logLine -ForegroundColor White
    $producerLogs += @{ messageId = $messageId; duration = $duration }
    
    Start-Sleep -Milliseconds 200
}

# Salvar logs do Producer
$producerLogs | ForEach-Object {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') [THREAD] INFO [LogProducerService] [MICROSERVICE-A] [$($_.messageId)] [stock-updates] - [KAFKA_PUBLISH] Message published - Duration: $($_.duration)ms"
} | Out-File -FilePath "logs/microservice-a.log" -Encoding UTF8

# Simular logs do Kafka
Write-Host "`n--- RED HAT AMQ STREAMS (KAFKA) ---" -ForegroundColor Yellow
for ($i = 0; $i -lt $producerLogs.Count; $i++) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $partition = Get-Random -Minimum 0 -Maximum 2
    $offset = Get-Random -Minimum 1000 -Maximum 9999
    
    $logLine = "$timestamp [kafka-thread] INFO [KAFKA_TOPIC] [stock-updates] [$partition] [$offset] - [TOPIC_RECEIVE] Message received in partition"
    Write-Host $logLine -ForegroundColor Yellow
    
    Start-Sleep -Milliseconds 100
    
    $replicationLine = "$timestamp [kafka-replication] INFO [KAFKA_REPLICATION] [stock-updates] [$partition] [$offset] - [REPLICATION_SYNC] Message replicated"
    Write-Host $replicationLine -ForegroundColor DarkYellow
    
    Start-Sleep -Milliseconds 150
}

# Salvar logs do Kafka
@(
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') [kafka-thread] INFO [KAFKA_TOPIC] [stock-updates] [0] [1001] - [TOPIC_RECEIVE] Message received in partition 0",
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') [kafka-replication] INFO [KAFKA_REPLICATION] [stock-updates] [0] [1001] - [REPLICATION_SYNC] Message replicated to brokers"
) | Out-File -FilePath "logs/amq-streams-kafka.log" -Encoding UTF8

# Simular logs do Microservice B
Write-Host "`n--- MICROSERVICE-B (CONSUMER) ---" -ForegroundColor Cyan
$consumerLogs = @()
for ($i = 0; $i -lt $producerLogs.Count; $i++) {
    $msg = $producerLogs[$i]
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $processingTime = Get-Random -Minimum 200 -Maximum 500
    
    $consumeLog = "$timestamp [consumer] INFO [KafkaConsumerService] [MICROSERVICE-B] [$($msg.messageId)] [stock-updates] - [KAFKA_CONSUMER] Message consumed"
    Write-Host $consumeLog -ForegroundColor Cyan
    
    Start-Sleep -Milliseconds 100
    
    $processLog = "$timestamp [consumer] INFO [MessageProcessor] [MICROSERVICE-B] [$($msg.messageId)] [] - [MESSAGE_PROCESSING] Processing completed - Duration: ${processingTime}ms"
    Write-Host $processLog -ForegroundColor Blue
    
    $consumerLogs += @{ messageId = $msg.messageId; processingTime = $processingTime }
    Start-Sleep -Milliseconds 200
}

# Salvar logs do Consumer
$consumerLogs | ForEach-Object {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') [consumer] INFO [KafkaConsumerService] [MICROSERVICE-B] [$($_.messageId)] [stock-updates] - [KAFKA_CONSUMER] Message consumed and processed - Duration: $($_.processingTime)ms"
} | Out-File -FilePath "logs/microservice-b.log" -Encoding UTF8

# Gerar relatorio
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    totalMessages = $producerLogs.Count
    components = @{
        "MICROSERVICE-A" = @{
            logCount = $producerLogs.Count
            avgDuration = [math]::Round(($producerLogs | Measure-Object -Property duration -Average).Average, 2)
        }
        "RED_HAT_AMQ_STREAMS" = @{
            logCount = $producerLogs.Count * 2
            operations = "TOPIC_RECEIVE, REPLICATION_SYNC"
        }
        "MICROSERVICE-B" = @{
            logCount = $consumerLogs.Count
            avgProcessingTime = [math]::Round(($consumerLogs | Measure-Object -Property processingTime -Average).Average, 2)
        }
    }
}

$report | ConvertTo-Json -Depth 3 | Out-File -FilePath "$RESULTS_DIR/logging-report.json" -Encoding UTF8

# Exibir resultado
Write-Host "`n=== RELATORIO DE COMPONENTES ===" -ForegroundColor Green
Write-Host "Total de mensagens: $($report.totalMessages)" -ForegroundColor White
Write-Host "`nComponentes identificados nos logs:" -ForegroundColor Yellow
foreach ($component in $report.components.Keys) {
    $data = $report.components[$component]
    Write-Host "  - $component" -ForegroundColor Cyan
    Write-Host "    Logs gerados: $($data.logCount)" -ForegroundColor White
    if ($data.avgDuration) {
        Write-Host "    Duration media: $($data.avgDuration)ms" -ForegroundColor White
    }
    if ($data.avgProcessingTime) {
        Write-Host "    Processing media: $($data.avgProcessingTime)ms" -ForegroundColor White
    }
    if ($data.operations) {
        Write-Host "    Operacoes: $($data.operations)" -ForegroundColor White
    }
}

Write-Host "`nArquivos de log gerados:" -ForegroundColor Yellow
@("logs/microservice-a.log", "logs/amq-streams-kafka.log", "logs/microservice-b.log") | ForEach-Object {
    if (Test-Path $_) {
        $size = [math]::Round((Get-Item $_).Length / 1KB, 2)
        Write-Host "  - $_ ($size KB)" -ForegroundColor Green
    } else {
        Write-Host "  - $_ (nao encontrado)" -ForegroundColor Red
    }
}

Write-Host "`n=== MELHORIAS IMPLEMENTADAS ===" -ForegroundColor Green
Write-Host "- Identificacao de componente: MICROSERVICE-A, RED_HAT_AMQ_STREAMS, MICROSERVICE-B" -ForegroundColor White
Write-Host "- Owner do processo: LogProducerService, KafkaConsumerService, MessageProcessor" -ForegroundColor White
Write-Host "- MessageId para correlacao entre componentes" -ForegroundColor White
Write-Host "- Metricas de performance (duration, processing time)" -ForegroundColor White
Write-Host "- Logs estruturados com contexto MDC" -ForegroundColor White

Write-Host "`nPara verificar logs:" -ForegroundColor Cyan
Write-Host "  Get-Content logs/microservice-a.log" -ForegroundColor Gray
Write-Host "  Get-Content logs/amq-streams-kafka.log" -ForegroundColor Gray
Write-Host "  Get-Content logs/microservice-b.log" -ForegroundColor Gray

Write-Host "`n=== DEMONSTRACAO CONCLUIDA ===" -ForegroundColor Green
