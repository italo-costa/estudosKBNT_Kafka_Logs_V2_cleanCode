# 🎛️ PowerShell Deployment Scripts

Write-Host "🚀 KBNT Kafka Independent Deployment Automation" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Set error handling
$ErrorActionPreference = "Stop"

# Configuration
$WORKSPACE_ROOT = "C:\workspace\estudosKBNT_Kafka_Logs"
$DOCKER_DIR = "$WORKSPACE_ROOT\docker"
$KAFKA_TOPICS_DIR = "$WORKSPACE_ROOT\kafka\topics"
$MICROSERVICES_DIR = "$WORKSPACE_ROOT\microservices"

# Deployment functions
function Show-Menu {
    Write-Host ""
    Write-Host "📋 Available Deployment Options:" -ForegroundColor Cyan
    Write-Host "1. Full Infrastructure Deployment (Traditional)"
    Write-Host "2. Topics-First Deployment (Independent)"
    Write-Host "3. Microservices-First Deployment (Auto-creation)"
    Write-Host "4. Gradual Rollout Deployment"
    Write-Host "5. Health Check & Status"
    Write-Host "6. Cleanup & Reset"
    Write-Host "7. Exit"
    Write-Host ""
}

function Deploy-FullInfrastructure {
    Write-Host "🏗️ Starting Full Infrastructure Deployment..." -ForegroundColor Yellow
    
    try {
        # Start infrastructure
        Set-Location $DOCKER_DIR
        Write-Host "Starting Kafka infrastructure..." -ForegroundColor Green
        docker-compose -f docker-compose.infrastructure.yml up -d
        
        # Wait for Kafka to be ready
        Write-Host "Waiting for Kafka to be ready..." -ForegroundColor Yellow
        Start-Sleep 30
        
        # Deploy topics (if kubectl is available)
        if (Get-Command kubectl -ErrorAction SilentlyContinue) {
            Write-Host "Deploying Kafka topics..." -ForegroundColor Green
            Set-Location $KAFKA_TOPICS_DIR
            
            $topicDirs = @("application-logs", "error-logs", "audit-logs", "financial-logs")
            foreach ($dir in $topicDirs) {
                if (Test-Path "$dir\topic-config.yaml") {
                    kubectl apply -f "$dir\topic-config.yaml"
                    Write-Host "✅ Deployed topic: $dir" -ForegroundColor Green
                }
            }
        }
        
        # Start microservices
        Set-Location $DOCKER_DIR
        Write-Host "Starting microservices..." -ForegroundColor Green
        docker-compose -f docker-compose.microservices.yml up -d
        
        Write-Host "✅ Full infrastructure deployment completed!" -ForegroundColor Green
        Show-HealthStatus
        
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Deploy-TopicsFirst {
    Write-Host "📋 Starting Topics-First Deployment..." -ForegroundColor Yellow
    
    try {
        # Check if kubectl is available
        if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
            Write-Host "⚠️ kubectl not found. Starting Kafka infrastructure first..." -ForegroundColor Yellow
            Set-Location $DOCKER_DIR
            docker-compose -f docker-compose.infrastructure.yml up kafka zookeeper -d
            Start-Sleep 30
            
            # Create topics using docker exec
            Write-Host "Creating topics using Kafka CLI..." -ForegroundColor Green
            $topics = @(
                @{name="application-logs"; partitions=3; replication=1},
                @{name="error-logs"; partitions=3; replication=1},
                @{name="audit-logs"; partitions=2; replication=1},
                @{name="financial-logs"; partitions=4; replication=1}
            )
            
            foreach ($topic in $topics) {
                docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic $($topic.name) --partitions $($topic.partitions) --replication-factor $($topic.replication)
                Write-Host "✅ Created topic: $($topic.name)" -ForegroundColor Green
            }
        } else {
            # Deploy using kubectl
            Write-Host "Deploying topics using kubectl..." -ForegroundColor Green
            Set-Location $KAFKA_TOPICS_DIR
            
            $topicFiles = @("application-logs", "error-logs", "audit-logs", "financial-logs")
            foreach ($topic in $topicFiles) {
                if (Test-Path "$topic\topic-config.yaml") {
                    kubectl apply -f "$topic\topic-config.yaml"
                    Write-Host "✅ Deployed topic: $topic" -ForegroundColor Green
                }
            }
            
            # Verify deployment
            Write-Host "Verifying topic deployment..." -ForegroundColor Yellow
            kubectl get kafkatopics
        }
        
        # Start microservices
        Set-Location $DOCKER_DIR
        Write-Host "Starting microservices..." -ForegroundColor Green
        docker-compose -f docker-compose.microservices.yml up -d
        
        Write-Host "✅ Topics-first deployment completed!" -ForegroundColor Green
        Show-HealthStatus
        
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Deploy-MicroservicesFirst {
    Write-Host "🔧 Starting Microservices-First Deployment..." -ForegroundColor Yellow
    
    try {
        # Start minimal infrastructure
        Set-Location $DOCKER_DIR
        Write-Host "Starting minimal Kafka infrastructure..." -ForegroundColor Green
        docker-compose -f docker-compose.infrastructure.yml up kafka zookeeper -d
        
        # Wait for Kafka
        Start-Sleep 20
        
        # Start microservices (they will auto-create topics)
        Write-Host "Starting microservices with auto-topic creation..." -ForegroundColor Green
        docker-compose -f docker-compose.microservices.yml up -d
        
        # Monitor topic creation
        Write-Host "Monitoring topic creation..." -ForegroundColor Yellow
        Start-Sleep 15
        
        Write-Host "Verifying auto-created topics:" -ForegroundColor Cyan
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list
        
        Write-Host "✅ Microservices-first deployment completed!" -ForegroundColor Green
        Show-HealthStatus
        
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Deploy-GradualRollout {
    Write-Host "⚡ Starting Gradual Rollout Deployment..." -ForegroundColor Yellow
    
    try {
        # Step 1: Minimal infrastructure
        Set-Location $DOCKER_DIR
        Write-Host "Step 1: Starting minimal Kafka infrastructure..." -ForegroundColor Green
        docker-compose -f docker-compose.infrastructure.yml up kafka zookeeper -d
        Start-Sleep 20
        
        # Step 2: Critical topics
        Write-Host "Step 2: Deploying critical topics..." -ForegroundColor Green
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic error-logs --partitions 3 --replication-factor 1
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic audit-logs --partitions 2 --replication-factor 1
        
        # Step 3: Producer service
        Write-Host "Step 3: Starting producer service..." -ForegroundColor Green
        docker-compose -f docker-compose.microservices.yml up log-producer-service -d
        Start-Sleep 10
        
        # Step 4: Remaining topics
        Write-Host "Step 4: Adding remaining topics..." -ForegroundColor Green
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic application-logs --partitions 3 --replication-factor 1
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --create --if-not-exists --topic financial-logs --partitions 4 --replication-factor 1
        
        # Step 5: Consumer service
        Write-Host "Step 5: Starting consumer service..." -ForegroundColor Green
        docker-compose -f docker-compose.microservices.yml up log-consumer-service -d
        
        Write-Host "✅ Gradual rollout deployment completed!" -ForegroundColor Green
        Show-HealthStatus
        
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-HealthStatus {
    Write-Host ""
    Write-Host "🏥 Health Status Check" -ForegroundColor Cyan
    Write-Host "=====================" -ForegroundColor Cyan
    
    try {
        # Check running containers
        Write-Host ""
        Write-Host "📊 Running Containers:" -ForegroundColor Yellow
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Check service health
        Write-Host ""
        Write-Host "🔍 Service Health Checks:" -ForegroundColor Yellow
        
        $services = @(
            @{name="Producer Service"; url="http://localhost:8080/actuator/health"},
            @{name="Consumer Service"; url="http://localhost:8081/actuator/health"}
        )
        
        foreach ($service in $services) {
            try {
                $response = Invoke-WebRequest -Uri $service.url -TimeoutSec 5 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    $health = ConvertFrom-Json $response.Content
                    $status = $health.status
                    $color = switch ($status) {
                        "UP" { "Green" }
                        "DEGRADED" { "Yellow" }
                        "DOWN" { "Red" }
                        default { "Gray" }
                    }
                    Write-Host "  ✅ $($service.name): $status" -ForegroundColor $color
                } else {
                    Write-Host "  ❌ $($service.name): HTTP $($response.StatusCode)" -ForegroundColor Red
                }
            } catch {
                Write-Host "  ❌ $($service.name): Unavailable" -ForegroundColor Red
            }
        }
        
        # Check Kafka topics
        Write-Host ""
        Write-Host "📋 Kafka Topics:" -ForegroundColor Yellow
        try {
            docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>$null
        } catch {
            Write-Host "  ❌ Could not list topics" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Cleanup-Reset {
    Write-Host "🧹 Cleanup & Reset Options" -ForegroundColor Yellow
    Write-Host "1. Stop all services"
    Write-Host "2. Stop and remove containers"
    Write-Host "3. Full reset (remove volumes - ⚠️ DATA LOSS)"
    Write-Host "4. Back to main menu"
    
    $choice = Read-Host "Select option (1-4)"
    
    try {
        Set-Location $DOCKER_DIR
        
        switch ($choice) {
            "1" {
                Write-Host "Stopping all services..." -ForegroundColor Yellow
                docker-compose -f docker-compose.infrastructure.yml stop
                docker-compose -f docker-compose.microservices.yml stop
                Write-Host "✅ All services stopped" -ForegroundColor Green
            }
            "2" {
                Write-Host "Stopping and removing containers..." -ForegroundColor Yellow
                docker-compose -f docker-compose.infrastructure.yml down
                docker-compose -f docker-compose.microservices.yml down
                Write-Host "✅ Containers removed" -ForegroundColor Green
            }
            "3" {
                $confirm = Read-Host "⚠️ This will delete all data. Type 'DELETE' to confirm"
                if ($confirm -eq "DELETE") {
                    Write-Host "Performing full reset..." -ForegroundColor Red
                    docker-compose -f docker-compose.infrastructure.yml down -v
                    docker-compose -f docker-compose.microservices.yml down -v
                    Write-Host "✅ Full reset completed" -ForegroundColor Green
                } else {
                    Write-Host "Reset cancelled" -ForegroundColor Yellow
                }
            }
            "4" { return }
            default { 
                Write-Host "Invalid option" -ForegroundColor Red 
            }
        }
    } catch {
        Write-Host "❌ Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
try {
    Set-Location $WORKSPACE_ROOT
    
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select deployment option (1-7)"
        
        switch ($choice) {
            "1" { Deploy-FullInfrastructure }
            "2" { Deploy-TopicsFirst }
            "3" { Deploy-MicroservicesFirst }
            "4" { Deploy-GradualRollout }
            "5" { Show-HealthStatus }
            "6" { Cleanup-Reset }
            "7" { 
                Write-Host "👋 Goodbye!" -ForegroundColor Green
                break 
            }
            default { 
                Write-Host "❌ Invalid option. Please select 1-7." -ForegroundColor Red 
            }
        }
        
        if ($choice -ne "7") {
            Write-Host ""
            Read-Host "Press Enter to continue..."
        }
    }
    
} catch {
    Write-Host "❌ Script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
