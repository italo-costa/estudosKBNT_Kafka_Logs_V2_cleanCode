# =============================================================================
# KBNT Virtual Stock Architecture - Complete Local Environment Startup
# =============================================================================

param(
    [string]$Operation = "start",
    [switch]$WithLogs = $true,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

# Configuration
$ProjectRoot = "c:\workspace\estudosKBNT_Kafka_Logs"
$LogsDir = Join-Path $ProjectRoot "logs"

# Ensure logs directory exists
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

# Colors for output
$Colors = @{
    Header = "Cyan"
    Success = "Green" 
    Warning = "Yellow"
    Error = "Red"
    Info = "Blue"
    Progress = "Magenta"
}

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "MAIN"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Component] [$Level] $Message"
    
    $color = switch ($Level) {
        "SUCCESS" { $Colors.Success }
        "WARNING" { $Colors.Warning }
        "ERROR" { $Colors.Error }
        "PROGRESS" { $Colors.Progress }
        default { $Colors.Info }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    if ($WithLogs) {
        $logEntry | Out-File -FilePath (Join-Path $LogsDir "environment-startup.log") -Append -Encoding UTF8
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host ""
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxRetries = 30,
        [int]$DelaySeconds = 5
    )
    
    Write-LogMessage "Testing health for $ServiceName at $Url" "INFO" "HEALTH_CHECK"
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-RestMethod -Uri $Url -Method GET -TimeoutSec 10 -ErrorAction Stop
            Write-LogMessage "$ServiceName is healthy! (attempt $i/$MaxRetries)" "SUCCESS" "HEALTH_CHECK"
            return $true
        }
        catch {
            if ($i -lt $MaxRetries) {
                Write-LogMessage "$ServiceName not ready, waiting... (attempt $i/$MaxRetries)" "PROGRESS" "HEALTH_CHECK"
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }
    
    Write-LogMessage "$ServiceName health check failed after $MaxRetries attempts" "ERROR" "HEALTH_CHECK"
    return $false
}

function Start-Infrastructure {
    Write-Header "STARTING KAFKA INFRASTRUCTURE"
    
    Push-Location $ProjectRoot
    
    try {
        Write-LogMessage "Stopping any existing containers..." "INFO" "DOCKER"
        docker-compose -f docker/docker-compose.yml down --remove-orphans 2>$null
        
        Write-LogMessage "Starting Kafka infrastructure..." "INFO" "DOCKER"
        docker-compose -f docker/docker-compose.yml up -d
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Kafka infrastructure started successfully" "SUCCESS" "DOCKER"
        } else {
            Write-LogMessage "Failed to start Kafka infrastructure" "ERROR" "DOCKER"
            return $false
        }
        
        # Wait for Kafka to be ready
        Write-LogMessage "Waiting for Kafka to be ready..." "PROGRESS" "KAFKA"
        Start-Sleep -Seconds 30
        
        # Test Kafka UI
        $kafkaUiReady = Test-ServiceHealth -ServiceName "Kafka UI" -Url "http://localhost:8080" -MaxRetries 10
        if (-not $kafkaUiReady) {
            Write-LogMessage "Kafka UI not ready, but continuing..." "WARNING" "KAFKA"
        }
        
        return $true
    }
    catch {
        Write-LogMessage "Error starting infrastructure: $($_.Exception.Message)" "ERROR" "DOCKER"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Start-VirtualStockService {
    Write-Header "STARTING VIRTUAL STOCK SERVICE (MICROSERVICE A)"
    
    $servicePath = Join-Path $ProjectRoot "microservices\virtual-stock-service"
    
    if (-not (Test-Path $servicePath)) {
        Write-LogMessage "Virtual Stock Service path not found: $servicePath" "ERROR" "VIRTUAL_STOCK"
        return $false
    }
    
    Push-Location $servicePath
    
    try {
        Write-LogMessage "Starting Virtual Stock Service..." "INFO" "VIRTUAL_STOCK"
        
        $env:SERVER_PORT = "8081"
        $env:SPRING_PROFILES_ACTIVE = "local"
        $env:KAFKA_BOOTSTRAP_SERVERS = "localhost:9092"
        $env:LOGGING_COMPONENT = "VIRTUAL-STOCK-SERVICE"
        
        # Start service in background
        $process = Start-Process -FilePath "mvn" -ArgumentList "spring-boot:run" -WindowStyle Minimized -PassThru
        
        if ($process) {
            Write-LogMessage "Virtual Stock Service starting with PID: $($process.Id)" "SUCCESS" "VIRTUAL_STOCK"
            $process.Id | Out-File -FilePath (Join-Path $LogsDir "virtual-stock-pid.txt") -Encoding UTF8
        } else {
            Write-LogMessage "Failed to start Virtual Stock Service" "ERROR" "VIRTUAL_STOCK"
            return $false
        }
        
        return $true
    }
    catch {
        Write-LogMessage "Error starting Virtual Stock Service: $($_.Exception.Message)" "ERROR" "VIRTUAL_STOCK"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Start-ACLVirtualStockService {
    Write-Header "STARTING ACL VIRTUAL STOCK SERVICE (MICROSERVICE B)"
    
    $servicePath = Join-Path $ProjectRoot "microservices\kbnt-stock-consumer-service"
    
    if (-not (Test-Path $servicePath)) {
        Write-LogMessage "ACL Virtual Stock Service path not found: $servicePath" "ERROR" "ACL_VIRTUAL_STOCK"
        return $false
    }
    
    Push-Location $servicePath
    
    try {
        Write-LogMessage "Starting ACL Virtual Stock Service..." "INFO" "ACL_VIRTUAL_STOCK"
        
        $env:SERVER_PORT = "8082"
        $env:SPRING_PROFILES_ACTIVE = "local"
        $env:KAFKA_BOOTSTRAP_SERVERS = "localhost:9092"
        $env:LOGGING_COMPONENT = "ACL-VIRTUAL-STOCK-SERVICE"
        
        # Start service in background
        $process = Start-Process -FilePath "mvn" -ArgumentList "spring-boot:run" -WindowStyle Minimized -PassThru
        
        if ($process) {
            Write-LogMessage "ACL Virtual Stock Service starting with PID: $($process.Id)" "SUCCESS" "ACL_VIRTUAL_STOCK"
            $process.Id | Out-File -FilePath (Join-Path $LogsDir "acl-virtual-stock-pid.txt") -Encoding UTF8
        } else {
            Write-LogMessage "Failed to start ACL Virtual Stock Service" "ERROR" "ACL_VIRTUAL_STOCK"
            return $false
        }
        
        return $true
    }
    catch {
        Write-LogMessage "Error starting ACL Virtual Stock Service: $($_.Exception.Message)" "ERROR" "ACL_VIRTUAL_STOCK"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Test-CompleteWorkflow {
    Write-Header "TESTING STOCK UPDATE WORKFLOW"
    
    # Wait for services to be ready
    Write-LogMessage "Waiting for services to start..." "PROGRESS" "TEST"
    Start-Sleep -Seconds 45
    
    # Test Virtual Stock Service health
    $virtualStockReady = Test-ServiceHealth -ServiceName "Virtual Stock Service" -Url "http://localhost:8081/actuator/health" -MaxRetries 15
    $aclStockReady = Test-ServiceHealth -ServiceName "ACL Virtual Stock Service" -Url "http://localhost:8082/actuator/health" -MaxRetries 15
    
    if (-not $virtualStockReady -or -not $aclStockReady) {
        Write-LogMessage "Services not ready for testing" "ERROR" "TEST"
        return $false
    }
    
    Write-LogMessage "All services are healthy, starting workflow test..." "SUCCESS" "TEST"
    
    # Create test stock update message
    $testMessage = @{
        productId = "AAPL-001"
        symbol = "AAPL"
        productName = "Apple Inc. Stock"
        initialQuantity = 150
        unitPrice = 175.50
        createdBy = "test-workflow-system"
        reason = "Workflow Integration Test - Stock Creation"
    } | ConvertTo-Json -Depth 3
    
    Write-LogMessage "Sending stock creation request..." "INFO" "TEST"
    Write-LogMessage "Request payload: $testMessage" "INFO" "TEST"
    
    try {
        # Send stock creation request
        $headers = @{ "Content-Type" = "application/json" }
        $response = Invoke-RestMethod -Uri "http://localhost:8081/api/v1/virtual-stock/stocks" -Method POST -Body $testMessage -Headers $headers -TimeoutSec 30
        
        Write-LogMessage "Stock creation response received" "SUCCESS" "TEST"
        Write-LogMessage "Response: $($response | ConvertTo-Json -Compress)" "INFO" "TEST"
        
        if ($response.success) {
            $stockId = $response.data.stockId
            Write-LogMessage "Stock created successfully with ID: $stockId" "SUCCESS" "TEST"
            
            # Wait for message processing
            Write-LogMessage "Waiting for Kafka message processing..." "PROGRESS" "TEST"
            Start-Sleep -Seconds 10
            
            # Now test stock quantity update
            $updateMessage = @{
                newQuantity = 200
                updatedBy = "test-workflow-system"
                reason = "Workflow Integration Test - Quantity Update"
            } | ConvertTo-Json -Depth 3
            
            Write-LogMessage "Sending stock quantity update..." "INFO" "TEST"
            Write-LogMessage "Update payload: $updateMessage" "INFO" "TEST"
            
            $updateResponse = Invoke-RestMethod -Uri "http://localhost:8081/api/v1/virtual-stock/stocks/$stockId/quantity" -Method PUT -Body $updateMessage -Headers $headers -TimeoutSec 30
            
            Write-LogMessage "Stock update response received" "SUCCESS" "TEST"
            Write-LogMessage "Update response: $($updateResponse | ConvertTo-Json -Compress)" "INFO" "TEST"
            
            if ($updateResponse.success) {
                Write-LogMessage "Stock quantity updated successfully!" "SUCCESS" "TEST"
                Write-LogMessage "New quantity: $($updateResponse.data.quantity)" "INFO" "TEST"
                
                # Final wait for processing
                Write-LogMessage "Allowing time for complete message processing..." "PROGRESS" "TEST"
                Start-Sleep -Seconds 15
                
                return $true
            } else {
                Write-LogMessage "Stock update failed: $($updateResponse.message)" "ERROR" "TEST"
                return $false
            }
        } else {
            Write-LogMessage "Stock creation failed: $($response.message)" "ERROR" "TEST"
            return $false
        }
    }
    catch {
        Write-LogMessage "Error during workflow test: $($_.Exception.Message)" "ERROR" "TEST"
        return $false
    }
}

function Show-LogsSummary {
    Write-Header "LOGS SUMMARY"
    
    $logFiles = @(
        @{ Name = "Environment Startup"; Path = Join-Path $LogsDir "environment-startup.log" },
        @{ Name = "Virtual Stock Service"; Path = Join-Path $LogsDir "virtual-stock-service.log" },
        @{ Name = "ACL Virtual Stock Service"; Path = Join-Path $LogsDir "kbnt-stock-consumer-service.log" }
    )
    
    foreach ($logFile in $logFiles) {
        if (Test-Path $logFile.Path) {
            Write-LogMessage "Log file available: $($logFile.Name) - $($logFile.Path)" "INFO" "LOGS"
        } else {
            Write-LogMessage "Log file not found: $($logFile.Name) - $($logFile.Path)" "WARNING" "LOGS"
        }
    }
    
    Write-LogMessage "To monitor logs in real-time, use:" "INFO" "LOGS"
    Write-Host "   Get-Content '$LogsDir\environment-startup.log' -Tail 50 -Wait" -ForegroundColor $Colors.Info
    Write-Host "   docker logs -f kafka" -ForegroundColor $Colors.Info
    Write-Host "   docker logs -f elasticsearch" -ForegroundColor $Colors.Info
}

function Show-ServiceEndpoints {
    Write-Header "SERVICE ENDPOINTS"
    
    Write-LogMessage "Available service endpoints:" "INFO" "ENDPOINTS"
    Write-Host "   Virtual Stock Service API: http://localhost:8081/api/v1/virtual-stock" -ForegroundColor $Colors.Success
    Write-Host "   Virtual Stock Health: http://localhost:8081/actuator/health" -ForegroundColor $Colors.Success
    Write-Host "   ACL Virtual Stock Health: http://localhost:8082/actuator/health" -ForegroundColor $Colors.Success
    Write-Host "   Kafka UI: http://localhost:8080" -ForegroundColor $Colors.Success
    Write-Host "   Kibana Dashboard: http://localhost:5601" -ForegroundColor $Colors.Success
    Write-Host "   Elasticsearch: http://localhost:9200" -ForegroundColor $Colors.Success
}

function Stop-AllServices {
    Write-Header "STOPPING ALL SERVICES"
    
    # Stop Java services
    if (Test-Path (Join-Path $LogsDir "virtual-stock-pid.txt")) {
        $pid = Get-Content (Join-Path $LogsDir "virtual-stock-pid.txt")
        if ($pid) {
            Write-LogMessage "Stopping Virtual Stock Service (PID: $pid)" "INFO" "SHUTDOWN"
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
    
    if (Test-Path (Join-Path $LogsDir "acl-virtual-stock-pid.txt")) {
        $pid = Get-Content (Join-Path $LogsDir "acl-virtual-stock-pid.txt")
        if ($pid) {
            Write-LogMessage "Stopping ACL Virtual Stock Service (PID: $pid)" "INFO" "SHUTDOWN"
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Stop Docker containers
    Push-Location $ProjectRoot
    try {
        Write-LogMessage "Stopping Docker containers..." "INFO" "SHUTDOWN"
        docker-compose -f docker/docker-compose.yml down
        Write-LogMessage "All services stopped" "SUCCESS" "SHUTDOWN"
    }
    finally {
        Pop-Location
    }
}

# Main execution
switch ($Operation.ToLower()) {
    "start" {
        Write-Header "KBNT VIRTUAL STOCK ARCHITECTURE - COMPLETE STARTUP"
        
        if (Start-Infrastructure) {
            if (Start-VirtualStockService) {
                if (Start-ACLVirtualStockService) {
                    if (Test-CompleteWorkflow) {
                        Write-LogMessage "Complete environment started and tested successfully!" "SUCCESS" "MAIN"
                        Show-ServiceEndpoints
                        Show-LogsSummary
                    } else {
                        Write-LogMessage "Environment started but workflow test failed" "WARNING" "MAIN"
                    }
                } else {
                    Write-LogMessage "Failed to start ACL Virtual Stock Service" "ERROR" "MAIN"
                }
            } else {
                Write-LogMessage "Failed to start Virtual Stock Service" "ERROR" "MAIN"
            }
        } else {
            Write-LogMessage "Failed to start infrastructure" "ERROR" "MAIN"
        }
    }
    
    "test" {
        Write-Header "TESTING WORKFLOW ONLY"
        Test-CompleteWorkflow
    }
    
    "stop" {
        Stop-AllServices
    }
    
    "status" {
        Write-Header "SERVICE STATUS"
        Test-ServiceHealth -ServiceName "Virtual Stock Service" -Url "http://localhost:8081/actuator/health" -MaxRetries 3
        Test-ServiceHealth -ServiceName "ACL Virtual Stock Service" -Url "http://localhost:8082/actuator/health" -MaxRetries 3
        Test-ServiceHealth -ServiceName "Kafka UI" -Url "http://localhost:8080" -MaxRetries 3
        Show-ServiceEndpoints
    }
    
    default {
        Write-Host "Usage: .\complete-environment-startup.ps1 [-Operation <start|test|stop|status>] [-WithLogs] [-Verbose]" -ForegroundColor $Colors.Warning
        Write-Host ""
        Write-Host "Operations:" -ForegroundColor $Colors.Header
        Write-Host "   start  - Start complete environment and run test" -ForegroundColor $Colors.Info
        Write-Host "   test   - Run workflow test only" -ForegroundColor $Colors.Info
        Write-Host "   stop   - Stop all services" -ForegroundColor $Colors.Info  
        Write-Host "   status - Check service status" -ForegroundColor $Colors.Info
    }
}
