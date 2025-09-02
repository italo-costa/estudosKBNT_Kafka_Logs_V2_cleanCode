# 🧪 Quick Test Script for Independent Deployment

Write-Host "🧪 KBNT Kafka Independent Deployment - Quick Test" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$ErrorActionPreference = "Stop"

# Configuration
$WORKSPACE_ROOT = "C:\workspace\estudosKBNT_Kafka_Logs"
$DOCKER_DIR = "$WORKSPACE_ROOT\docker"

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$HealthUrl,
        [int]$Port
    )
    
    Write-Host "🔍 Testing $ServiceName health..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $health = ConvertFrom-Json $response.Content
            $status = $health.status
            
            switch ($status) {
                "UP" { 
                    Write-Host "✅ $ServiceName is healthy (UP)" -ForegroundColor Green 
                    return $true
                }
                "DEGRADED" { 
                    Write-Host "⚠️ $ServiceName is degraded but functional" -ForegroundColor Yellow 
                    return $true
                }
                "DOWN" { 
                    Write-Host "❌ $ServiceName is down" -ForegroundColor Red 
                    return $false
                }
                default { 
                    Write-Host "❓ $ServiceName status unknown: $status" -ForegroundColor Gray 
                    return $false
                }
            }
        } else {
            Write-Host "❌ $ServiceName returned HTTP $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ $ServiceName is not responding: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-KafkaTopics {
    Write-Host "📋 Testing Kafka topics..." -ForegroundColor Yellow
    
    try {
        $topics = docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>$null
        if ($topics) {
            Write-Host "✅ Available Kafka topics:" -ForegroundColor Green
            $topics | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
            return $true
        } else {
            Write-Host "❌ No topics found or Kafka unavailable" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Failed to list Kafka topics: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-ContainerStatus {
    Write-Host "🐳 Testing container status..." -ForegroundColor Yellow
    
    try {
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}" | Where-Object { $_ -notmatch "NAMES" }
        if ($containers) {
            Write-Host "✅ Running containers:" -ForegroundColor Green
            $containers | ForEach-Object { Write-Host "  $($_)" -ForegroundColor Cyan }
            return $true
        } else {
            Write-Host "❌ No containers running" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Failed to check container status: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-LogProduction {
    Write-Host "📤 Testing log production..." -ForegroundColor Yellow
    
    try {
        # Send test log via producer service
        $testLog = @{
            level = "INFO"
            message = "Test log from automated deployment test"
            service = "test-service"
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/logs" -Method POST -Body $testLog -ContentType "application/json" -TimeoutSec 10 -UseBasicParsing
        
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 202) {
            Write-Host "✅ Log production test successful" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Log production failed with status: $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Log production test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Start-QuickTest {
    Write-Host ""
    Write-Host "🚀 Starting microservices-first deployment for testing..." -ForegroundColor Cyan
    
    try {
        Set-Location $DOCKER_DIR
        
        # Start infrastructure and services
        docker-compose -f docker-compose.infrastructure.yml up kafka zookeeper -d
        Start-Sleep 15
        
        docker-compose -f docker-compose.microservices.yml up -d
        Start-Sleep 20
        
        Write-Host "✅ Services started, beginning tests..." -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to start services: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Run-AllTests {
    Write-Host ""
    Write-Host "🧪 Running comprehensive test suite..." -ForegroundColor Cyan
    Write-Host ""
    
    $results = @{}
    
    # Test container status
    $results["Containers"] = Test-ContainerStatus
    Start-Sleep 2
    
    # Test Kafka topics
    $results["KafkaTopics"] = Test-KafkaTopics
    Start-Sleep 2
    
    # Test producer service health
    $results["ProducerHealth"] = Test-ServiceHealth -ServiceName "Producer Service" -HealthUrl "http://localhost:8080/actuator/health" -Port 8080
    Start-Sleep 2
    
    # Test consumer service health  
    $results["ConsumerHealth"] = Test-ServiceHealth -ServiceName "Consumer Service" -HealthUrl "http://localhost:8081/actuator/health" -Port 8081
    Start-Sleep 2
    
    # Test log production
    $results["LogProduction"] = Test-LogProduction
    
    # Summary
    Write-Host ""
    Write-Host "📊 Test Results Summary" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    
    $passed = 0
    $total = $results.Count
    
    foreach ($test in $results.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        Write-Host "$($test.Key): $status" -ForegroundColor $color
        
        if ($test.Value) { $passed++ }
    }
    
    Write-Host ""
    Write-Host "Results: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    
    if ($passed -eq $total) {
        Write-Host "🎉 All tests passed! Independent deployment is working correctly." -ForegroundColor Green
    } elseif ($passed -gt 0) {
        Write-Host "⚠️ Partial success. Some components are working in degraded mode." -ForegroundColor Yellow
    } else {
        Write-Host "❌ All tests failed. Check logs and configuration." -ForegroundColor Red
    }
    
    return ($passed -eq $total)
}

# Main execution
try {
    Write-Host "Select test option:" -ForegroundColor Cyan
    Write-Host "1. Quick test (start services + run tests)"
    Write-Host "2. Test existing deployment"
    Write-Host "3. Exit"
    
    $choice = Read-Host "Choose option (1-3)"
    
    switch ($choice) {
        "1" {
            if (Start-QuickTest) {
                Run-AllTests
            }
        }
        "2" {
            Run-AllTests
        }
        "3" {
            Write-Host "👋 Goodbye!" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "❌ Invalid option" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "💡 Tips:" -ForegroundColor Yellow
    Write-Host "- Check detailed logs: docker-compose logs <service-name>"
    Write-Host "- Access health endpoints directly: curl http://localhost:8080/actuator/health"
    Write-Host "- Use the full deployment script: .\scripts\deploy.ps1"
    Write-Host ""
    
} catch {
    Write-Host "❌ Test script failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
