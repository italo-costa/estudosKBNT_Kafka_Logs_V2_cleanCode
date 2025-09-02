# Manual Test Validation Script
# This script validates test file structure and readiness without executing tests
param()

Write-Host "Manual Test Validation for KBNT Kafka Enhanced Logging System" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan

$baseDir = "c:\workspace\estudosKBNT_Kafka_Logs\microservices\kbnt-log-service"
$testDir = "$baseDir\src\test\java\com\estudoskbnt\kbntlogservice"

Write-Host "Validating test files structure and content..." -ForegroundColor Yellow

# Test file validation
$testFiles = @{
    "StockUpdateProducerTest.java" = "$testDir\producer\StockUpdateProducerTest.java"
    "StockUpdateControllerTest.java" = "$testDir\controller\StockUpdateControllerTest.java"
    "KafkaPublicationLogTest.java" = "$testDir\model\KafkaPublicationLogTest.java"
}

$totalTests = 0
$totalFiles = 0

foreach ($testName in $testFiles.Keys) {
    $filePath = $testFiles[$testName]
    Write-Host ""
    Write-Host "Validating: $testName" -ForegroundColor Green
    
    if (Test-Path $filePath) {
        $totalFiles++
        Write-Host "  ✅ File exists: $filePath" -ForegroundColor Green
        
        # Get file stats
        $fileInfo = Get-Item $filePath
        Write-Host "  📊 File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
        Write-Host "  📅 Last modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        
        # Count test methods
        $content = Get-Content $filePath -Raw
        $testMethods = ([regex]"@Test").Matches($content).Count
        $totalTests += $testMethods
        Write-Host "  🧪 Test methods found: $testMethods" -ForegroundColor Cyan
        
        # Check for key annotations and imports
        $hasJUnit5 = $content -match "org\.junit\.jupiter\.api"
        $hasMockito = $content -match "org\.mockito"
        $hasSpringTest = $content -match "org\.springframework\.test"
        
        Write-Host "  📦 JUnit 5: $(if($hasJUnit5) {'✅'} else {'❌'})" -ForegroundColor $(if($hasJUnit5) {'Green'} else {'Red'})
        Write-Host "  📦 Mockito: $(if($hasMockito) {'✅'} else {'❌'})" -ForegroundColor $(if($hasMockito) {'Green'} else {'Red'})
        Write-Host "  📦 Spring Test: $(if($hasSpringTest) {'✅'} else {'❌'})" -ForegroundColor $(if($hasSpringTest) {'Green'} else {'Red'})
        
        # Check specific test categories based on file type
        if ($testName -eq "StockUpdateProducerTest.java") {
            $hasHashTests = $content -match "generateMessageHash"
            $hasTopicTests = $content -match "determineTopicName"
            $hasLoggingTests = $content -match "logPublication"
            
            Write-Host "  🔍 Hash generation tests: $(if($hasHashTests) {'✅'} else {'❌'})" -ForegroundColor $(if($hasHashTests) {'Green'} else {'Red'})
            Write-Host "  🔍 Topic routing tests: $(if($hasTopicTests) {'✅'} else {'❌'})" -ForegroundColor $(if($hasTopicTests) {'Green'} else {'Red'})
            Write-Host "  🔍 Publication logging tests: $(if($hasLoggingTests) {'✅'} else {'❌'})" -ForegroundColor $(if($hasLoggingTests) {'Green'} else {'Red'})
        }
        
        if ($testName -eq "StockUpdateControllerTest.java") {
            $hasMockMvc = $content -match "@WebMvcTest"
            $hasValidation = $content -match "InvalidProductId"
            $hasEndpoints = $content -match "/stock/update"
            
            Write-Host "  🔍 MockMvc integration: $(if($hasMockMvc) {'✅'} else {'❌'})" -ForegroundColor $(if($hasMockMvc) {'Green'} else {'Red'})
            Write-Host "  🔍 Validation tests: $(if($hasValidation) {'✅'} else {'❌'})" -ForegroundColor $(if($hasValidation) {'Green'} else {'Red'})
            Write-Host "  🔍 REST endpoint tests: $(if($hasEndpoints) {'✅'} else {'❌'})" -ForegroundColor $(if($hasEndpoints) {'Green'} else {'Red'})
        }
        
        if ($testName -eq "KafkaPublicationLogTest.java") {
            $hasBuilderTests = $content -match "builder\(\)"
            $hasStatusTests = $content -match "PublicationStatus"
            $hasConstructorTests = $content -match "shouldUseNoArgsConstructor"
            
            Write-Host "  🔍 Builder pattern tests: $(if($hasBuilderTests) {'✅'} else {'❌'})" -ForegroundColor $(if($hasBuilderTests) {'Green'} else {'Red'})
            Write-Host "  🔍 Status enum tests: $(if($hasStatusTests) {'✅'} else {'❌'})" -ForegroundColor $(if($hasStatusTests) {'Green'} else {'Red'})
            Write-Host "  🔍 Constructor tests: $(if($hasConstructorTests) {'✅'} else {'❌'})" -ForegroundColor $(if($hasConstructorTests) {'Green'} else {'Red'})
        }
        
    } else {
        Write-Host "  ❌ File not found: $filePath" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total test files validated: $totalFiles / 3" -ForegroundColor $(if($totalFiles -eq 3) {'Green'} else {'Red'})
Write-Host "Total test methods found: $totalTests" -ForegroundColor Cyan

# Check main source files exist
Write-Host ""
Write-Host "Validating main source files..." -ForegroundColor Yellow
$sourceFiles = @{
    "StockUpdateProducer.java" = "$baseDir\src\main\java\com\estudoskbnt\kbntlogservice\service\StockUpdateProducer.java"
    "StockUpdateController.java" = "$baseDir\src\main\java\com\estudoskbnt\kbntlogservice\controller\StockUpdateController.java"
    "KafkaPublicationLog.java" = "$baseDir\src\main\java\com\estudoskbnt\kbntlogservice\model\KafkaPublicationLog.java"
    "StockUpdateMessage.java" = "$baseDir\src\main\java\com\estudoskbnt\kbntlogservice\model\StockUpdateMessage.java"
}

$sourceCount = 0
foreach ($sourceName in $sourceFiles.Keys) {
    $sourcePath = $sourceFiles[$sourceName]
    if (Test-Path $sourcePath) {
        $sourceCount++
        Write-Host "  ✅ $sourceName" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $sourceName - NOT FOUND" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Source files available: $sourceCount / 4" -ForegroundColor $(if($sourceCount -eq 4) {'Green'} else {'Red'})

# Check pom.xml
Write-Host ""
Write-Host "Checking Maven configuration..." -ForegroundColor Yellow
$pomPath = "$baseDir\pom.xml"
if (Test-Path $pomPath) {
    Write-Host "  ✅ pom.xml found" -ForegroundColor Green
    $pomContent = Get-Content $pomPath -Raw
    
    $hasJUnit = $pomContent -match "junit-jupiter"
    $hasMockito = $pomContent -match "mockito"
    $hasSpring = $pomContent -match "spring-boot-starter-test"
    
    Write-Host "  📦 JUnit dependency: $(if($hasJUnit) {'✅'} else {'❌'})" -ForegroundColor $(if($hasJUnit) {'Green'} else {'Red'})
    Write-Host "  📦 Mockito dependency: $(if($hasMockito) {'✅'} else {'❌'})" -ForegroundColor $(if($hasMockito) {'Green'} else {'Red'})
    Write-Host "  📦 Spring Test dependency: $(if($hasSpring) {'✅'} else {'❌'})" -ForegroundColor $(if($hasSpring) {'Green'} else {'Red'})
} else {
    Write-Host "  ❌ pom.xml not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FINAL ASSESSMENT ===" -ForegroundColor Green
if ($totalFiles -eq 3 -and $totalTests -ge 35 -and $sourceCount -ge 3) {
    Write-Host "🎉 TEST SUITE READY FOR EXECUTION!" -ForegroundColor Green
    Write-Host "✅ All test files present and properly structured" -ForegroundColor Green
    Write-Host "✅ $totalTests comprehensive test methods implemented" -ForegroundColor Green
    Write-Host "✅ Source files available for testing" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Install Java JDK 17+ and Maven 3.8+" -ForegroundColor Gray
    Write-Host "2. Run: mvn test -Dtest=StockUpdateProducerTest,StockUpdateControllerTest,KafkaPublicationLogTest" -ForegroundColor Gray
    Write-Host "3. Or use VS Code Java Extension Pack with Test Explorer" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Test suite incomplete or has issues" -ForegroundColor Yellow
    Write-Host "Please check the validation results above" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Manual validation completed!" -ForegroundColor Cyan
