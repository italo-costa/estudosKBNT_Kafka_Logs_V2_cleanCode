# Deploy Kafka Topics Script (PowerShell)
# This script deploys all Kafka topics independently of microservices

$ErrorActionPreference = "Stop"

$NAMESPACE = "kafka"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$TOPICS_DIR = Join-Path $SCRIPT_DIR "..\topics"

Write-Host "🚀 Deploying Kafka Topics..." -ForegroundColor Green

# Check if namespace exists
try {
    kubectl get namespace $NAMESPACE | Out-Null
}
catch {
    Write-Host "❌ Namespace '$NAMESPACE' not found. Please deploy infrastructure first." -ForegroundColor Red
    exit 1
}

# Check if Kafka cluster is ready
Write-Host "🔍 Checking Kafka cluster readiness..." -ForegroundColor Yellow
try {
    kubectl get kafka kafka-cluster -n $NAMESPACE | Out-Null
}
catch {
    Write-Host "❌ Kafka cluster 'kafka-cluster' not found. Please deploy infrastructure first." -ForegroundColor Red
    exit 1
}

# Wait for Kafka cluster to be ready
Write-Host "⏳ Waiting for Kafka cluster to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready kafka/kafka-cluster -n $NAMESPACE --timeout=300s

# Deploy topics in order
$topics = @("application-logs", "error-logs", "audit-logs", "financial-logs")

foreach ($topic in $topics) {
    Write-Host "📝 Deploying topic: $topic" -ForegroundColor Cyan
    
    $configFile = Join-Path $TOPICS_DIR "$topic\topic-config.yaml"
    if (Test-Path $configFile) {
        kubectl apply -f $configFile
        
        # Wait for topic to be ready
        Write-Host "⏳ Waiting for topic '$topic' to be ready..." -ForegroundColor Yellow
        kubectl wait --for=condition=Ready kafkatopic/$topic -n $NAMESPACE --timeout=60s
        
        Write-Host "✅ Topic '$topic' deployed successfully" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Configuration file not found: $configFile" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "🎉 All Kafka topics deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Topic Status:" -ForegroundColor Cyan
kubectl get kafkatopic -n $NAMESPACE

Write-Host ""
Write-Host "🔍 To verify topic creation on Kafka cluster:" -ForegroundColor Yellow
Write-Host "kubectl exec -it kafka-cluster-kafka-0 -n $NAMESPACE -- bin/kafka-topics.sh --bootstrap-server localhost:9092 --list" -ForegroundColor Gray
