# PowerShell Script para Deploy Híbrido
# Microserviços em Kubernetes Local conectando ao AMQ Streams Externo

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("deploy", "cleanup", "test")]
    [string]$Action = "deploy",
    
    [Parameter(Mandatory=$false)]
    [string]$KafkaExternalHost = $env:KAFKA_EXTERNAL_HOST,
    
    [Parameter(Mandatory=$false)]
    [string]$KafkaUsername = $env:KAFKA_USERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$KafkaPassword = $env:KAFKA_PASSWORD
)

# Variáveis de configuração
$Namespace = "microservices"
$DefaultKafkaHost = "your-redhat-kafka-host:9092"
$DefaultKafkaUsername = "microservices-user"
$DefaultKafkaPassword = "your-password"

# Definir valores padrão se não fornecidos
if ([string]::IsNullOrEmpty($KafkaExternalHost)) { $KafkaExternalHost = $DefaultKafkaHost }
if ([string]::IsNullOrEmpty($KafkaUsername)) { $KafkaUsername = $DefaultKafkaUsername }
if ([string]::IsNullOrEmpty($KafkaPassword)) { $KafkaPassword = $DefaultKafkaPassword }

# Funções de output colorido
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
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

# Verificar pré-requisitos
function Test-Prerequisites {
    Write-Status "Verificando pré-requisitos..."
    
    # Verificar kubectl
    try {
        $null = kubectl version --client --short 2>$null
    }
    catch {
        Write-Error "kubectl não está instalado ou não está no PATH"
        exit 1
    }
    
    # Verificar docker
    try {
        $null = docker version --format "{{.Client.Version}}" 2>$null
    }
    catch {
        Write-Error "docker não está instalado ou não está rodando"
        exit 1
    }
    
    # Verificar conexão com cluster
    try {
        $null = kubectl cluster-info --request-timeout=10s 2>$null
    }
    catch {
        Write-Error "Não foi possível conectar ao cluster Kubernetes"
        exit 1
    }
    
    Write-Success "Pré-requisitos verificados"
}

# Construir imagens Docker
function Build-DockerImages {
    Write-Status "Construindo imagens Docker..."
    
    $currentLocation = Get-Location
    
    # Producer Service
    $producerPath = Join-Path (Split-Path $PWD -Parent) "microservices\log-producer-service"
    if (Test-Path $producerPath) {
        Write-Status "Construindo log-producer-service..."
        Set-Location $producerPath
        docker build -t log-producer-service:latest . | Out-Host
        Set-Location $currentLocation
        Write-Success "log-producer-service construído"
    } else {
        Write-Warning "Diretório log-producer-service não encontrado: $producerPath"
    }
    
    # Consumer Service
    $consumerPath = Join-Path (Split-Path $PWD -Parent) "microservices\log-consumer-service"
    if (Test-Path $consumerPath) {
        Write-Status "Construindo log-consumer-service..."
        Set-Location $consumerPath
        docker build -t log-consumer-service:latest . | Out-Host
        Set-Location $currentLocation
        Write-Success "log-consumer-service construído"
    } else {
        Write-Warning "Diretório log-consumer-service não encontrado: $consumerPath"
    }
    
    # Analytics Service
    $analyticsPath = Join-Path (Split-Path $PWD -Parent) "microservices\log-analytics-service"
    if (Test-Path $analyticsPath) {
        Write-Status "Construindo log-analytics-service..."
        Set-Location $analyticsPath
        docker build -t log-analytics-service:latest . | Out-Host
        Set-Location $currentLocation
        Write-Success "log-analytics-service construído"
    } else {
        Write-Warning "Diretório log-analytics-service não encontrado: $analyticsPath"
    }
}

# Configurar secrets e configmaps
function Set-KubernetesSecrets {
    Write-Status "Configurando secrets e configmaps..."
    
    # Atualizar ConfigMap com configurações reais
    if ($KafkaExternalHost -ne $DefaultKafkaHost) {
        $patchData = @{
            data = @{
                "bootstrap-servers" = $KafkaExternalHost
            }
        } | ConvertTo-Json -Compress
        
        kubectl patch configmap kafka-external-config -n $Namespace --type merge -p $patchData
        Write-Success "Bootstrap servers atualizados: $KafkaExternalHost"
    } else {
        Write-Warning "KAFKA_EXTERNAL_HOST não foi definido. Use: `$env:KAFKA_EXTERNAL_HOST='your-host:9092'"
    }
    
    # Atualizar credenciais se fornecidas
    if ($KafkaUsername -ne $DefaultKafkaUsername -or $KafkaPassword -ne $DefaultKafkaPassword) {
        $credentialsData = @{
            stringData = @{
                "kafka-username" = $KafkaUsername
                "kafka-password" = $KafkaPassword
            }
        } | ConvertTo-Json -Compress
        
        kubectl patch secret kafka-external-credentials -n $Namespace --type merge -p $credentialsData
        Write-Success "Credenciais Kafka atualizadas"
    } else {
        Write-Warning "Credenciais padrão sendo usadas. Defina: `$env:KAFKA_USERNAME e `$env:KAFKA_PASSWORD"
    }
}

# Deploy da infraestrutura
function Deploy-Infrastructure {
    Write-Status "Fazendo deploy da infraestrutura..."
    
    # Aplicar manifestos de infraestrutura
    kubectl apply -f infrastructure.yaml | Out-Host
    
    Write-Status "Aguardando infraestrutura ficar pronta..."
    kubectl wait --for=condition=ready pod -l app=postgres -n $Namespace --timeout=120s | Out-Host
    kubectl wait --for=condition=ready pod -l app=redis -n $Namespace --timeout=60s | Out-Host
    
    Write-Success "Infraestrutura deployada com sucesso"
}

# Deploy dos microserviços
function Deploy-Microservices {
    Write-Status "Fazendo deploy dos microserviços..."
    
    # Aplicar manifestos de microserviços
    kubectl apply -f microservices.yaml | Out-Host
    
    Write-Status "Aguardando microserviços ficarem prontos..."
    
    # Aguardar deployments
    kubectl wait --for=condition=available deployment/log-producer-service -n $Namespace --timeout=180s | Out-Host
    kubectl wait --for=condition=available deployment/log-consumer-service -n $Namespace --timeout=180s | Out-Host
    kubectl wait --for=condition=available deployment/log-analytics-service -n $Namespace --timeout=180s | Out-Host
    
    Write-Success "Microserviços deployados com sucesso"
}

# Teste de conectividade
function Test-Connectivity {
    Write-Status "Testando conectividade..."
    
    # Testar conectividade com Kafka externo
    Write-Status "Testando conectividade com AMQ Streams..."
    
    # Port-forward para testar o producer
    $job = Start-Job -ScriptBlock {
        kubectl port-forward service/log-producer-service 8080:80 -n microservices
    }
    
    Start-Sleep -Seconds 10
    
    # Teste básico do health endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Success "Producer service está respondendo"
        }
    }
    catch {
        Write-Warning "Producer service não está respondendo na porta 8080"
    }
    
    # Cleanup port-forward
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -ErrorAction SilentlyContinue
    
    # Mostrar status dos pods
    Write-Status "Status dos pods:"
    kubectl get pods -n $Namespace | Out-Host
    
    Write-Status "Status dos services:"
    kubectl get svc -n $Namespace | Out-Host
}

# Mostrar informações de acesso
function Show-AccessInfo {
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "🎯 Informações de Acesso" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    
    Write-Host "Para acessar os serviços localmente:" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 Producer Service (REST API):" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/log-producer-service 8080:80 -n $Namespace" -ForegroundColor Gray
    Write-Host "   http://localhost:8080/actuator/health" -ForegroundColor Gray
    Write-Host "   http://localhost:8080/api/logs/send" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📊 Consumer Service:" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/log-consumer-service 8081:80 -n $Namespace" -ForegroundColor Gray
    Write-Host "   http://localhost:8081/actuator/health" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📊 Analytics Service:" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/log-analytics-service 8082:80 -n $Namespace" -ForegroundColor Gray
    Write-Host "   http://localhost:8082/actuator/health" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔍 Monitoramento:" -ForegroundColor Yellow
    Write-Host "   kubectl logs -f deployment/log-producer-service -n $Namespace" -ForegroundColor Gray
    Write-Host "   kubectl logs -f deployment/log-consumer-service -n $Namespace" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🗄️  Database (PostgreSQL):" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/postgres-service 5432:5432 -n $Namespace" -ForegroundColor Gray
    Write-Host "   psql -h localhost -U loguser -d loganalytics" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔴 Redis:" -ForegroundColor Yellow
    Write-Host "   kubectl port-forward service/redis-service 6379:6379 -n $Namespace" -ForegroundColor Gray
    Write-Host "   redis-cli -h localhost" -ForegroundColor Gray
}

# Função principal de deploy
function Invoke-Deploy {
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "🚀 Deploy Híbrido - AMQ Streams + Microserviços" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    
    Write-Host "Iniciando deploy híbrido..." -ForegroundColor White
    Write-Host "Namespace: $Namespace" -ForegroundColor White
    Write-Host "Kafka Host: $KafkaExternalHost" -ForegroundColor White
    Write-Host ""
    
    Test-Prerequisites
    
    # Criar namespace se não existir
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f - | Out-Host
    
    Build-DockerImages
    Deploy-Infrastructure
    Set-KubernetesSecrets
    Deploy-Microservices
    Test-Connectivity
    Show-AccessInfo
    
    Write-Success "Deploy híbrido concluído com sucesso! 🎉"
}

# Função de cleanup
function Invoke-Cleanup {
    Write-Status "Limpando recursos..."
    kubectl delete namespace $Namespace --ignore-not-found=true | Out-Host
    Write-Success "Recursos removidos"
}

# Execução principal baseada no parâmetro Action
switch ($Action) {
    "deploy" {
        Invoke-Deploy
    }
    "cleanup" {
        Invoke-Cleanup
    }
    "test" {
        Test-Connectivity
    }
    default {
        Write-Host "Uso: .\deploy.ps1 [-Action deploy|cleanup|test]" -ForegroundColor Yellow
        Write-Host "  deploy  - Deploy completo (padrão)" -ForegroundColor Gray
        Write-Host "  cleanup - Remove todos os recursos" -ForegroundColor Gray
        Write-Host "  test    - Testa conectividade" -ForegroundColor Gray
        exit 1
    }
}
