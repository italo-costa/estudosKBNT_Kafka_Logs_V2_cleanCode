#!/usr/bin/env powershell
# =============================================================================
# KBNT KAFKA LOGS - DEPLOY ESCALÁVEL AUTOMATIZADO
# =============================================================================
# Script para deploy com escalabilidade horizontal e vertical completa
# Suporte a: Docker Compose, Kubernetes, Auto-scaling, Monitoring
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("local", "docker", "kubernetes", "hybrid")]
    [string]$Mode = "docker",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("minimal", "standard", "high-performance", "enterprise")]
    [string]$Scale = "standard",
    
    [Parameter(Mandatory=$false)]
    [switch]$Monitoring = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Cleanup = $false
)

# =============================================================================
# CONFIGURAÇÕES E CONSTANTES
# =============================================================================
$ErrorActionPreference = "Stop"
$ProjectName = "kbnt-scalable"
$DockerComposeFile = "docker-compose.scalable.yml"

$ScaleConfigurations = @{
    "minimal" = @{
        "api-gateway" = 1
        "virtual-stock-service" = 1
        "log-producer-service" = 1
        "log-consumer-service" = 1
        "kafka-brokers" = 1
        "elasticsearch-nodes" = 1
        "postgres-replicas" = 0
        "memory-limit" = "256m"
        "cpu-limit" = "0.5"
    }
    "standard" = @{
        "api-gateway" = 2
        "virtual-stock-service" = 2
        "log-producer-service" = 2
        "log-consumer-service" = 2
        "kafka-brokers" = 3
        "elasticsearch-nodes" = 2
        "postgres-replicas" = 1
        "memory-limit" = "512m"
        "cpu-limit" = "1.0"
    }
    "high-performance" = @{
        "api-gateway" = 2
        "virtual-stock-service" = 3
        "log-producer-service" = 2
        "log-consumer-service" = 2
        "kafka-brokers" = 3
        "elasticsearch-nodes" = 2
        "postgres-replicas" = 1
        "memory-limit" = "1024m"
        "cpu-limit" = "2.0"
    }
    "enterprise" = @{
        "api-gateway" = 3
        "virtual-stock-service" = 5
        "log-producer-service" = 3
        "log-consumer-service" = 3
        "kafka-brokers" = 5
        "elasticsearch-nodes" = 3
        "postgres-replicas" = 2
        "memory-limit" = "2048m"
        "cpu-limit" = "4.0"
    }
}

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================
function Write-Banner {
    param([string]$Message)
    Write-Host "`n🚀 ===============================================================================" -ForegroundColor Cyan
    Write-Host "   $Message" -ForegroundColor White
    Write-Host "🚀 ===============================================================================`n" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "⚡ $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Check-Prerequisites {
    Write-Step "Verificando pré-requisitos..."
    
    # Verificar Docker
    try {
        $dockerVersion = docker --version
        Write-Success "Docker encontrado: $dockerVersion"
    } catch {
        Write-Error "Docker não encontrado. Por favor, instale o Docker Desktop."
        exit 1
    }
    
    # Verificar Docker Compose
    try {
        $composeVersion = docker compose version
        Write-Success "Docker Compose encontrado: $composeVersion"
    } catch {
        Write-Error "Docker Compose não encontrado."
        exit 1
    }
    
    # Verificar WSL se estiver no Windows
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        try {
            wsl --version | Out-Null
            Write-Success "WSL disponível"
        } catch {
            Write-Error "WSL não encontrado. Usando Docker Desktop nativo."
        }
    }
    
    # Verificar recursos disponíveis
    Write-Step "Verificando recursos do sistema..."
    
    if ($IsWindows -or $env:OS -eq "Windows_NT") {
        try {
            $systemInfo = wsl -d Ubuntu -- bash -c "nproc && free -h | head -2 | tail -1"
            Write-Success "Recursos do sistema verificados via WSL"
        } catch {
            Write-Success "Usando recursos do Docker Desktop"
        }
    }
}

function Deploy-Infrastructure {
    param([string]$ScaleType)
    
    Write-Step "Fazendo deploy da infraestrutura em modo: $ScaleType"
    
    $config = $ScaleConfigurations[$ScaleType]
    
    # Cleanup anterior se solicitado
    if ($Cleanup) {
        Write-Step "Limpando deploy anterior..."
        docker compose -f $DockerComposeFile -p $ProjectName down -v --remove-orphans
        docker system prune -f
        Write-Success "Cleanup concluído"
    }
    
    # Build das imagens
    Write-Step "Fazendo build das imagens dos microservices..."
    docker compose -f $DockerComposeFile -p $ProjectName build --parallel
    Write-Success "Build concluído"
    
    # Deploy da infraestrutura base
    Write-Step "Fazendo deploy da infraestrutura base (PostgreSQL, Kafka, Elasticsearch)..."
    docker compose -f $DockerComposeFile -p $ProjectName up -d postgres-master zookeeper1 zookeeper2 zookeeper3 kafka1 kafka2 kafka3 elasticsearch1 elasticsearch2
    
    # Aguardar inicialização
    Write-Step "Aguardando inicialização da infraestrutura (60 segundos)..."
    Start-Sleep 60
    
    # Deploy dos microservices
    Write-Step "Fazendo deploy dos microservices..."
    docker compose -f $DockerComposeFile -p $ProjectName up -d
    
    # Aguardar inicialização completa
    Write-Step "Aguardando inicialização completa dos serviços (90 segundos)..."
    Start-Sleep 90
    
    Write-Success "Deploy da infraestrutura concluído!"
}

function Deploy-Monitoring {
    Write-Step "Fazendo deploy do sistema de monitoramento..."
    
    # Subir Prometheus e Grafana
    docker compose -f $DockerComposeFile -p $ProjectName up -d prometheus grafana
    
    Write-Success "Sistema de monitoramento disponível:"
    Write-Host "  📊 Prometheus: http://localhost:9090" -ForegroundColor Cyan
    Write-Host "  📈 Grafana: http://localhost:3000 (admin/admin123)" -ForegroundColor Cyan
    Write-Host "  📊 HAProxy Stats: http://localhost:8404/stats (admin/kbnt123)" -ForegroundColor Cyan
}

function Test-Deployment {
    Write-Step "Executando testes de verificação..."
    
    # Verificar saúde dos serviços
    $services = @(
        @{name="Load Balancer"; url="http://localhost:8404/stats"},
        @{name="API Gateway"; url="http://localhost:8090/actuator/health"},
        @{name="Virtual Stock Service"; url="http://localhost:8086/actuator/health"},
        @{name="Prometheus"; url="http://localhost:9090/-/healthy"}
    )
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.url -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Success "$($service.name) está saudável"
            }
        } catch {
            Write-Error "$($service.name) não está respondendo: $($service.url)"
        }
    }
}

function Show-Deployment-Info {
    param([string]$ScaleType)
    
    $config = $ScaleConfigurations[$ScaleType]
    
    Write-Banner "DEPLOY KBNT KAFKA LOGS - ESCALABILIDADE COMPLETA"
    
    Write-Host "📊 CONFIGURAÇÃO DE ESCALABILIDADE:" -ForegroundColor White
    Write-Host "  • Modo: $Mode" -ForegroundColor Green
    Write-Host "  • Escala: $ScaleType" -ForegroundColor Green
    Write-Host "  • API Gateways: $($config['api-gateway'])" -ForegroundColor Yellow
    Write-Host "  • Virtual Stock Services: $($config['virtual-stock-service'])" -ForegroundColor Yellow
    Write-Host "  • Log Services: $($config['log-producer-service']) produtores, $($config['log-consumer-service']) consumidores" -ForegroundColor Yellow
    Write-Host "  • Kafka Brokers: $($config['kafka-brokers'])" -ForegroundColor Yellow
    Write-Host "  • Elasticsearch Nodes: $($config['elasticsearch-nodes'])" -ForegroundColor Yellow
    Write-Host "  • PostgreSQL Replicas: $($config['postgres-replicas'])" -ForegroundColor Yellow
    
    Write-Host "`n🌐 ENDPOINTS DISPONÍVEIS:" -ForegroundColor White
    Write-Host "  • Load Balancer (HAProxy): http://localhost:8090" -ForegroundColor Cyan
    Write-Host "  • API Gateway (LoadBalanced): http://localhost:8090" -ForegroundColor Cyan
    Write-Host "  • Virtual Stock Service: http://localhost:8086" -ForegroundColor Cyan
    Write-Host "  • HAProxy Statistics: http://localhost:8404/stats" -ForegroundColor Cyan
    
    if ($Monitoring) {
        Write-Host "`n📊 MONITORAMENTO:" -ForegroundColor White
        Write-Host "  • Prometheus: http://localhost:9090" -ForegroundColor Cyan
        Write-Host "  • Grafana: http://localhost:3000" -ForegroundColor Cyan
    }
    
    Write-Host "`n⚡ RECURSOS ESTIMADOS:" -ForegroundColor White
    $totalMemory = ([int]$config['memory-limit'].Replace('m','')) * ($config['api-gateway'] + $config['virtual-stock-service'] + $config['log-producer-service'] + $config['log-consumer-service'] + $config['kafka-brokers'] + $config['elasticsearch-nodes'] + 1)
    $totalCpu = [float]$config['cpu-limit'] * ($config['api-gateway'] + $config['virtual-stock-service'] + $config['log-producer-service'] + $config['log-consumer-service'] + $config['kafka-brokers'] + $config['elasticsearch-nodes'])
    
    Write-Host "  • Memória Total: ~$([math]::Round($totalMemory/1024, 1))GB" -ForegroundColor Green
    Write-Host "  • CPU Total: ~$totalCpu cores" -ForegroundColor Green
    
    Write-Host "`n🧪 TESTE DE CARGA:" -ForegroundColor White
    Write-Host "  Execute: python virtual-stock-traffic-test.py" -ForegroundColor Yellow
    Write-Host "  Para testar throughput e escalabilidade" -ForegroundColor White
}

function Deploy-Kubernetes {
    Write-Step "Iniciando deploy no Kubernetes..."
    
    # Verificar kubectl
    try {
        kubectl version --client | Out-Null
        Write-Success "kubectl encontrado"
    } catch {
        Write-Error "kubectl não encontrado. Por favor, instale o Kubernetes CLI."
        return
    }
    
    # Apply dos manifestos Kubernetes
    if (Test-Path "kubernetes") {
        Write-Step "Aplicando manifestos Kubernetes..."
        kubectl apply -f kubernetes/ -R
        
        # Aguardar pods ficarem ready
        Write-Step "Aguardando pods ficarem prontos..."
        kubectl wait --for=condition=ready pod --all --timeout=300s
        
        Write-Success "Deploy Kubernetes concluído!"
    } else {
        Write-Error "Diretório kubernetes/ não encontrado"
    }
}

# =============================================================================
# SCRIPT PRINCIPAL
# =============================================================================
try {
    Write-Banner "KBNT KAFKA LOGS - DEPLOY ESCALÁVEL"
    
    Check-Prerequisites
    
    switch ($Mode) {
        "docker" {
            Deploy-Infrastructure $Scale
            if ($Monitoring) {
                Deploy-Monitoring
            }
            Test-Deployment
            Show-Deployment-Info $Scale
        }
        "kubernetes" {
            Deploy-Kubernetes
            Show-Deployment-Info $Scale
        }
        "hybrid" {
            Deploy-Infrastructure $Scale
            Deploy-Kubernetes
            if ($Monitoring) {
                Deploy-Monitoring
            }
            Test-Deployment
            Show-Deployment-Info $Scale
        }
        default {
            Write-Error "Modo não suportado: $Mode"
            exit 1
        }
    }
    
    Write-Banner "DEPLOY CONCLUÍDO COM SUCESSO!"
    
} catch {
    Write-Error "Erro durante o deploy: $_"
    Write-Host "Para fazer cleanup: docker compose -f $DockerComposeFile down -v" -ForegroundColor Yellow
    exit 1
}
