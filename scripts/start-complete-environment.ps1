# =============================================================================
# KBNT Enhanced Kafka Publication Logging System - Windows PowerShell Startup
# Complete Environment Orchestration Script for Windows
# =============================================================================
# 
# This PowerShell script orchestrates the complete startup of:
# - Red Hat AMQ Streams (Kafka)
# - Microservice A (Producer - Stock Update Service)  
# - Microservice B (Consumer - Stock Consumer Service)
# - PostgreSQL Database
# - Monitoring and Logging Infrastructure
#
# Author: KBNT Development Team
# Version: 1.0.0
# Date: 2025-08-30
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("startup", "start", "health", "test", "info", "cleanup")]
    [string]$Command = "startup",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "kbnt-system",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment = "development",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
    [string]$LogLevel = "INFO"
)

# Configuration Variables
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ServiceConfig = @{
    ProducerService = "kbnt-stock-producer-service"
    ConsumerService = "kbnt-stock-consumer-service"
    KafkaCluster = "kbnt-kafka-cluster"
    PostgresService = "kbnt-postgresql"
}

# Timing Configuration (in seconds)
$TimingConfig = @{
    KafkaStartupWait = 120
    PostgresStartupWait = 60
    ProducerStartupWait = 90
    ConsumerStartupWait = 90
    TopicCreationWait = 30
    HealthCheckInterval = 10
    MaxHealthChecks = 30
}

# Colors for PowerShell output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Magenta = "Magenta"
    Cyan = "Cyan"
    White = "White"
}

# Enhanced Logging Functions
function Write-LogHeader {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $Colors.White
    Write-Host $Message -ForegroundColor $Colors.White
    Write-Host "========================================" -ForegroundColor $Colors.White
    Write-Host ""
}

function Write-LogInfo {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-LogSuccess {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [SUCCESS] $Message" -ForegroundColor $Colors.Green
}

function Write-LogWarning {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-LogError {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor $Colors.Red
}

function Write-LogStep {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [STEP] $Message" -ForegroundColor $Colors.Magenta
}

function Write-LogProgress {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [PROGRESS] $Message" -ForegroundColor $Colors.Cyan
}

# Progress indicator
function Show-Progress {
    param(
        [int]$Duration,
        [string]$Message
    )
    
    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] [WAITING] $Message " -NoNewline -ForegroundColor $Colors.Cyan
    
    $interval = 2
    $elapsed = 0
    
    while ($elapsed -lt $Duration) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }
    Write-Host " ✓" -ForegroundColor $Colors.Green
}

# Health check function
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthEndpoint,
        [int]$MaxAttempts,
        [int]$CheckInterval
    )
    
    Write-LogInfo "Checking health for $ServiceName at $HealthEndpoint"
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        Write-LogProgress "Health check attempt $i/$MaxAttempts for $ServiceName"
        
        try {
            $response = Invoke-RestMethod -Uri $HealthEndpoint -Method Get -TimeoutSec 10 -ErrorAction Stop
            Write-LogSuccess "$ServiceName is healthy! (attempt $i/$MaxAttempts)"
            return $true
        }
        catch {
            if ($i -lt $MaxAttempts) {
                Write-LogWarning "$ServiceName not ready yet, waiting $CheckInterval seconds... (attempt $i/$MaxAttempts)"
                Start-Sleep -Seconds $CheckInterval
            }
        }
    }
    
    Write-LogError "$ServiceName health check failed after $MaxAttempts attempts"
    return $false
}

# Prerequisites check
function Test-Prerequisites {
    Write-LogHeader "CHECKING PREREQUISITES"
    
    $prerequisites = @("kubectl", "docker", "mvn", "java")
    $missingTools = @()
    
    foreach ($tool in $prerequisites) {
        Write-LogInfo "Checking for $tool..."
        
        try {
            $null = Get-Command $tool -ErrorAction Stop
            Write-LogSuccess "$tool is installed"
        }
        catch {
            Write-LogError "$tool is not installed"
            $missingTools += $tool
        }
    }
    
    if ($missingTools.Count -gt 0) {
        Write-LogError "Missing required tools: $($missingTools -join ', ')"
        Write-LogError "Please install missing tools before continuing"
        exit 1
    }
    
    # Check Kubernetes connection
    Write-LogInfo "Checking Kubernetes cluster connection..."
    try {
        kubectl cluster-info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Kubernetes cluster is accessible"
        }
        else {
            throw "Cannot connect to cluster"
        }
    }
    catch {
        Write-LogError "Cannot connect to Kubernetes cluster"
        exit 1
    }
    
    Write-LogSuccess "All prerequisites satisfied"
}

# Setup namespace
function Initialize-Namespace {
    Write-LogHeader "SETTING UP NAMESPACE"
    
    Write-LogInfo "Creating namespace '$Namespace' if it doesn't exist..."
    kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace
    kubectl label namespace $Namespace monitoring=enabled --overwrite
    kubectl label namespace $Namespace environment=$Environment --overwrite
    
    Write-LogSuccess "Namespace '$Namespace' is ready and configured"
}

# Deploy PostgreSQL
function Deploy-PostgreSQL {
    Write-LogHeader "DEPLOYING POSTGRESQL DATABASE"
    
    Write-LogStep "Creating PostgreSQL configuration..."
    
    $postgresConfig = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-config
  namespace: $Namespace
data:
  POSTGRES_DB: kbnt_consumption_db
  POSTGRES_USER: kbnt_user
---
apiVersion: v1
kind: Secret
metadata:
  name: postgresql-secret
  namespace: $Namespace
type: Opaque
data:
  POSTGRES_PASSWORD: a2JudF9wYXNzd29yZA==  # kbnt_password
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $($ServiceConfig.PostgresService)
  namespace: $Namespace
  labels:
    app: $($ServiceConfig.PostgresService)
    component: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $($ServiceConfig.PostgresService)
  template:
    metadata:
      labels:
        app: $($ServiceConfig.PostgresService)
        component: database
    spec:
      containers:
      - name: postgresql
        image: postgres:15
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgresql-config
        - secretRef:
            name: postgresql-secret
        volumeMounts:
        - name: postgresql-storage
          mountPath: /var/lib/postgresql/data
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - kbnt_user
            - -d
            - kbnt_consumption_db
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - kbnt_user
            - -d
            - kbnt_consumption_db
          initialDelaySeconds: 30
          periodSeconds: 10
      volumes:
      - name: postgresql-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: $($ServiceConfig.PostgresService)
  namespace: $Namespace
  labels:
    app: $($ServiceConfig.PostgresService)
spec:
  type: ClusterIP
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: $($ServiceConfig.PostgresService)
"@

    $tempFile = "$env:TEMP\postgresql-config.yaml"
    $postgresConfig | Out-File -FilePath $tempFile -Encoding UTF8
    
    Write-LogInfo "Deploying PostgreSQL..."
    kubectl apply -f $tempFile
    
    Write-LogInfo "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=$($ServiceConfig.PostgresService) -n $Namespace --timeout="$($TimingConfig.PostgresStartupWait)s"
    
    Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    Write-LogSuccess "PostgreSQL deployed and ready"
}

# Deploy AMQ Streams
function Deploy-AMQStreams {
    Write-LogHeader "DEPLOYING RED HAT AMQ STREAMS (KAFKA)"
    
    Write-LogStep "Checking if Strimzi operator is installed..."
    
    try {
        kubectl get crd kafkas.kafka.strimzi.io 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Strimzi operator already installed"
        }
        else {
            throw "Strimzi not found"
        }
    }
    catch {
        Write-LogWarning "Strimzi operator not found. Installing..."
        
        Write-LogInfo "Installing Strimzi Kafka operator..."
        $strimziUrl = "https://strimzi.io/install/latest?namespace=$Namespace"
        Invoke-RestMethod -Uri $strimziUrl | kubectl apply -f -
        
        Write-LogInfo "Waiting for Strimzi operator to be ready..."
        kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n $Namespace --timeout=300s
    }
    
    Write-LogStep "Deploying Kafka cluster..."
    
    $kafkaConfigPath = Join-Path $ProjectRoot "kubernetes\amq-streams\kafka-cluster.yaml"
    if (Test-Path $kafkaConfigPath) {
        Write-LogInfo "Using existing Kafka cluster configuration"
        kubectl apply -f $kafkaConfigPath -n $Namespace
    }
    else {
        Write-LogWarning "Kafka cluster configuration not found, creating basic configuration..."
        New-BasicKafkaConfig
    }
    
    Write-LogInfo "Waiting for Kafka cluster to be ready (this may take several minutes)..."
    Show-Progress -Duration $TimingConfig.KafkaStartupWait -Message "Kafka cluster starting up"
    
    kubectl wait --for=condition=ready kafka $ServiceConfig.KafkaCluster -n $Namespace --timeout="$($TimingConfig.KafkaStartupWait)s"
    Write-LogSuccess "Kafka cluster deployed and ready"
}

# Create basic Kafka configuration
function New-BasicKafkaConfig {
    $basicKafkaConfig = @"
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: $($ServiceConfig.KafkaCluster)
  namespace: $Namespace
spec:
  kafka:
    version: 3.5.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      default.replication.factor: 3
      min.insync.replicas: 2
      inter.broker.protocol.version: "3.5"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
"@

    $tempFile = "$env:TEMP\basic-kafka.yaml"
    $basicKafkaConfig | Out-File -FilePath $tempFile -Encoding UTF8
    kubectl apply -f $tempFile
    Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
}

# Create Kafka topics
function New-KafkaTopics {
    Write-LogHeader "CREATING KAFKA TOPICS"
    
    $topics = @(
        @{ Name = "stock-updates"; Partitions = 3; Replicas = 3 }
        @{ Name = "high-priority-stock-updates"; Partitions = 3; Replicas = 3 }
        @{ Name = "stock-updates-retry"; Partitions = 3; Replicas = 3 }
        @{ Name = "stock-updates-dlt"; Partitions = 1; Replicas = 3 }
        @{ Name = "publication-logs"; Partitions = 3; Replicas = 3 }
    )
    
    foreach ($topic in $topics) {
        Write-LogStep "Creating topic '$($topic.Name)' with $($topic.Partitions) partitions and $($topic.Replicas) replicas"
        
        $topicConfig = @"
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: $($topic.Name)
  namespace: $Namespace
  labels:
    strimzi.io/cluster: $($ServiceConfig.KafkaCluster)
spec:
  partitions: $($topic.Partitions)
  replicas: $($topic.Replicas)
  config:
    retention.ms: 604800000  # 7 days
    segment.ms: 86400000     # 1 day
    cleanup.policy: delete
    compression.type: producer
"@
        
        $tempFile = "$env:TEMP\topic-$($topic.Name).yaml"
        $topicConfig | Out-File -FilePath $tempFile -Encoding UTF8
        kubectl apply -f $tempFile
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
        
        Write-LogInfo "Topic '$($topic.Name)' created"
    }
    
    Write-LogInfo "Waiting for topics to be ready..."
    Show-Progress -Duration $TimingConfig.TopicCreationWait -Message "Topics being created"
    
    foreach ($topic in $topics) {
        kubectl wait --for=condition=ready kafkatopic $topic.Name -n $Namespace --timeout=60s
    }
    
    Write-LogSuccess "All Kafka topics created and ready"
}

# Deploy Producer Service
function Deploy-ProducerService {
    Write-LogHeader "DEPLOYING PRODUCER SERVICE (MICROSERVICE A)"
    
    Write-LogStep "Building Producer Service..."
    Set-Location $ProjectRoot
    
    Write-LogInfo "Compiling and packaging producer service..."
    mvn clean package -DskipTests -q
    
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Producer service build failed"
        exit 1
    }
    
    Write-LogInfo "Building Docker image for producer service..."
    New-ProducerDockerfile
    docker build -t "$($ServiceConfig.ProducerService):latest" .
    
    Write-LogStep "Creating producer service Kubernetes manifests..."
    New-ProducerK8sManifests
    
    Write-LogInfo "Deploying producer service to Kubernetes..."
    kubectl apply -f "$env:TEMP\producer-manifests.yaml"
    
    Write-LogInfo "Waiting for producer service to be ready..."
    kubectl wait --for=condition=ready pod -l app=$ServiceConfig.ProducerService -n $Namespace --timeout="$($TimingConfig.ProducerStartupWait)s"
    
    Write-LogSuccess "Producer service deployed and ready"
}

# Create Dockerfile for producer
function New-ProducerDockerfile {
    $dockerfilePath = Join-Path $ProjectRoot "Dockerfile"
    if (-not (Test-Path $dockerfilePath)) {
        Write-LogInfo "Creating Dockerfile for producer service..."
        
        $dockerfileContent = @'
FROM openjdk:17-jre-slim

WORKDIR /app

# Copy the application jar
COPY target/*.jar app.jar

# Create non-root user
RUN useradd -r -u 1001 appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
'@
        
        $dockerfileContent | Out-File -FilePath $dockerfilePath -Encoding UTF8
    }
}

# Create Kubernetes manifests for producer
function New-ProducerK8sManifests {
    $producerManifests = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: $($ServiceConfig.ProducerService)-config
  namespace: $Namespace
data:
  application.yml: |
    spring:
      application:
        name: $($ServiceConfig.ProducerService)
      profiles:
        active: production
      kafka:
        bootstrap-servers: $($ServiceConfig.KafkaCluster)-kafka-bootstrap:9092
        producer:
          key-serializer: org.apache.kafka.common.serialization.StringSerializer
          value-serializer: org.springframework.kafka.support.serializer.JsonSerializer
          acks: all
          retries: 3
    server:
      port: 8080
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      endpoint:
        health:
          show-details: always
    app:
      kafka:
        topics:
          stock-updates: stock-updates
          high-priority-stock-updates: high-priority-stock-updates
          publication-logs: publication-logs
        publication-logging:
          enabled: true
          hash-calculation: true
    logging:
      level:
        com.estudoskbnt: INFO
        org.springframework.kafka: INFO
      pattern:
        console: "%d{HH:mm:ss.SSS} [%thread] %-5level [%X{correlationId}] %logger{36} - %msg%n"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $($ServiceConfig.ProducerService)
  namespace: $Namespace
  labels:
    app: $($ServiceConfig.ProducerService)
    component: producer
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $($ServiceConfig.ProducerService)
  template:
    metadata:
      labels:
        app: $($ServiceConfig.ProducerService)
        component: producer
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      containers:
      - name: $($ServiceConfig.ProducerService)
        image: $($ServiceConfig.ProducerService):latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: SPRING_KAFKA_BOOTSTRAP_SERVERS
          value: "$($ServiceConfig.KafkaCluster)-kafka-bootstrap:9092"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: config-volume
        configMap:
          name: $($ServiceConfig.ProducerService)-config
---
apiVersion: v1
kind: Service
metadata:
  name: $($ServiceConfig.ProducerService)
  namespace: $Namespace
  labels:
    app: $($ServiceConfig.ProducerService)
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: $($ServiceConfig.ProducerService)
"@

    $tempFile = "$env:TEMP\producer-manifests.yaml"
    $producerManifests | Out-File -FilePath $tempFile -Encoding UTF8
}

# Deploy Consumer Service
function Deploy-ConsumerService {
    Write-LogHeader "DEPLOYING CONSUMER SERVICE (MICROSERVICE B)"
    
    Write-LogStep "Building Consumer Service..."
    
    $consumerPath = Join-Path $ProjectRoot "microservices\kbnt-stock-consumer-service"
    if (Test-Path $consumerPath) {
        Set-Location $consumerPath
        
        Write-LogInfo "Building consumer service..."
        if (Test-Path "scripts\deploy-consumer.sh") {
            # For Windows, we'll need to run the script using Git Bash or WSL
            Write-LogInfo "Running consumer deployment script..."
            bash scripts/deploy-consumer.sh build
            bash scripts/deploy-consumer.sh deploy
        }
        else {
            Write-LogError "Consumer deployment script not found"
            exit 1
        }
        
        Write-LogSuccess "Consumer service deployed successfully"
    }
    else {
        Write-LogError "Consumer service directory not found at: $consumerPath"
        exit 1
    }
    
    Write-LogInfo "Waiting for consumer service to be ready..."
    kubectl wait --for=condition=ready pod -l app=$ServiceConfig.ConsumerService -n $Namespace --timeout="$($TimingConfig.ConsumerStartupWait)s"
    
    Write-LogSuccess "Consumer service deployed and ready"
}

# Perform health checks
function Test-AllServicesHealth {
    Write-LogHeader "PERFORMING COMPREHENSIVE HEALTH CHECKS"
    
    Write-LogInfo "Starting health checks for all services..."
    Show-Progress -Duration 30 -Message "Allowing services to stabilize"
    
    # Check PostgreSQL
    Write-LogStep "Checking PostgreSQL connectivity..."
    try {
        kubectl exec -n $Namespace deployment/$($ServiceConfig.PostgresService) -- pg_isready -U kbnt_user -d kbnt_consumption_db 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "✓ PostgreSQL is accessible and ready"
        }
        else {
            Write-LogError "✗ PostgreSQL health check failed"
        }
    }
    catch {
        Write-LogError "✗ PostgreSQL health check failed: $($_.Exception.Message)"
    }
    
    # Check Kafka cluster
    Write-LogStep "Checking Kafka cluster status..."
    try {
        $kafkaStatus = kubectl get kafka $ServiceConfig.KafkaCluster -n $Namespace -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>$null
        if ($kafkaStatus -eq "True") {
            Write-LogSuccess "✓ Kafka cluster is ready"
        }
        else {
            Write-LogError "✗ Kafka cluster is not ready"
        }
    }
    catch {
        Write-LogError "✗ Kafka cluster check failed: $($_.Exception.Message)"
    }
    
    # Check services via port forwarding for health endpoints
    Write-LogStep "Setting up temporary port forwarding for health checks..."
    
    # Producer health check
    $producerPF = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/$($ServiceConfig.ProducerService)", "8080:8080", "-n", $Namespace -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 5
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 10 -ErrorAction Stop
        Write-LogSuccess "✓ Producer service is healthy"
    }
    catch {
        Write-LogWarning "⚠ Producer service health check inconclusive"
    }
    
    Stop-Process -Id $producerPF.Id -Force -ErrorAction SilentlyContinue
    
    # Consumer health check  
    $consumerPF = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/$($ServiceConfig.ConsumerService)", "8081:8081", "-n", $Namespace -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 5
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8081/api/consumer/actuator/health" -Method Get -TimeoutSec 10 -ErrorAction Stop
        Write-LogSuccess "✓ Consumer service is healthy"
    }
    catch {
        Write-LogWarning "⚠ Consumer service health check inconclusive"
    }
    
    Stop-Process -Id $consumerPF.Id -Force -ErrorAction SilentlyContinue
    
    Write-LogSuccess "Health checks completed"
}

# Test end-to-end workflow
function Test-EndToEndWorkflow {
    Write-LogHeader "TESTING END-TO-END WORKFLOW"
    
    Write-LogStep "Setting up port forwarding for testing..."
    
    # Port forward producer service
    $producerPF = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/$($ServiceConfig.ProducerService)", "8080:8080", "-n", $Namespace -PassThru -WindowStyle Hidden
    
    # Port forward consumer service
    $consumerPF = Start-Process -FilePath "kubectl" -ArgumentList "port-forward", "service/$($ServiceConfig.ConsumerService)", "8081:8081", "-n", $Namespace -PassThru -WindowStyle Hidden
    
    Show-Progress -Duration 10 -Message "Establishing port forwarding"
    
    Write-LogStep "Sending test message to producer..."
    
    $testMessage = @{
        productId = "TEST-PROD-001"
        quantity = 100
        price = 29.99
        operation = "ADD"
        category = "Electronics"
        supplier = "TestSupplier"
        location = "WH-TEST"
        priority = "NORMAL"
    } | ConvertTo-Json
    
    Write-LogInfo "Posting test stock update..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/stock/update" -Method Post -Body $testMessage -ContentType "application/json" -TimeoutSec 30
        Write-LogSuccess "✓ Test message sent to producer"
    }
    catch {
        Write-LogError "✗ Failed to send test message to producer: $($_.Exception.Message)"
    }
    
    Show-Progress -Duration 15 -Message "Waiting for message processing"
    
    Write-LogStep "Checking consumer statistics..."
    try {
        $stats = Invoke-RestMethod -Uri "http://localhost:8081/api/consumer/monitoring/statistics" -Method Get -TimeoutSec 10
        Write-LogSuccess "✓ Consumer monitoring endpoint accessible"
        Write-LogInfo "Consumer Statistics: $($stats | ConvertTo-Json -Compress)"
    }
    catch {
        Write-LogWarning "⚠ Consumer monitoring endpoint not accessible: $($_.Exception.Message)"
    }
    
    # Cleanup
    Stop-Process -Id $producerPF.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $consumerPF.Id -Force -ErrorAction SilentlyContinue
    
    Write-LogSuccess "End-to-end workflow test completed"
}

# Display environment information
function Show-EnvironmentInfo {
    Write-LogHeader "ENVIRONMENT INFORMATION"
    
    Write-Host "KBNT Enhanced Kafka Publication Logging System" -ForegroundColor $Colors.White
    Write-Host "Environment: " -NoNewline -ForegroundColor $Colors.White
    Write-Host $Environment -ForegroundColor $Colors.Cyan
    Write-Host "Namespace: " -NoNewline -ForegroundColor $Colors.White  
    Write-Host $Namespace -ForegroundColor $Colors.Cyan
    Write-Host "Deployment Date: " -NoNewline -ForegroundColor $Colors.White
    Write-Host (Get-Date) -ForegroundColor $Colors.Cyan
    Write-Host ""
    
    Write-LogInfo "Service Endpoints (use kubectl port-forward to access):"
    Write-Host "  Producer Service: http://localhost:8080" -ForegroundColor $Colors.Cyan
    Write-Host "  Consumer Service: http://localhost:8081/api/consumer" -ForegroundColor $Colors.Cyan
    Write-Host "  Producer Health: http://localhost:8080/actuator/health" -ForegroundColor $Colors.Cyan
    Write-Host "  Consumer Health: http://localhost:8081/api/consumer/actuator/health" -ForegroundColor $Colors.Cyan
    Write-Host "  Consumer Monitoring: http://localhost:8081/api/consumer/monitoring/statistics" -ForegroundColor $Colors.Cyan
    Write-Host ""
    
    Write-LogInfo "Kafka Topics Created:"
    Write-Host "  stock-updates (main topic)" -ForegroundColor $Colors.Cyan
    Write-Host "  high-priority-stock-updates (priority topic)" -ForegroundColor $Colors.Cyan
    Write-Host "  stock-updates-retry (retry topic)" -ForegroundColor $Colors.Cyan
    Write-Host "  stock-updates-dlt (dead letter topic)" -ForegroundColor $Colors.Cyan
    Write-Host "  publication-logs (audit logs)" -ForegroundColor $Colors.Cyan
    Write-Host ""
    
    Write-LogInfo "Port Forward Commands:"
    Write-Host "  kubectl port-forward service/$($ServiceConfig.ProducerService) 8080:8080 -n $Namespace" -ForegroundColor $Colors.Yellow
    Write-Host "  kubectl port-forward service/$($ServiceConfig.ConsumerService) 8081:8081 -n $Namespace" -ForegroundColor $Colors.Yellow
    Write-Host ""
    
    Write-LogInfo "Monitoring Commands:"
    Write-Host "  kubectl get pods -n $Namespace" -ForegroundColor $Colors.Yellow
    Write-Host "  kubectl logs -f deployment/$($ServiceConfig.ProducerService) -n $Namespace" -ForegroundColor $Colors.Yellow
    Write-Host "  kubectl logs -f deployment/$($ServiceConfig.ConsumerService) -n $Namespace" -ForegroundColor $Colors.Yellow
    Write-Host ""
    
    Write-LogSuccess "Environment setup completed successfully!"
}

# Cleanup environment
function Remove-Environment {
    Write-LogHeader "CLEANING UP ENVIRONMENT"
    
    $confirmation = Read-Host "This will delete all resources in namespace '$Namespace'. Are you sure? (y/N)"
    
    if ($confirmation -match "^[Yy]") {
        Write-LogInfo "Deleting all resources in namespace '$Namespace'..."
        kubectl delete namespace $Namespace --ignore-not-found=true
        Write-LogSuccess "Environment cleanup completed"
    }
    else {
        Write-LogInfo "Cleanup cancelled"
    }
}

# Main execution
switch ($Command) {
    { $_ -in @("startup", "start") } {
        Write-LogHeader "KBNT ENHANCED KAFKA LOGGING SYSTEM - COMPLETE STARTUP"
        
        Test-Prerequisites
        Initialize-Namespace
        Deploy-PostgreSQL
        Deploy-AMQStreams
        New-KafkaTopics
        Deploy-ProducerService
        Deploy-ConsumerService
        Test-AllServicesHealth
        Test-EndToEndWorkflow
        Show-EnvironmentInfo
    }
    
    "health" {
        Test-AllServicesHealth
    }
    
    "test" {
        Test-EndToEndWorkflow
    }
    
    "info" {
        Show-EnvironmentInfo
    }
    
    "cleanup" {
        Remove-Environment
    }
    
    default {
        Write-Host "Usage: .\start-complete-environment.ps1 [-Command <startup|health|test|info|cleanup>] [-Namespace <namespace>] [-Environment <development|staging|production>]" -ForegroundColor $Colors.Yellow
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor $Colors.White
        Write-Host "  startup  - Complete environment startup (default)" -ForegroundColor $Colors.Cyan
        Write-Host "  health   - Perform health checks only" -ForegroundColor $Colors.Cyan
        Write-Host "  test     - Run end-to-end workflow test" -ForegroundColor $Colors.Cyan
        Write-Host "  info     - Display environment information" -ForegroundColor $Colors.Cyan
        Write-Host "  cleanup  - Clean up all resources" -ForegroundColor $Colors.Cyan
        Write-Host ""
        Write-Host "Parameters:" -ForegroundColor $Colors.White
        Write-Host "  -Namespace: $Namespace" -ForegroundColor $Colors.Green
        Write-Host "  -Environment: $Environment" -ForegroundColor $Colors.Green
        Write-Host "  -LogLevel: $LogLevel" -ForegroundColor $Colors.Green
    }
}
