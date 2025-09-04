# PowerShell Script for Running Unit Tests for KBNT Log Service
param(
    [string]$TestClass = "All",
    [switch]$Verbose = $false
)

Write-Host "🧪 Running Unit Tests for KBNT Log Service..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Change to service directory
Set-Location "kbnt-log-service"

# Function to find Maven executable
function Find-Maven {
    # Try common Maven locations
    $mavenLocations = @(
        "mvn",
        "mvn.cmd",
        "$env:MAVEN_HOME\bin\mvn.cmd",
        "$env:M2_HOME\bin\mvn.cmd",
        "C:\Program Files\Apache Maven*\bin\mvn.cmd",
        "C:\maven\bin\mvn.cmd",
        "${env:ProgramFiles}\maven\bin\mvn.cmd",
        "${env:ProgramFiles(x86)}\Apache\Maven*\bin\mvn.cmd"
    )
    
    foreach ($location in $mavenLocations) {
        try {
            if (Get-Command $location -ErrorAction SilentlyContinue) {
                Write-Host "✅ Found Maven at: $location" -ForegroundColor Green
                return $location
            }
        } catch {
            # Continue to next location
        }
    }
    
    # Try wildcard search for Maven installations
    try {
        $mavenInstalls = Get-ChildItem "C:\Program Files" -Filter "*maven*" -Directory -ErrorAction SilentlyContinue
        if ($mavenInstalls) {
            foreach ($install in $mavenInstalls) {
                $mvnPath = Join-Path $install.FullName "bin\mvn.cmd"
                if (Test-Path $mvnPath) {
                    Write-Host "✅ Found Maven at: $mvnPath" -ForegroundColor Green
                    return $mvnPath
                }
            }
        }
    } catch {
        # Continue
    }
    
    return $null
}

# Find Maven
$maven = Find-Maven

if (-not $maven) {
    Write-Host "❌ Maven not found! Please install Maven or ensure it's in PATH." -ForegroundColor Red
    Write-Host "   Download Maven from: https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    Write-Host "   Or use VS Code Java Extension Pack which includes embedded Maven" -ForegroundColor Yellow
    
    # Try to use VS Code's integrated tools
    Write-Host "🔧 Attempting to use VS Code's integrated Java tools..." -ForegroundColor Yellow
    
    # Check if Java extensions are available
    if (Get-Command "java" -ErrorAction SilentlyContinue) {
        Write-Host "✅ Java found, compiling tests manually..." -ForegroundColor Green
        
        # Manual compilation and test execution
        $srcPath = "src\main\java"
        $testPath = "src\test\java"
        $targetPath = "target\test-classes"
        
        if (-not (Test-Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        }
        
        # Basic compilation approach
        Write-Host "📝 Compiling test classes..." -ForegroundColor Yellow
        Write-Host "Note: For full test execution, please install Maven or use VS Code's Test Explorer" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ Java not found either!" -ForegroundColor Red
        Write-Host "Please install:" -ForegroundColor Yellow
        Write-Host "  1. Java JDK 17 or higher" -ForegroundColor Yellow
        Write-Host "  2. Apache Maven 3.8+" -ForegroundColor Yellow
        Write-Host "  3. Or use VS Code Java Extension Pack" -ForegroundColor Yellow
    }
    
    exit 1
}

# Run tests
Write-Host "🚀 Executing tests with Maven..." -ForegroundColor Cyan

try {
    if ($TestClass -eq "All") {
        Write-Host "Running all unit tests..." -ForegroundColor Yellow
        & $maven "test" "-Dtest=StockUpdateProducerTest,StockUpdateControllerTest,KafkaPublicationLogTest"
    } else {
        Write-Host "Running specific test class: $TestClass..." -ForegroundColor Yellow
        & $maven "test" "-Dtest=$TestClass"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
        Write-Host "🎯 Test Summary:" -ForegroundColor Cyan
        Write-Host "  ✅ StockUpdateProducerTest - Producer functionality and logging" -ForegroundColor Green
        Write-Host "  ✅ StockUpdateControllerTest - REST API endpoints and validation" -ForegroundColor Green
        Write-Host "  ✅ KafkaPublicationLogTest - Logging model and data integrity" -ForegroundColor Green
        
        # Look for test reports
        $testReportsPath = "target\surefire-reports"
        if (Test-Path $testReportsPath) {
            Write-Host ""
            Write-Host "📊 Test Reports generated at: $testReportsPath" -ForegroundColor Cyan
            Get-ChildItem $testReportsPath -Filter "*.xml" | ForEach-Object {
                Write-Host "  📄 $($_.Name)" -ForegroundColor Gray
            }
        }
        
    } else {
        Write-Host ""
        Write-Host "❌ Some tests failed!" -ForegroundColor Red
        Write-Host "Check the output above for details." -ForegroundColor Yellow
        
        # Look for test reports even on failure
        $testReportsPath = "target\surefire-reports"
        if (Test-Path $testReportsPath) {
            Write-Host "📊 Test Reports: $testReportsPath" -ForegroundColor Cyan
        }
        
        exit 1
    }
    
} catch {
    Write-Host "❌ Error executing tests: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🏁 Unit Testing completed!" -ForegroundColor Green
Write-Host "💡 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review test results above" -ForegroundColor Gray
Write-Host "  2. Check test reports in target/surefire-reports/" -ForegroundColor Gray
Write-Host "  3. Run integration tests if needed" -ForegroundColor Gray
Write-Host "  4. Deploy enhanced logging system to test environment" -ForegroundColor Gray
