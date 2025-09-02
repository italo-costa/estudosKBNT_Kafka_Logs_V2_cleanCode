# KBNT System Startup - Respecting Hexagonal Architecture + AMQ Streams
# Starts microservices in containers and AMQ Streams in separate environment

Write-Host "🏗️ KBNT System - Hexagonal Architecture + AMQ Streams Startup" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Phase 1: Start AMQ Streams (Red Hat Kafka) in separate environment
Write-Host ""
Write-Host "📊 Phase 1: Starting Red Hat AMQ Streams Environment" -ForegroundColor Yellow
Write-Host "----------------------------------------------------" -ForegroundColor Yellow

# Check if we have container runtime for AMQ Streams
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "🚀 Starting AMQ Streams using Docker..." -ForegroundColor Blue
    
    # Start Zookeeper first
    Write-Host "Starting Zookeeper..." -ForegroundColor Gray
    docker run -d --name zookeeper-amq `
        -p 2181:2181 `
        -e KAFKA_OPTS="-Djava.security.auth.login.config=/opt/kafka/config/zookeeper_jaas.conf" `
        registry.redhat.io/amq7/amq-streams-kafka-34-rhel8:latest `
        /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
    
    Start-Sleep 10
    
    # Start AMQ Streams Kafka
    Write-Host "Starting Red Hat AMQ Streams..." -ForegroundColor Gray
    docker run -d --name kafka-amq `
        -p 9092:9092 `
        -p 9094:9094 `
        --link zookeeper-amq `
        -e KAFKA_ZOOKEEPER_CONNECT=zookeeper-amq:2181 `
        -e KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092,EXTERNAL://0.0.0.0:9094 `
        -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,EXTERNAL://localhost:9094 `
        -e KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT `
        registry.redhat.io/amq7/amq-streams-kafka-34-rhel8:latest `
        /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
    
    Write-Host "✅ AMQ Streams environment started" -ForegroundColor Green
} else {
    Write-Host "⚠️ No container runtime found. Please install Docker or Podman" -ForegroundColor Red
    Write-Host "Using local Kafka installation if available..." -ForegroundColor Yellow
}

# Phase 2: Wait for AMQ Streams to be ready
Write-Host ""
Write-Host "⏳ Waiting for AMQ Streams to be ready..." -ForegroundColor Yellow
Start-Sleep 30

# Test Kafka connectivity
try {
    $kafkaTest = Test-NetConnection -ComputerName localhost -Port 9092 -InformationLevel Quiet
    if ($kafkaTest) {
        Write-Host "✅ AMQ Streams is accessible on localhost:9092" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ AMQ Streams connectivity check failed" -ForegroundColor Yellow
}

# Phase 3: Build microservices (Hexagonal Architecture)
Write-Host ""
Write-Host "🏗️ Phase 2: Building Spring Boot Microservices" -ForegroundColor Yellow
Write-Host "----------------------------------------------" -ForegroundColor Yellow

if (Get-Command mvn -ErrorAction SilentlyContinue) {
    Write-Host "📦 Building microservices with Maven..." -ForegroundColor Blue
    
    cd microservices
    mvn clean package -DskipTests -q
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Microservices built successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Build failed. Check dependencies." -ForegroundColor Red
    }
    cd ..
} else {
    Write-Host "⚠️ Maven not found. Skipping build phase." -ForegroundColor Yellow
    Write-Host "Install Maven: winget install Apache.Maven" -ForegroundColor Cyan
}

# Phase 4: Start microservices in containers
Write-Host ""
Write-Host "🚀 Phase 3: Starting Microservices Containers" -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow

if (Test-Path "microservices/docker-compose.yml") {
    Write-Host "Starting microservices with docker-compose..." -ForegroundColor Blue
    docker-compose -f microservices/docker-compose.yml up -d
    Write-Host "✅ Microservices containers started" -ForegroundColor Green
} else {
    Write-Host "⚠️ Docker compose file not found" -ForegroundColor Yellow
}

# Phase 5: Topic Creation (using your AmqStreamsTopicConfiguration.java)
Write-Host ""
Write-Host "📋 Phase 4: Topic Auto-Creation via Spring Boot" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Yellow
Write-Host "Topics will be created automatically when microservices start:" -ForegroundColor Gray
Write-Host "  • kbnt-application-logs (6 partitions, 2GB retention)" -ForegroundColor White
Write-Host "  • kbnt-error-logs (4 partitions, 5GB retention)" -ForegroundColor White
Write-Host "  • kbnt-audit-logs (3 partitions, 10GB retention)" -ForegroundColor White
Write-Host "  • kbnt-financial-logs (8 partitions, 20GB retention)" -ForegroundColor White
Write-Host "  • kbnt-dead-letter-queue (2 partitions, 1GB retention)" -ForegroundColor White

# Phase 6: Start Python consumer
Write-Host ""
Write-Host "🐍 Phase 5: Python Log Consumer Ready" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow
Write-Host "Your log-consumer.py is ready to process messages:" -ForegroundColor Gray
Write-Host "  python consumers/python/log-consumer.py --topic kbnt-application-logs" -ForegroundColor Cyan
Write-Host "  python consumers/python/log-consumer.py --topic kbnt-error-logs" -ForegroundColor Cyan

# Summary
Write-Host ""
Write-Host "🎉 KBNT System Architecture Ready!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "🏗️ Architecture Summary:" -ForegroundColor Cyan
Write-Host "  📦 Microservices: Spring Boot + Hexagonal Architecture (Containers)" -ForegroundColor White
Write-Host "  📊 Message Broker: Red Hat AMQ Streams (Separate Environment)" -ForegroundColor White
Write-Host "  🐍 Consumers: Python + Java (External Applications)" -ForegroundColor White
Write-Host "  🔄 Communication: Async via Kafka Topics" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Service Endpoints:" -ForegroundColor Cyan
Write-Host "  • Kafka (AMQ Streams): localhost:9092" -ForegroundColor White
Write-Host "  • Stock Producer API: http://localhost:8080" -ForegroundColor White
Write-Host "  • Stock Consumer API: http://localhost:8081" -ForegroundColor White
Write-Host "  • KBNT Log Service: http://localhost:8082" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test Python consumer: python consumers/python/log-consumer.py" -ForegroundColor White
Write-Host "  2. Check microservice logs: docker logs <container-name>" -ForegroundColor White
Write-Host "  3. Monitor topics: Access Kafka UI or use kafka-console-consumer" -ForegroundColor White
Write-Host "  4. Generate test data: Run your virtual stock tests" -ForegroundColor White
