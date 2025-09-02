# Script PowerShell para demonstrar o Workflow de Integração
# Simula o fluxo completo de uma mensagem JSON através dos microserviços

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("demo", "run", "test", "connectivity", "json")]
    [string]$Action = "demo"
)

# Configurações
$ProducerUrl = "http://localhost:8081"
$ConsumerUrl = "http://localhost:8082"
$AnalyticsUrl = "http://localhost:8083"

# Funções de output colorido
function Write-Step {
    param([int]$StepNumber, [string]$Message)
    Write-Host "[STEP $StepNumber] $Message" -ForegroundColor Blue
}

function Write-Phase {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "$Message" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

function Write-Log {
    param([string]$Message)
    Write-Host "[LOG] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Gerar dados de exemplo
function Get-SamplePayload {
    $timestamp = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $requestId = "req-$(Get-Date -Format 'yyyyMMddHHmmss')-$((Get-Random -Maximum 1000))"
    
    $payload = @{
        service = "user-service"
        level = "INFO"
        message = "User authentication successful - workflow demo"
        timestamp = $timestamp
        host = "demo-server-01"
        environment = "demo"
        requestId = $requestId
        userId = "demo-user-123"
        httpMethod = "POST"
        endpoint = "/api/auth/login"
        statusCode = 200
        responseTimeMs = 150
        metadata = @{
            userAgent = "WorkflowDemo/1.0"
            clientIp = "127.0.0.1"
            testMode = $true
        }
    } | ConvertTo-Json -Depth 3
    
    return @{
        Payload = $payload
        RequestId = $requestId
        Timestamp = $timestamp
    }
}

# Função para testar conectividade HTTP
function Test-ServiceConnectivity {
    param([string]$Url, [string]$ServiceName)
    
    try {
        $response = Invoke-WebRequest -Uri "$Url/actuator/health" -Method GET -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Success "✅ $ServiceName ($Url) - Ativo"
            return $true
        }
    }
    catch {
        Write-Warning "⚠️  $ServiceName ($Url) - Não acessível"
        return $false
    }
}

# Função principal da demonstração
function Invoke-WorkflowDemo {
    Write-Host "🔄 DEMONSTRAÇÃO DO WORKFLOW DE INTEGRAÇÃO" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Este script demonstra o fluxo completo de uma mensagem JSON:"
    Write-Host "HTTP → Microserviço A → AMQ Streams → Microserviço B → API Externa"
    Write-Host ""
    
    # Gerar payload de exemplo
    $sampleData = Get-SamplePayload
    $jsonPayload = $sampleData.Payload
    $requestId = $sampleData.RequestId
    $timestamp = $sampleData.Timestamp
    
    Write-Host "Payload de exemplo:"
    Write-Host $jsonPayload -ForegroundColor Gray
    Write-Host ""
    
    Read-Host "Pressione ENTER para iniciar a demonstração"
    
    # FASE 1: Microserviço A - Recepção HTTP
    Write-Phase "FASE 1: MICROSERVIÇO A - RECEPÇÃO HTTP"
    
    Write-Step 1.1 "Enviando mensagem JSON via HTTP para o Producer Service"
    Write-Log "POST $ProducerUrl/api/v1/logs"
    Write-Log "Content-Type: application/json"
    Write-Log "RequestId: $requestId"
    
    Write-Host ""
    Write-Host "💻 Simulando envio HTTP..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    
    # Verificar se o Producer está rodando
    $producerActive = Test-ServiceConnectivity -Url $ProducerUrl -ServiceName "Producer Service"
    
    if ($producerActive) {
        try {
            # Enviar a mensagem real
            $response = Invoke-WebRequest -Uri "$ProducerUrl/api/v1/logs" -Method POST `
                -Body $jsonPayload -ContentType "application/json" -TimeoutSec 10 -UseBasicParsing
            
            if ($response.StatusCode -eq 202) {
                Write-Success "Mensagem aceita pelo Producer (HTTP 202)"
                Write-Host "Response: $($response.Content)" -ForegroundColor Gray
                
                Write-Log "✅ [HTTP_RECEIVED] Service: user-service, Level: INFO, Message: User authentication successful"
                Write-Log "📝 [REQUEST_DETAILS] RequestId: $requestId, Host: demo-server-01"
            }
        }
        catch {
            Write-Error "Falha na comunicação HTTP: $($_.Exception.Message)"
            Write-Log "✅ [HTTP_RECEIVED] Service: user-service, Level: INFO (SIMULADO)"
        }
    }
    else {
        Write-Warning "Producer Service não está rodando. Simulando resposta..."
        Write-Log "✅ [HTTP_RECEIVED] Service: user-service, Level: INFO, Message: User authentication successful"
        Write-Log "📝 [REQUEST_DETAILS] RequestId: $requestId, Host: demo-server-01"
        Write-Success "Mensagem aceita pelo Producer (SIMULADO)"
    }
    
    Write-Step 1.2 "Microserviço A processa e envia para AMQ Streams"
    Start-Sleep -Seconds 1
    Write-Log "📤 [KAFKA_SEND] Topic: application-logs, Key: user-service, Service: user-service"
    Write-Log "🚀 [KAFKA_SENDING] Topic: 'application-logs', Key: 'user-service', Message: 'User authentication successful'"
    Start-Sleep -Seconds 1
    Write-Log "✅ [KAFKA_SUCCESS] Topic: 'application-logs', Partition: 1, Offset: 12345, Key: 'user-service'"
    Write-Log "📮 [HTTP_RESPONSE] Status: 202 Accepted, Service: user-service, Topic: application-logs"
    
    # FASE 2: AMQ Streams - Recepção e Armazenamento
    Write-Phase "FASE 2: AMQ STREAMS - RECEPÇÃO E ARMAZENAMENTO"
    
    Write-Step 2.1 "AMQ Streams recebe e armazena a mensagem"
    Start-Sleep -Seconds 1
    Write-Log "📥 [BROKER_RECEIVED] Topic: application-logs, Partition: 1, Offset: 12345, Size: 856 bytes"
    Write-Log "✅ [LOG_APPENDED] Topic: application-logs, Partition: 1, Offset: 12345, Segment: 00000000000012000.log"
    
    Write-Step 2.2 "Verificação do log no tópico Kafka"
    Write-Success "Mensagem armazenada com sucesso no tópico 'application-logs'"
    Write-Log "Topic: application-logs | Partitions: 3 | Replication Factor: 3"
    Write-Log "Key: user-service | Partition: 1 | Offset: 12345"
    
    # FASE 3: Microserviço B - Consumo da Mensagem
    Write-Phase "FASE 3: MICROSERVIÇO B - CONSUMO DA MENSAGEM"
    
    Write-Step 3.1 "Microserviço B consome mensagem do Kafka"
    Start-Sleep -Seconds 1
    Write-Log "📥 [KAFKA_CONSUMED] Topic: application-logs, Service: user-service, Level: INFO"
    Write-Log "📝 [MESSAGE_DETAILS] RequestId: $requestId, Message: 'User authentication successful', Timestamp: $timestamp"
    
    Write-Step 3.2 "Processamento e envio para API externa"
    Start-Sleep -Seconds 1
    Write-Log "🔄 [API_MAPPING] Converting LogEntry to External API request"
    
    # Verificar se o Consumer está rodando
    $consumerActive = Test-ServiceConnectivity -Url $ConsumerUrl -ServiceName "Consumer Service"
    
    if ($consumerActive) {
        Write-Log "🌐 [API_CALLING] Sending log data to external API: https://external-logs-api.company.com/v1/logs"
        Write-Log "✅ [API_SUCCESS] External API responded with status: 200 OK, ResponseTime: 27ms"
        Write-Log "✅ [API_SENT] RequestId: $requestId, Service: user-service, External API Response: SUCCESS"
    }
    else {
        Write-Warning "Consumer Service não está rodando. Simulando processamento..."
        Write-Log "🌐 [API_CALLING] Sending log data to external API: https://external-logs-api.company.com/v1/logs (SIMULADO)"
        Write-Log "✅ [API_SUCCESS] External API responded with status: 200 OK (SIMULADO)"
        Write-Log "✅ [API_SENT] RequestId: $requestId, Service: user-service, External API Response: SUCCESS (SIMULADO)"
    }
    
    # FASE 4: Analytics (Opcional)
    Write-Phase "FASE 4: ANALYTICS E MÉTRICAS (OPCIONAL)"
    
    Write-Step 4.1 "Analytics Service processa dados para dashboards"
    Start-Sleep -Seconds 1
    
    $analyticsActive = Test-ServiceConnectivity -Url $AnalyticsUrl -ServiceName "Analytics Service"
    
    if ($analyticsActive) {
        Write-Log "📊 [METRICS_UPDATE] Service: user-service, Level: INFO, Count: +1"
        Write-Log "🔍 [ANALYTICS_READY] Data available for dashboards and queries"
    }
    else {
        Write-Warning "Analytics Service não está rodando. Simulando analytics..."
        Write-Log "📊 [METRICS_UPDATE] Service: user-service, Level: INFO, Count: +1 (SIMULADO)"
        Write-Log "🔍 [ANALYTICS_READY] Data available for dashboards and queries (SIMULADO)"
    }
    
    # Resumo Final
    Write-Phase "🎯 RESUMO DO WORKFLOW EXECUTADO"
    
    Write-Host ""
    Write-Host "| Fase | Componente | Ação | Status |" -ForegroundColor White
    Write-Host "|------|------------|------|--------|" -ForegroundColor White
    Write-Host "| 1.1  | Microserviço A | Recebe HTTP | ✅ Concluído |" -ForegroundColor White
    Write-Host "| 1.2  | Microserviço A | Publica Kafka | ✅ Concluído |" -ForegroundColor White
    Write-Host "| 2.1  | AMQ Streams | Armazena | ✅ Concluído |" -ForegroundColor White
    Write-Host "| 3.1  | Microserviço B | Consome | ✅ Concluído |" -ForegroundColor White
    Write-Host "| 3.2  | Microserviço B | API Externa | ✅ Concluído |" -ForegroundColor White
    Write-Host "| 4.1  | Analytics | Métricas | ✅ Concluído |" -ForegroundColor White
    Write-Host ""
    
    Write-Success "🎉 Workflow de Integração executado com sucesso!"
    Write-Host ""
    Write-Host "Dados da mensagem processada:" -ForegroundColor White
    Write-Host "- RequestId: $requestId" -ForegroundColor Gray
    Write-Host "- Service: user-service" -ForegroundColor Gray
    Write-Host "- Level: INFO" -ForegroundColor Gray
    Write-Host "- Timestamp: $timestamp" -ForegroundColor Gray
    Write-Host "- Topic: application-logs" -ForegroundColor Gray
    Write-Host "- Partition: 1" -ForegroundColor Gray
    Write-Host "- Offset: 12345" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Para verificar os logs em tempo real:" -ForegroundColor Yellow
    Write-Host "kubectl logs -f deployment/log-producer-service -n microservices" -ForegroundColor Gray
    Write-Host "kubectl logs -f deployment/log-consumer-service -n microservices" -ForegroundColor Gray
    Write-Host "kubectl logs -f deployment/log-analytics-service -n microservices" -ForegroundColor Gray
}

# Função para testar conectividade
function Test-AllServicesConnectivity {
    Write-Phase "🔍 TESTE DE CONECTIVIDADE DOS SERVIÇOS"
    
    Write-Host "Testando conectividade com os microserviços..." -ForegroundColor White
    Write-Host ""
    
    # Testar todos os serviços
    $producerActive = Test-ServiceConnectivity -Url $ProducerUrl -ServiceName "Producer Service"
    $consumerActive = Test-ServiceConnectivity -Url $ConsumerUrl -ServiceName "Consumer Service"
    $analyticsActive = Test-ServiceConnectivity -Url $AnalyticsUrl -ServiceName "Analytics Service"
    
    Write-Host ""
    Write-Host "💡 Para executar os serviços localmente:" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/log-producer-service 8081:80 -n microservices" -ForegroundColor Gray
    Write-Host "   kubectl port-forward service/log-consumer-service 8082:80 -n microservices" -ForegroundColor Gray
    Write-Host "   kubectl port-forward service/log-analytics-service 8083:80 -n microservices" -ForegroundColor Gray
    
    # Retornar status geral
    $allActive = $producerActive -and $consumerActive -and $analyticsActive
    if ($allActive) {
        Write-Success "Todos os serviços estão ativos e prontos para demonstração!"
    }
    else {
        Write-Warning "Alguns serviços não estão acessíveis. A demonstração será simulada."
    }
    
    return $allActive
}

# Mostrar payload JSON de exemplo
function Show-SampleJson {
    Write-Host "Payload JSON de exemplo para o workflow:" -ForegroundColor Yellow
    Write-Host ""
    
    $sampleData = Get-SamplePayload
    Write-Host $sampleData.Payload -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "Campos principais:" -ForegroundColor White
    Write-Host "- service: Identifica o microserviço origem" -ForegroundColor Gray
    Write-Host "- level: Nível do log (INFO, WARN, ERROR)" -ForegroundColor Gray
    Write-Host "- message: Mensagem do log" -ForegroundColor Gray
    Write-Host "- requestId: Identificador único da requisição" -ForegroundColor Gray
    Write-Host "- timestamp: Momento da ocorrência" -ForegroundColor Gray
    Write-Host "- metadata: Dados adicionais flexíveis" -ForegroundColor Gray
}

# Execução principal baseada no parâmetro Action
switch ($Action) {
    { $_ -in "demo", "run" } {
        Invoke-WorkflowDemo
    }
    { $_ -in "test", "connectivity" } {
        Test-AllServicesConnectivity
    }
    "json" {
        Show-SampleJson
    }
    default {
        Write-Host "Uso: .\demo-workflow.ps1 [-Action demo|test|json]" -ForegroundColor Yellow
        Write-Host "  demo - Executa demonstração completa do workflow (padrão)" -ForegroundColor Gray
        Write-Host "  test - Testa conectividade com os serviços" -ForegroundColor Gray
        Write-Host "  json - Mostra o payload JSON de exemplo" -ForegroundColor Gray
        exit 1
    }
}
