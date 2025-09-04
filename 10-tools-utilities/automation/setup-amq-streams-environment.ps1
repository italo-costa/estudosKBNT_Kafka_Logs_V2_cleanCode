#!/usr/bin/env powershell
<#
.SYNOPSIS
    Configura ambiente Red Hat AMQ Streams simulado com Docker
    
.DESCRIPTION
    Este script configura um ambiente completo Kafka que simula o Red Hat AMQ Streams
    usando Docker Compose. Inclui todos os componentes necessários para desenvolvimento
    e testes do sistema KBNT Virtual Stock Management.
    
.PARAMETER Action
    Ação a ser executada: start, stop, restart, status, logs
    
.PARAMETER Verbose
    Mostra saída detalhada
    
.EXAMPLE
    .\setup-amq-streams-environment.ps1 -Action start -Verbose
    
.NOTES
    Requer Docker Desktop instalado e funcionando
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "cleanup")]
    [string]$Action = "start",
    
    [switch]$Verbose
)

# Configurações
$DockerComposeFile = "docker-compose-amq-streams.yml"
$ProjectName = "kbnt-kafka"
$RequiredPorts = @(2181, 8080, 8081, 8082, 8083, 9092, 9101)

# Tópicos que serão criados
$KafkaTopics = @(
    @{Name="user-events"; Partitions=3; Replication=1},
    @{Name="order-events"; Partitions=3; Replication=1},
    @{Name="payment-events"; Partitions=3; Replication=1},
    @{Name="inventory-events"; Partitions=3; Replication=1},
    @{Name="notification-events"; Partitions=3; Replication=1},
    @{Name="audit-logs"; Partitions=1; Replication=1},
    @{Name="application-logs"; Partitions=2; Replication=1}
)

function Write-Banner {
    param([string]$Text)
    
    Write-Host ""
    Write-Host "="*70 -ForegroundColor Cyan
    Write-Host $Text.PadLeft(($Text.Length + 70)/2).PadRight(70) -ForegroundColor Yellow
    Write-Host "="*70 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Step, [string]$Description)
    
    Write-Host "🔄 STEP $Step`: " -NoNewline -ForegroundColor Green
    Write-Host $Description -ForegroundColor White
}

function Test-DockerAvailable {
    Write-Step "1" "Verificando Docker..."
    
    try {
        $dockerVersion = docker --version
        if ($LASTEXITCODE -ne 0) {
            throw "Docker não encontrado"
        }
        
        Write-Host "   ✅ Docker disponível: $dockerVersion" -ForegroundColor Green
        
        # Verifica se Docker está rodando
        docker info | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker não está rodando"
        }
        
        Write-Host "   ✅ Docker daemon rodando" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "   ❌ Erro: $_" -ForegroundColor Red
        Write-Host "   💡 Instale o Docker Desktop e inicie o serviço" -ForegroundColor Yellow
        return $false
    }
}

function Test-PortsAvailable {
    Write-Step "2" "Verificando portas necessárias..."
    
    $usedPorts = @()
    foreach ($port in $RequiredPorts) {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($connection) {
            $usedPorts += $port
        }
    }
    
    if ($usedPorts.Count -gt 0) {
        Write-Host "   ⚠️  Portas em uso: $($usedPorts -join ', ')" -ForegroundColor Yellow
        Write-Host "   💡 Pode ser necessário parar outros serviços" -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "   ✅ Todas as portas estão disponíveis" -ForegroundColor Green
        return $true
    }
}

function Start-KafkaEnvironment {
    Write-Banner "INICIANDO AMBIENTE RED HAT AMQ STREAMS SIMULADO"
    
    if (-not (Test-DockerAvailable)) {
        return $false
    }
    
    Test-PortsAvailable | Out-Null
    
    Write-Step "3" "Iniciando containers Docker Compose..."
    
    try {
        if ($Verbose) {
            docker-compose -f $DockerComposeFile -p $ProjectName up -d --build
        } else {
            docker-compose -f $DockerComposeFile -p $ProjectName up -d --build | Out-Null
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao iniciar containers"
        }
        
        Write-Host "   ✅ Containers iniciados com sucesso" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Erro: $_" -ForegroundColor Red
        return $false
    }
    
    Write-Step "4" "Aguardando inicialização dos serviços..."
    
    # Aguarda Kafka ficar pronto
    $maxAttempts = 30
    $attempt = 0
    $kafkaReady = $false
    
    do {
        $attempt++
        Write-Host "   🔍 Tentativa $attempt/$maxAttempts - Verificando Kafka..." -ForegroundColor Cyan
        
        try {
            $result = docker exec kbnt-kafka kafka-topics --bootstrap-server localhost:9092 --list 2>$null
            if ($LASTEXITCODE -eq 0) {
                $kafkaReady = $true
                Write-Host "   ✅ Kafka está pronto!" -ForegroundColor Green
                break
            }
        }
        catch {
            # Continua tentando
        }
        
        Start-Sleep -Seconds 5
    } while ($attempt -lt $maxAttempts -and -not $kafkaReady)
    
    if (-not $kafkaReady) {
        Write-Host "   ❌ Timeout esperando Kafka ficar pronto" -ForegroundColor Red
        return $false
    }
    
    Write-Step "5" "Criando tópicos Kafka..."
    
    foreach ($topic in $KafkaTopics) {
        try {
            Write-Host "   📝 Criando tópico: $($topic.Name)" -ForegroundColor Cyan
            
            docker exec kbnt-kafka kafka-topics --create `
                --topic $($topic.Name) `
                --bootstrap-server localhost:9092 `
                --partitions $($topic.Partitions) `
                --replication-factor $($topic.Replication) `
                --if-not-exists | Out-Null
                
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Tópico $($topic.Name) criado" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️  Tópico $($topic.Name) já existe ou erro na criação" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "   ❌ Erro criando tópico $($topic.Name): $_" -ForegroundColor Red
        }
    }
    
    Write-Step "6" "Verificando status dos serviços..."
    
    Show-ServiceStatus
    
    Write-Host ""
    Write-Host "🎉 AMBIENTE PRONTO!" -ForegroundColor Green
    Write-Host "📋 Interfaces disponíveis:" -ForegroundColor Cyan
    Write-Host "   • Kafka UI:        http://localhost:8080" -ForegroundColor White
    Write-Host "   • Schema Registry: http://localhost:8081" -ForegroundColor White  
    Write-Host "   • Kafka REST:      http://localhost:8082" -ForegroundColor White
    Write-Host "   • Connect API:     http://localhost:8083" -ForegroundColor White
    Write-Host "   • Kafka Broker:    localhost:9092" -ForegroundColor White
    Write-Host ""
    
    return $true
}

function Stop-KafkaEnvironment {
    Write-Banner "PARANDO AMBIENTE RED HAT AMQ STREAMS"
    
    Write-Step "1" "Parando containers..."
    
    try {
        docker-compose -f $DockerComposeFile -p $ProjectName down
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Containers parados com sucesso" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Alguns containers podem não ter parado corretamente" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   ❌ Erro: $_" -ForegroundColor Red
    }
}

function Show-ServiceStatus {
    Write-Step "INFO" "Status dos serviços..."
    
    $services = @(
        @{Name="Zookeeper"; Container="kbnt-zookeeper"; Port=2181},
        @{Name="Kafka"; Container="kbnt-kafka"; Port=9092},
        @{Name="Schema Registry"; Container="kbnt-schema-registry"; Port=8081},
        @{Name="Kafka Connect"; Container="kbnt-kafka-connect"; Port=8083},
        @{Name="Kafka UI"; Container="kbnt-kafka-ui"; Port=8080},
        @{Name="Kafka REST"; Container="kbnt-kafka-rest"; Port=8082}
    )
    
    foreach ($service in $services) {
        $container = docker ps --filter "name=$($service.Container)" --format "table {{.Names}}\t{{.Status}}" | Select-Object -Skip 1
        
        if ($container) {
            $status = ($container -split '\t')[1]
            if ($status -match "Up") {
                Write-Host "   ✅ $($service.Name): $status" -ForegroundColor Green
            } else {
                Write-Host "   ❌ $($service.Name): $status" -ForegroundColor Red
            }
        } else {
            Write-Host "   ❌ $($service.Name): Container não encontrado" -ForegroundColor Red
        }
    }
    
    # Lista tópicos
    try {
        Write-Host ""
        Write-Host "   📝 Tópicos Kafka:" -ForegroundColor Cyan
        $topics = docker exec kbnt-kafka kafka-topics --bootstrap-server localhost:9092 --list 2>$null
        if ($LASTEXITCODE -eq 0 -and $topics) {
            $topics -split "`n" | Where-Object { $_ -ne "" } | ForEach-Object {
                Write-Host "      • $_" -ForegroundColor White
            }
        } else {
            Write-Host "      ⚠️  Não foi possível listar tópicos" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "      ❌ Erro listando tópicos: $_" -ForegroundColor Red
    }
}

function Show-Logs {
    Write-Banner "LOGS DO AMBIENTE KAFKA"
    
    Write-Host "🔍 Mostrando logs dos últimos containers..." -ForegroundColor Cyan
    docker-compose -f $DockerComposeFile -p $ProjectName logs --tail=50 -f
}

function Cleanup-Environment {
    Write-Banner "LIMPEZA COMPLETA DO AMBIENTE"
    
    Write-Step "1" "Parando e removendo containers..."
    docker-compose -f $DockerComposeFile -p $ProjectName down -v --remove-orphans
    
    Write-Step "2" "Removendo volumes..."
    docker volume prune -f
    
    Write-Step "3" "Removendo redes..."
    docker network prune -f
    
    Write-Host "   ✅ Limpeza concluída" -ForegroundColor Green
}

# Execução principal
switch ($Action.ToLower()) {
    "start" {
        Start-KafkaEnvironment | Out-Null
    }
    "stop" {
        Stop-KafkaEnvironment
    }
    "restart" {
        Stop-KafkaEnvironment
        Start-Sleep -Seconds 3
        Start-KafkaEnvironment | Out-Null
    }
    "status" {
        Write-Banner "STATUS DO AMBIENTE RED HAT AMQ STREAMS"
        Show-ServiceStatus
    }
    "logs" {
        Show-Logs
    }
    "cleanup" {
        Cleanup-Environment
    }
    default {
        Write-Host "Uso: .\setup-amq-streams-environment.ps1 -Action [start|stop|restart|status|logs|cleanup]" -ForegroundColor Yellow
    }
}

Write-Host ""
