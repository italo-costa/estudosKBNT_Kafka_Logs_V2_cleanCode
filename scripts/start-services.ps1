# Simple Service Starter for KBNT Traffic Test
# Starts the basic services needed for traffic testing

param(
    [switch]$Help
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host "[$Level] $timestamp - $Message" -ForegroundColor $color
}

function Test-JavaAvailable {
    try {
        $javaVersion = java -version 2>&1
        Write-Log "Java is available: $($javaVersion[0])" "SUCCESS"
        return $true
    } catch {
        Write-Log "Java is not available or not in PATH" "ERROR"
        return $false
    }
}

function Start-ProducerService {
    Write-Log "Starting Producer Service..." "INFO"
    
    $producerPath = "c:\workspace\estudosKBNT_Kafka_Logs\microservices\kbnt-stock-producer-service"
    
    if (-not (Test-Path $producerPath)) {
        Write-Log "Producer service path not found: $producerPath" "ERROR"
        return $false
    }
    
    try {
        Set-Location $producerPath
        Write-Log "Building Producer Service..." "INFO"
        
        # Check if we have Maven or Gradle
        if (Test-Path "pom.xml") {
            Write-Log "Using Maven to build producer..." "INFO"
            $buildResult = mvn clean package -DskipTests 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Producer built successfully" "SUCCESS"
                
                # Start the service
                Write-Log "Starting producer application..." "INFO"
                Start-Process -FilePath "java" -ArgumentList @("-jar", "target\*.jar", "--server.port=8080") -WindowStyle Minimized
                
                return $true
            } else {
                Write-Log "Failed to build producer: $buildResult" "ERROR"
                return $false
            }
        } elseif (Test-Path "build.gradle") {
            Write-Log "Using Gradle to build producer..." "INFO"
            $buildResult = gradlew build -x test 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Producer built successfully" "SUCCESS"
                
                # Start the service
                Write-Log "Starting producer application..." "INFO"
                Start-Process -FilePath "java" -ArgumentList @("-jar", "build\libs\*.jar", "--server.port=8080") -WindowStyle Minimized
                
                return $true
            } else {
                Write-Log "Failed to build producer: $buildResult" "ERROR"
                return $false
            }
        } else {
            Write-Log "No Maven (pom.xml) or Gradle (build.gradle) found in producer directory" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error starting producer service: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-ConsumerService {
    Write-Log "Starting Consumer Service..." "INFO"
    
    $consumerPath = "c:\workspace\estudosKBNT_Kafka_Logs\microservices\kbnt-stock-consumer-service"
    
    if (-not (Test-Path $consumerPath)) {
        Write-Log "Consumer service path not found: $consumerPath" "ERROR"
        return $false
    }
    
    try {
        Set-Location $consumerPath
        Write-Log "Building Consumer Service..." "INFO"
        
        # Check if we have Maven or Gradle
        if (Test-Path "pom.xml") {
            Write-Log "Using Maven to build consumer..." "INFO"
            $buildResult = mvn clean package -DskipTests 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Consumer built successfully" "SUCCESS"
                
                # Start the service
                Write-Log "Starting consumer application..." "INFO"
                Start-Process -FilePath "java" -ArgumentList @("-jar", "target\*.jar", "--server.port=8081") -WindowStyle Minimized
                
                return $true
            } else {
                Write-Log "Failed to build consumer: $buildResult" "ERROR"
                return $false
            }
        } elseif (Test-Path "build.gradle") {
            Write-Log "Using Gradle to build consumer..." "INFO"
            $buildResult = gradlew build -x test 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Consumer built successfully" "SUCCESS"
                
                # Start the service
                Write-Log "Starting consumer application..." "INFO"
                Start-Process -FilePath "java" -ArgumentList @("-jar", "build\libs\*.jar", "--server.port=8081") -WindowStyle Minimized
                
                return $true
            } else {
                Write-Log "Failed to build consumer: $buildResult" "ERROR"
                return $false
            }
        } else {
            Write-Log "No Maven (pom.xml) or Gradle (build.gradle) found in consumer directory" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error starting consumer service: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Wait-ForServicesToStart {
    Write-Log "Waiting for services to start..." "INFO"
    
    $maxWait = 120  # 2 minutes
    $checkInterval = 10  # 10 seconds
    $elapsed = 0
    
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        
        Write-Log "Checking services (elapsed: ${elapsed}s)..." "INFO"
        
        # Check producer
        try {
            $producerHealth = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5
            $producerHealthy = $true
            Write-Log "Producer service is healthy" "SUCCESS"
        } catch {
            $producerHealthy = $false
        }
        
        # Check consumer
        try {
            $consumerHealth = Invoke-WebRequest -Uri "http://localhost:8081/api/consumer/actuator/health" -TimeoutSec 5
            $consumerHealthy = $true
            Write-Log "Consumer service is healthy" "SUCCESS"
        } catch {
            $consumerHealthy = $false
        }
        
        if ($producerHealthy -and $consumerHealthy) {
            Write-Log "All services are healthy!" "SUCCESS"
            return $true
        }
        
        Write-Log "Services not ready yet, waiting..." "WARNING"
    }
    
    Write-Log "Timeout waiting for services to start" "ERROR"
    return $false
}

function Show-Help {
    Write-Host @"
KBNT Simple Service Starter

This script starts the Producer and Consumer services needed for traffic testing.

USAGE:
    .\start-services.ps1

PREREQUISITES:
    - Java 17+ installed and in PATH
    - Maven or Gradle in PATH (for building)
    - KBNT microservices source code

The script will:
1. Check Java availability
2. Build and start Producer Service on port 8080
3. Build and start Consumer Service on port 8081
4. Wait for services to be healthy
5. Show status and next steps

"@ -ForegroundColor Cyan
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Log "=== KBNT SERVICE STARTER ===" "INFO"

# Check prerequisites
if (-not (Test-JavaAvailable)) {
    Write-Log "Java is required but not available. Please install Java 17+ and ensure it's in your PATH." "ERROR"
    exit 1
}

# Start services
Write-Log "Starting KBNT services..." "INFO"

$producerStarted = Start-ProducerService
Start-Sleep -Seconds 5  # Give producer a head start

$consumerStarted = Start-ConsumerService

if (-not ($producerStarted -and $consumerStarted)) {
    Write-Log "Failed to start one or more services. Check the logs above." "ERROR"
    exit 1
}

# Wait for services to be ready
if (Wait-ForServicesToStart) {
    Write-Log "=== SERVICES STARTED SUCCESSFULLY ===" "SUCCESS"
    Write-Log "Producer Service: http://localhost:8080" "SUCCESS"
    Write-Log "Consumer Service: http://localhost:8081" "SUCCESS"
    Write-Log "" "INFO"
    Write-Log "You can now run traffic tests:" "INFO"
    Write-Log "  powershell -ExecutionPolicy Bypass -File scripts\simple-traffic-test.ps1" "INFO"
    Write-Log "" "INFO"
    Write-Log "Monitor endpoints:" "INFO"
    Write-Log "  Producer Health: http://localhost:8080/actuator/health" "INFO"
    Write-Log "  Consumer Health: http://localhost:8081/api/consumer/actuator/health" "INFO"
    Write-Log "  Consumer Stats: http://localhost:8081/api/consumer/monitoring/statistics" "INFO"
} else {
    Write-Log "Services failed to start properly. Please check the application logs." "ERROR"
    exit 1
}
