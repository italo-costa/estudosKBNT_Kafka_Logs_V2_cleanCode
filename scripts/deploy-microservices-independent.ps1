# Independent Microservices Deployment Script

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Independent Microservices Deployment..." -ForegroundColor Green

# Configuration
$DOCKER_COMPOSE_FILE = "docker\docker-compose.microservices.yml"
$NAMESPACE = "microservices"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to check if port is available
function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

# Function to wait for service health
function Wait-ForServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthUrl,
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 10
    )
    
    Write-Host "⏳ Waiting for $ServiceName to be healthy..." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $HealthUrl -Method GET -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ $ServiceName is healthy!" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "🔄 Attempt $i/$MaxAttempts - $ServiceName not ready yet..." -ForegroundColor Yellow
        }
        
        if ($i -lt $MaxAttempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    Write-Host "❌ $ServiceName failed to become healthy within timeout" -ForegroundColor Red
    return $false
}

# Check prerequisites
Write-Host "🔍 Checking prerequisites..." -ForegroundColor Cyan

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found. Please install Docker first." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Compose not found. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $DOCKER_COMPOSE_FILE)) {
    Write-Host "❌ Docker Compose file not found: $DOCKER_COMPOSE_FILE" -ForegroundColor Red
    exit 1
}

# Check port availability
$ports = @(8080, 8081, 8082, 9092, 2181)
$portsInUse = @()

foreach ($port in $ports) {
    if (Test-Port $port) {
        $portsInUse += $port
    }
}

if ($portsInUse.Count -gt 0) {
    Write-Host "⚠️  Warning: The following ports are already in use: $($portsInUse -join ', ')" -ForegroundColor Yellow
    Write-Host "Do you want to continue? Existing services may conflict. (y/N): " -NoNewline -ForegroundColor Yellow
    $continue = Read-Host
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "Deployment cancelled." -ForegroundColor Gray
        exit 0
    }
}

# Build and start services
Write-Host "🏗️  Building and starting microservices..." -ForegroundColor Cyan

try {
    # Start infrastructure first
    Write-Host "📦 Starting infrastructure services..." -ForegroundColor Blue
    docker-compose -f $DOCKER_COMPOSE_FILE up -d zookeeper kafka kafka-ui
    
    # Wait for Kafka to be ready
    if (-not (Wait-ForServiceHealth "Kafka" "http://localhost:8080" 20 15)) {
        Write-Host "❌ Infrastructure startup failed" -ForegroundColor Red
        exit 1
    }
    
    # Start microservices
    Write-Host "🚀 Starting microservices..." -ForegroundColor Blue
    docker-compose -f $DOCKER_COMPOSE_FILE up -d log-producer-service log-consumer-service
    
    # Wait for microservices to be ready
    $services = @{
        "Log Producer Service" = "http://localhost:8081/log-producer/actuator/health"
        "Log Consumer Service" = "http://localhost:8082/log-consumer/actuator/health"
    }
    
    $allHealthy = $true
    foreach ($service in $services.GetEnumerator()) {
        if (-not (Wait-ForServiceHealth $service.Key $service.Value 15 10)) {
            $allHealthy = $false
        }
    }
    
    if ($allHealthy) {
        Write-Host ""
        Write-Host "🎉 All microservices deployed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Service Status:" -ForegroundColor Cyan
        docker-compose -f $DOCKER_COMPOSE_FILE ps
        
        Write-Host ""
        Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
        Write-Host "• Log Producer Service: http://localhost:8081/log-producer" -ForegroundColor White
        Write-Host "• Log Consumer Service: http://localhost:8082/log-consumer" -ForegroundColor White
        Write-Host "• Kafka UI: http://localhost:8080" -ForegroundColor White
        Write-Host "• Producer Health: http://localhost:8081/log-producer/actuator/health" -ForegroundColor Gray
        Write-Host "• Consumer Health: http://localhost:8082/log-consumer/actuator/health" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "🧪 Test the services:" -ForegroundColor Yellow
        Write-Host "curl -X POST http://localhost:8081/log-producer/api/logs -H 'Content-Type: application/json' -d '{\"level\":\"INFO\",\"message\":\"Test message\",\"serviceName\":\"test-service\"}'" -ForegroundColor Gray
    }
    else {
        Write-Host "⚠️  Some services failed to start properly. Check logs with:" -ForegroundColor Yellow
        Write-Host "docker-compose -f $DOCKER_COMPOSE_FILE logs" -ForegroundColor Gray
    }
}
catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check logs with: docker-compose -f $DOCKER_COMPOSE_FILE logs" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Cyan
Write-Host "• View logs: docker-compose -f $DOCKER_COMPOSE_FILE logs -f" -ForegroundColor Gray
Write-Host "• Stop services: docker-compose -f $DOCKER_COMPOSE_FILE down" -ForegroundColor Gray
Write-Host "• Restart service: docker-compose -f $DOCKER_COMPOSE_FILE restart <service-name>" -ForegroundColor Gray
