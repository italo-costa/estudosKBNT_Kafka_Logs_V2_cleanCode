# Simple Environment Startup Script
# Starts Virtual Stock Service and ACL Virtual Stock Service

param(
    [switch]$SkipBuild,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "STARTING VIRTUAL STOCK ARCHITECTURE ENVIRONMENT" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = "c:\workspace\estudosKBNT_Kafka_Logs"
$VirtualStockPath = Join-Path $ProjectRoot "microservices\virtual-stock-service"
$ACLStockPath = Join-Path $ProjectRoot "microservices\kbnt-stock-consumer-service"

# Function to check if port is in use
function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.ConnectAsync("localhost", $Port).Wait(1000)
        if ($connection.Connected) {
            $connection.Close()
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Check if services are already running
Write-Host "Checking for running services..." -ForegroundColor Yellow

$port8080InUse = Test-Port -Port 8080
$port8081InUse = Test-Port -Port 8081

if ($port8080InUse) {
    Write-Host "Virtual Stock Service (Port 8080) is already running" -ForegroundColor Green
}

if ($port8081InUse) {
    Write-Host "ACL Virtual Stock Service (Port 8081) is already running" -ForegroundColor Green
}

# Build applications if not skipping
if (-not $SkipBuild) {
    Write-Host ""
    Write-Host "Building Applications..." -ForegroundColor Yellow
    
    # Build Virtual Stock Service
    if (Test-Path $VirtualStockPath) {
        Write-Host "Building Virtual Stock Service..." -ForegroundColor White
        Push-Location $VirtualStockPath
        
        try {
            $buildResult = & mvn clean compile -q
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   Virtual Stock Service build: SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "   Virtual Stock Service build: FAILED" -ForegroundColor Red
            }
        } catch {
            Write-Host "   Virtual Stock Service build: ERROR - $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "   Virtual Stock Service path not found: $VirtualStockPath" -ForegroundColor Red
    }
    
    # Build ACL Virtual Stock Service
    if (Test-Path $ACLStockPath) {
        Write-Host "Building ACL Virtual Stock Service..." -ForegroundColor White
        Push-Location $ACLStockPath
        
        try {
            $buildResult = & mvn clean compile -q
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ACL Virtual Stock Service build: SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "   ACL Virtual Stock Service build: FAILED" -ForegroundColor Red
            }
        } catch {
            Write-Host "   ACL Virtual Stock Service build: ERROR - $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "   ACL Virtual Stock Service path not found: $ACLStockPath" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Starting Services..." -ForegroundColor Yellow

# Start Virtual Stock Service
if (-not $port8080InUse) {
    Write-Host "Starting Virtual Stock Service on port 8080..." -ForegroundColor White
    
    if (Test-Path $VirtualStockPath) {
        Push-Location $VirtualStockPath
        
        try {
            $env:SERVER_PORT = "8080"
            $env:SPRING_PROFILES_ACTIVE = "local"
            
            Start-Process -FilePath "mvn" -ArgumentList "spring-boot:run", "-Dspring-boot.run.profiles=local" -WindowStyle Minimized
            Write-Host "   Virtual Stock Service starting..." -ForegroundColor Green
            
        } catch {
            Write-Host "   ERROR starting Virtual Stock Service: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Pop-Location
        }
    }
} else {
    Write-Host "Virtual Stock Service already running on port 8080" -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Start ACL Virtual Stock Service  
if (-not $port8081InUse) {
    Write-Host "Starting ACL Virtual Stock Service on port 8081..." -ForegroundColor White
    
    if (Test-Path $ACLStockPath) {
        Push-Location $ACLStockPath
        
        try {
            $env:SERVER_PORT = "8081"
            $env:SPRING_PROFILES_ACTIVE = "local"
            
            Start-Process -FilePath "mvn" -ArgumentList "spring-boot:run", "-Dspring-boot.run.profiles=local" -WindowStyle Minimized
            Write-Host "   ACL Virtual Stock Service starting..." -ForegroundColor Green
            
        } catch {
            Write-Host "   ERROR starting ACL Virtual Stock Service: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Pop-Location
        }
    }
} else {
    Write-Host "ACL Virtual Stock Service already running on port 8081" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Waiting for services to start..." -ForegroundColor Yellow

# Wait for services to be ready
$maxWaitTime = 120  # 2 minutes
$checkInterval = 5  # 5 seconds
$elapsedTime = 0

do {
    Start-Sleep -Seconds $checkInterval
    $elapsedTime += $checkInterval
    
    $virtualStockReady = $false
    $aclStockReady = $false
    
    # Check Virtual Stock Service
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $virtualStockReady = $true
        }
    } catch {
        # Service not ready yet
    }
    
    # Check ACL Virtual Stock Service
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $aclStockReady = $true
        }
    } catch {
        # Service not ready yet
    }
    
    $progress = [math]::Round(($elapsedTime / $maxWaitTime) * 100, 0)
    Write-Host "   Checking services... ${progress}% (${elapsedTime}s)" -ForegroundColor Gray
    
    if ($virtualStockReady -and $aclStockReady) {
        break
    }
    
} while ($elapsedTime -lt $maxWaitTime)

Write-Host ""

# Final status check
Write-Host "ENVIRONMENT STATUS:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

$virtualStockStatus = try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 3
    if ($response.StatusCode -eq 200) { "RUNNING" } else { "ERROR" }
} catch { "NOT RUNNING" }

$aclStockStatus = try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -TimeoutSec 3
    if ($response.StatusCode -eq 200) { "RUNNING" } else { "ERROR" }
} catch { "NOT RUNNING" }

Write-Host "Virtual Stock Service (Port 8080): $virtualStockStatus" -ForegroundColor $(if($virtualStockStatus -eq "RUNNING") {"Green"} else {"Red"})
Write-Host "ACL Virtual Stock Service (Port 8081): $aclStockStatus" -ForegroundColor $(if($aclStockStatus -eq "RUNNING") {"Green"} else {"Red"})

Write-Host ""

if ($virtualStockStatus -eq "RUNNING" -and $aclStockStatus -eq "RUNNING") {
    Write-Host "ENVIRONMENT READY!" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host ""
    Write-Host "Available Endpoints:" -ForegroundColor Yellow
    Write-Host "   Virtual Stock API: http://localhost:8080/api/v1/virtual-stock" -ForegroundColor White
    Write-Host "   Health Checks:" -ForegroundColor White
    Write-Host "     - Virtual Stock: http://localhost:8080/actuator/health" -ForegroundColor Gray
    Write-Host "     - ACL Stock: http://localhost:8081/actuator/health" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "   Run architecture demo: .\scripts\hexagonal-architecture-demo.ps1" -ForegroundColor White
} else {
    Write-Host "ENVIRONMENT NOT FULLY READY" -ForegroundColor Red -BackgroundColor DarkRed
    Write-Host "Please check the application logs for errors" -ForegroundColor Yellow
}

Write-Host ""
