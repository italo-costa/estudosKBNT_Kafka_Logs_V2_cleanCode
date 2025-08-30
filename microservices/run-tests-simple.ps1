# PowerShell Script for Running Unit Tests for KBNT Log Service
param(
    [string]$TestClass = "All",
    [switch]$Verbose = $false
)

Write-Host "Running Unit Tests for KBNT Log Service..." -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Change to service directory
Set-Location "kbnt-log-service"

# Function to find Maven executable
function Find-Maven {
    # Try common Maven locations
    $mavenLocations = @(
        "mvn",
        "mvn.cmd",
        "$env:MAVEN_HOME\bin\mvn.cmd",
        "$env:M2_HOME\bin\mvn.cmd"
    )
    
    foreach ($location in $mavenLocations) {
        try {
            if (Get-Command $location -ErrorAction SilentlyContinue) {
                Write-Host "Found Maven at: $location" -ForegroundColor Green
                return $location
            }
        } catch {
            # Continue to next location
        }
    }
    
    return $null
}

# Find Maven
$maven = Find-Maven

if (-not $maven) {
    Write-Host "Maven not found! Trying alternative approaches..." -ForegroundColor Red
    
    # Try to find Java at least
    if (Get-Command "java" -ErrorAction SilentlyContinue) {
        Write-Host "Java found, but Maven is required for running tests" -ForegroundColor Yellow
        Write-Host "Please install Maven or use VS Code's Java Extension Pack" -ForegroundColor Yellow
    } else {
        Write-Host "Java not found either!" -ForegroundColor Red
        Write-Host "Please install Java JDK and Apache Maven" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Alternative options:" -ForegroundColor Cyan
    Write-Host "1. Install VS Code Java Extension Pack" -ForegroundColor Gray
    Write-Host "2. Use VS Code Test Explorer to run tests" -ForegroundColor Gray
    Write-Host "3. Install Maven from https://maven.apache.org/" -ForegroundColor Gray
    
    exit 1
}

# Run tests
Write-Host "Executing tests with Maven..." -ForegroundColor Cyan

try {
    if ($TestClass -eq "All") {
        Write-Host "Running all unit tests..." -ForegroundColor Yellow
        & $maven "test" "-Dtest=StockUpdateProducerTest,StockUpdateControllerTest,KafkaPublicationLogTest" "-Dmaven.test.failure.ignore=false"
    } else {
        Write-Host "Running specific test class: $TestClass..." -ForegroundColor Yellow
        & $maven "test" "-Dtest=$TestClass"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "All tests passed successfully!" -ForegroundColor Green
        Write-Host "Test Summary:" -ForegroundColor Cyan
        Write-Host "  StockUpdateProducerTest - Producer functionality and logging" -ForegroundColor Green
        Write-Host "  StockUpdateControllerTest - REST API endpoints and validation" -ForegroundColor Green
        Write-Host "  KafkaPublicationLogTest - Logging model and data integrity" -ForegroundColor Green
        
    } else {
        Write-Host ""
        Write-Host "Some tests failed!" -ForegroundColor Red
        Write-Host "Check the output above for details." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error executing tests: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Unit Testing completed!" -ForegroundColor Green
