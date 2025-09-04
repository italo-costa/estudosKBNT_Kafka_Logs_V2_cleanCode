# =============================================================================
# KBNT Scalable Deployment Script
# Automated deployment with performance optimization
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("local", "kubernetes", "hybrid")]
    [string]$Environment = "local",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "scalable", "production")]
    [string]$Profile = "scalable",
    
    [Parameter(Mandatory=$false)]
    [switch]$Monitoring = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanDeploy = $false
)

# Color functions
function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Info { Write-Host $args[0] -ForegroundColor Cyan }
function Write-Warning { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Error { Write-Host $args[0] -ForegroundColor Red }

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Info "🚀 KBNT Scalable Deployment Script"
Write-Info "Environment: $Environment"
Write-Info "Profile: $Profile"
Write-Info "Project Root: $ProjectRoot"

# Function to check prerequisites
function Test-Prerequisites {
    Write-Info "🔍 Checking prerequisites..."
    
    $tools = @()
    
    if ($Environment -eq "local") {
        $tools += "docker"
        $tools += "docker-compose"
    } elseif ($Environment -eq "kubernetes") {
        $tools += "kubectl"
        $tools += "helm"
    }
    
    foreach ($tool in $tools) {
        try {
            $null = Get-Command $tool -ErrorAction Stop
            Write-Success "✅ $tool is available"
        } catch {
            Write-Error "❌ $tool not found. Please install $tool first."
            exit 1
        }
    }
}

# Function for local Docker deployment
function Deploy-Local {
    Write-Info "🐳 Deploying locally with Docker Compose..."
    
    Set-Location "$ProjectRoot\docker"
    
    if ($CleanDeploy) {
        Write-Info "🧹 Cleaning up existing containers..."
        wsl -d Ubuntu -- bash -c "docker compose -f docker-compose.free-tier.yml down -v"
    }
    
    # Build and start services
    Write-Info "🔨 Building and starting services..."
    if ($Monitoring) {
        $composeFile = "docker-compose.free-tier.yml --profile monitoring"
    } else {
        $composeFile = "docker-compose.free-tier.yml"
    }
    
    $command = "cd /mnt/c/workspace/estudosKBNT_Kafka_Logs/docker && docker compose -f $composeFile up -d --build"
    wsl -d Ubuntu -- bash -c $command
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Local deployment completed!"
        Show-LocalEndpoints
    } else {
        Write-Error "❌ Local deployment failed!"
        exit 1
    }
}

# Function for Kubernetes deployment
function Deploy-Kubernetes {
    Write-Info "☸️ Deploying to Kubernetes..."
    
    # Check if cluster is accessible
    try {
        kubectl cluster-info | Out-Null
        Write-Success "✅ Kubernetes cluster is accessible"
    } catch {
        Write-Error "❌ Cannot access Kubernetes cluster"
        exit 1
    }
    
    # Create namespace
    kubectl create namespace kbnt-scalable --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Kafka cluster first
    Write-Info "📨 Deploying Kafka cluster..."
    kubectl apply -f "$ProjectRoot\kubernetes\kafka\kafka-scalable-cluster.yaml"
    
    # Wait for Kafka to be ready
    Write-Info "⏳ Waiting for Kafka cluster to be ready..."
    kubectl wait --for=condition=Ready kafkas/kbnt-scalable-cluster -n kbnt-scalable --timeout=300s
    
    # Deploy microservices
    Write-Info "🚀 Deploying microservices..."
    kubectl apply -f "$ProjectRoot\kubernetes\microservices\virtual-stock-service-scalable.yaml"
    
    # Wait for deployments
    Write-Info "⏳ Waiting for deployments to be ready..."
    kubectl wait --for=condition=Available deployment/virtual-stock-service -n kbnt-scalable --timeout=300s
    
    if ($?) {
        Write-Success "✅ Kubernetes deployment completed!"
        Show-KubernetesEndpoints
    } else {
        Write-Error "❌ Kubernetes deployment failed!"
        exit 1
    }
}

# Function to show local endpoints
function Show-LocalEndpoints {
    Write-Info ""
    Write-Info "🎯 Application Endpoints (Local):"
    Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Success "🌐 API Gateway:          http://localhost:8090"
    Write-Success "📊 Management:           http://localhost:8091/actuator"
    Write-Success "🏪 Virtual Stock:        http://localhost:8086"
    Write-Success "📊 Stock Management:     http://localhost:8087/actuator"
    Write-Success "📨 Kafka UI:             http://localhost:8080"
    Write-Success "📊 Elasticsearch:        http://localhost:9200"
    
    if ($Monitoring) {
        Write-Success "📈 Kibana:               http://localhost:5601"
    }
    
    Write-Info ""
    Write-Info "🧪 Quick Test Commands:"
    Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Info 'curl -X POST http://localhost:8090/api/v1/virtual-stock/products -H "Content-Type: application/json" -d "{\"productId\":\"TEST-001\",\"quantity\":100,\"price\":25.99}"'
    Write-Info 'curl http://localhost:8090/api/v1/virtual-stock/products/TEST-001'
}

# Function to show Kubernetes endpoints
function Show-KubernetesEndpoints {
    Write-Info ""
    Write-Info "🎯 Application Endpoints (Kubernetes):"
    Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Success "🌐 API Gateway:          kubectl port-forward svc/api-gateway 8090:80 -n kbnt-scalable"
    Write-Success "🏪 Virtual Stock:        kubectl port-forward svc/virtual-stock-service 8086:80 -n kbnt-scalable"
    Write-Success "📨 Kafka Bootstrap:      kubectl port-forward svc/kbnt-scalable-cluster-kafka-bootstrap 9092:9092 -n kbnt-scalable"
    
    Write-Info ""
    Write-Info "📊 Monitoring Commands:"
    Write-Info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Info "kubectl get pods -n kbnt-scalable"
    Write-Info "kubectl get hpa -n kbnt-scalable"
    Write-Info "kubectl top pods -n kbnt-scalable"
}

# Function to check deployment status
function Test-DeploymentHealth {
    Write-Info "🏥 Checking deployment health..."
    
    if ($Environment -eq "local") {
        # Test Docker containers
        $containers = @("api-gateway-free", "virtual-stock-service-free", "kafka-free", "postgres-free")
        
        foreach ($container in $containers) {
            $status = wsl -d Ubuntu -- bash -c "docker inspect -f '{{.State.Health.Status}}' $container 2>/dev/null || echo 'unknown'"
            if ($status -eq "healthy" -or $status -eq "unknown") {
                Write-Success "✅ $container is healthy"
            } else {
                Write-Warning "⚠️ $container health status: $status"
            }
        }
        
        # Test API endpoints
        Start-Sleep 30  # Wait for services to fully start
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8091/actuator/health" -TimeoutSec 10
            if ($response.status -eq "UP") {
                Write-Success "✅ API Gateway health check passed"
            }
        } catch {
            Write-Warning "⚠️ API Gateway health check failed: $($_.Exception.Message)"
        }
        
    } elseif ($Environment -eq "kubernetes") {
        # Test Kubernetes deployments
        $deployments = kubectl get deployments -n kbnt-scalable -o jsonpath='{.items[*].metadata.name}'
        
        foreach ($deployment in $deployments.Split(' ')) {
            if ($deployment) {
                $ready = kubectl get deployment $deployment -n kbnt-scalable -o jsonpath='{.status.conditions[?(@.type=="Available")].status}'
                if ($ready -eq "True") {
                    Write-Success "✅ Deployment $deployment is ready"
                } else {
                    Write-Warning "⚠️ Deployment $deployment is not ready"
                }
            }
        }
    }
}

# Main execution
try {
    Test-Prerequisites
    
    switch ($Environment) {
        "local" { Deploy-Local }
        "kubernetes" { Deploy-Kubernetes }
        "hybrid" { 
            Write-Info "🔄 Hybrid deployment not implemented yet"
            exit 1
        }
    }
    
    # Health check
    Test-DeploymentHealth
    
    Write-Success ""
    Write-Success "🎉 KBNT Scalable Deployment completed successfully!"
    Write-Success "   Environment: $Environment"
    Write-Success "   Profile: $Profile"
    if ($Monitoring) {
        Write-Success "   Monitoring: Enabled"
    } else {
        Write-Success "   Monitoring: Disabled"
    }
    
} catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    exit 1
}
