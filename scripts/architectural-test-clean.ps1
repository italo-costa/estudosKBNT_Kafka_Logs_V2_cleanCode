# TESTE ARQUITETURAL COMPLETO - Seguindo Diagramação
# Teste todos os componentes da arquitetura sem custos
param([int]$TotalRequests = 1000, [int]$Port = 8080)

Write-Host "TESTE ARQUITETURAL COMPLETO - Seguindo Diagramação" -ForegroundColor Magenta
Write-Host "Baseado na arquitetura documentada - SEM CUSTOS" -ForegroundColor Yellow

$TestStart = Get-Date
$ArchResults = @{
    PreValidation = @{ Health = $null; Info = $null; Connectivity = $null }
    ComponentTests = @{
        "SpringBootCore" = @{ Tested = $false; Status = ""; Latency = 0; Errors = 0 }
        "ActuatorHealth" = @{ Tested = $false; Status = ""; Latency = 0; Errors = 0 }
        "ActuatorInfo" = @{ Tested = $false; Status = ""; Latency = 0; Errors = 0 }
        "TestEndpoint" = @{ Tested = $false; Status = ""; Latency = 0; Errors = 0 }
        "StocksAPI" = @{ Tested = $false; Status = ""; Latency = 0; Errors = 0; IsMocked = $false }
    }
    LoadBalancing = @{
        Distribution = @{
            "ActuatorHealth" = @{ Weight = 30; Count = 0; AvgLatency = 0; Errors = 0 }
            "StocksAPI" = @{ Weight = 35; Count = 0; AvgLatency = 0; Errors = 0 }
            "TestEndpoint" = @{ Weight = 25; Count = 0; AvgLatency = 0; Errors = 0 }
            "ActuatorInfo" = @{ Weight = 10; Count = 0; AvgLatency = 0; Errors = 0 }
        }
    }
    TotalRequests = 0; SuccessRequests = 0; FailedRequests = 0
    Latencies = @(); SlowRequests = @()
    ArchitecturalCompliance = @{ Score = 0; Issues = @(); Validations = @() }
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "FASE 1 - PRE-VALIDACAO ARQUITETURAL" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. TESTE DE CONECTIVIDADE CORE
Write-Host "`n1. Testando Spring Boot Core..." -ForegroundColor White
try {
    $coreTest = Measure-Command { 
        $response = Invoke-WebRequest "http://localhost:$Port" -TimeoutSec 5 -ErrorAction Stop
    }
    $ArchResults.ComponentTests.SpringBootCore = @{ 
        Tested = $true; Status = "ONLINE"; 
        Latency = $coreTest.TotalMilliseconds; Errors = 0 
    }
    $latencyMs = [math]::Round($coreTest.TotalMilliseconds, 2)
    Write-Host "   ✅ Spring Boot Core: ONLINE ($latencyMs ms)" -ForegroundColor Green
    $ArchResults.ArchitecturalCompliance.Validations += "SpringBoot Core funcional"
} catch {
    $ArchResults.ComponentTests.SpringBootCore.Status = "OFFLINE"
    $ArchResults.ComponentTests.SpringBootCore.Errors = 1
    Write-Host "   ❌ Spring Boot Core: OFFLINE" -ForegroundColor Red
    $ArchResults.ArchitecturalCompliance.Issues += "SpringBoot Core inacessível"
}

# 2. TESTE ACTUATOR HEALTH
Write-Host "`n2. Testando Actuator Health Endpoint..." -ForegroundColor White
try {
    $healthTest = Measure-Command {
        $healthResponse = Invoke-RestMethod "http://localhost:$Port/actuator/health" -TimeoutSec 5
    }
    $ArchResults.ComponentTests.ActuatorHealth = @{
        Tested = $true; Status = "HEALTHY"; 
        Latency = $healthTest.TotalMilliseconds; Errors = 0
    }
    $ArchResults.PreValidation.Health = $healthResponse
    $healthLatency = [math]::Round($healthTest.TotalMilliseconds, 2)
    Write-Host "   ✅ Actuator Health: $($healthResponse.status) ($healthLatency ms)" -ForegroundColor Green
    $ArchResults.ArchitecturalCompliance.Validations += "Actuator Health endpoint funcional"
} catch {
    $ArchResults.ComponentTests.ActuatorHealth.Status = "UNHEALTHY"
    $ArchResults.ComponentTests.ActuatorHealth.Errors = 1
    Write-Host "   ❌ Actuator Health: FALHOU" -ForegroundColor Red
    $ArchResults.ArchitecturalCompliance.Issues += "Actuator Health não responsivo"
}

# 3. TESTE ACTUATOR INFO
Write-Host "`n3. Testando Actuator Info Endpoint..." -ForegroundColor White
try {
    $infoTest = Measure-Command {
        $infoResponse = Invoke-RestMethod "http://localhost:$Port/actuator/info" -TimeoutSec 5
    }
    $ArchResults.ComponentTests.ActuatorInfo = @{
        Tested = $true; Status = "AVAILABLE"; 
        Latency = $infoTest.TotalMilliseconds; Errors = 0
    }
    $ArchResults.PreValidation.Info = $infoResponse
    $infoLatency = [math]::Round($infoTest.TotalMilliseconds, 2)
    Write-Host "   ✅ Actuator Info: DISPONÍVEL ($infoLatency ms)" -ForegroundColor Green
    $ArchResults.ArchitecturalCompliance.Validations += "Actuator Info endpoint funcional"
} catch {
    $ArchResults.ComponentTests.ActuatorInfo.Status = "UNAVAILABLE"
    $ArchResults.ComponentTests.ActuatorInfo.Errors = 1
    Write-Host "   ⚠️  Actuator Info: NÃO DISPONÍVEL" -ForegroundColor Yellow
    $ArchResults.ArchitecturalCompliance.Issues += "Actuator Info não configurado"
}

# 4. TESTE CUSTOM TEST ENDPOINT
Write-Host "`n4. Testando Custom Test Endpoint..." -ForegroundColor White
try {
    $testEndpointTest = Measure-Command {
        $testResponse = Invoke-RestMethod "http://localhost:$Port/test" -TimeoutSec 5
    }
    $ArchResults.ComponentTests.TestEndpoint = @{
        Tested = $true; Status = "FUNCTIONAL"; 
        Latency = $testEndpointTest.TotalMilliseconds; Errors = 0
    }
    $testLatency = [math]::Round($testEndpointTest.TotalMilliseconds, 2)
    Write-Host "   ✅ Test Endpoint: FUNCIONAL ($testLatency ms)" -ForegroundColor Green
    $ArchResults.ArchitecturalCompliance.Validations += "Custom Test endpoint implementado"
} catch {
    $ArchResults.ComponentTests.TestEndpoint.Status = "NOT_FOUND"
    $ArchResults.ComponentTests.TestEndpoint.Errors = 1
    Write-Host "   ❌ Test Endpoint: NÃO ENCONTRADO" -ForegroundColor Red
    $ArchResults.ArchitecturalCompliance.Issues += "Custom Test endpoint não implementado"
}

# 5. TESTE STOCKS API
Write-Host "`n5. Testando Stocks API Endpoint..." -ForegroundColor White
try {
    $stocksTest = Measure-Command {
        $stocksResponse = Invoke-RestMethod "http://localhost:$Port/api/stocks/AAPL" -TimeoutSec 5
    }
    $ArchResults.ComponentTests.StocksAPI = @{
        Tested = $true; Status = "IMPLEMENTED"; 
        Latency = $stocksTest.TotalMilliseconds; Errors = 0; IsMocked = $false
    }
    $stocksLatency = [math]::Round($stocksTest.TotalMilliseconds, 2)
    Write-Host "   🎉 Stocks API: IMPLEMENTADO! ($stocksLatency ms)" -ForegroundColor Green
    $ArchResults.ArchitecturalCompliance.Validations += "Stocks API real implementado"
} catch {
    $ArchResults.ComponentTests.StocksAPI = @{
        Tested = $true; Status = "NOT_IMPLEMENTED"; 
        Latency = 0; Errors = 1; IsMocked = $true
    }
    Write-Host "   ❌ Stocks API: NÃO IMPLEMENTADO (será mockado)" -ForegroundColor Red
    $ArchResults.ArchitecturalCompliance.Issues += "Stocks API ainda não implementado - usando mock"
}

# RELATÓRIO DE PRÉ-VALIDAÇÃO
Write-Host "`n--------------------------------------------------" -ForegroundColor Yellow
Write-Host "RELATÓRIO DE PRÉ-VALIDAÇÃO:" -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow

$componentsOK = ($ArchResults.ComponentTests.Values | Where-Object { $_.Errors -eq 0 }).Count
$totalComponents = $ArchResults.ComponentTests.Count
$preValidationScore = [math]::Round(($componentsOK / $totalComponents) * 100, 2)

Write-Host "Componentes funcionais: $componentsOK/$totalComponents ($preValidationScore pct)" -ForegroundColor $(if($preValidationScore -ge 80) {"Green"} else {"Red"})

if ($ArchResults.ArchitecturalCompliance.Issues.Count -gt 0) {
    Write-Host "`nIssues identificados:" -ForegroundColor Red
    $ArchResults.ArchitecturalCompliance.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($ArchResults.ArchitecturalCompliance.Validations.Count -gt 0) {
    Write-Host "`nValidações bem-sucedidas:" -ForegroundColor Green
    $ArchResults.ArchitecturalCompliance.Validations | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
}

if ($preValidationScore -lt 60) {
    Write-Host "`n❌ PRÉ-VALIDAÇÃO FALHOU: Muitos componentes offline" -ForegroundColor Red
    Write-Host "Cancelando teste arquitetural..." -ForegroundColor Red
    return
}

Write-Host "`n✅ PRÉ-VALIDAÇÃO APROVADA: Continuando com teste completo..." -ForegroundColor Green

# CONFIGURAÇÃO DO LOAD BALANCING
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "FASE 2 - TESTE DE LOAD BALANCING ARQUITETURAL" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$ArchitecturalEndpoints = @()

if ($ArchResults.ComponentTests.ActuatorHealth.Errors -eq 0) {
    $ArchitecturalEndpoints += @{ Name = "health"; URL = "http://localhost:$Port/actuator/health"; Weight = 30; Component = "ActuatorHealth" }
}

if ($ArchResults.ComponentTests.TestEndpoint.Errors -eq 0) {
    $ArchitecturalEndpoints += @{ Name = "test"; URL = "http://localhost:$Port/test"; Weight = 25; Component = "TestEndpoint" }
}

if ($ArchResults.ComponentTests.ActuatorInfo.Errors -eq 0) {
    $ArchitecturalEndpoints += @{ Name = "info"; URL = "http://localhost:$Port/actuator/info"; Weight = 10; Component = "ActuatorInfo" }
}

if ($ArchResults.ComponentTests.StocksAPI.Status -eq "IMPLEMENTED") {
    $ArchitecturalEndpoints += @{ Name = "stocks"; URL = "http://localhost:$Port/api/stocks/AAPL"; Weight = 35; Component = "StocksAPI"; IsMocked = $false }
} else {
    $ArchitecturalEndpoints += @{ Name = "stocks"; URL = "MOCK"; Weight = 35; Component = "StocksAPI"; IsMocked = $true }
}

Write-Host "Endpoints arquiteturais configurados:" -ForegroundColor White
$ArchitecturalEndpoints | ForEach-Object {
    $mockStatus = if ($_.IsMocked) { " (MOCKADO)" } else { "" }
    Write-Host "  - $($_.Name): $($_.Weight) pct - $($_.Component)$mockStatus" -ForegroundColor Cyan
}

Write-Host "`nExecutando $TotalRequests requests seguindo distribuição arquitetural..." -ForegroundColor Green

# LOOP PRINCIPAL
for ($i = 1; $i -le $TotalRequests; $i++) {
    $rand = Get-Random -Max 100
    $selectedEndpoint = $ArchitecturalEndpoints[0]
    $cumWeight = 0
    
    foreach ($endpoint in $ArchitecturalEndpoints) {
        $cumWeight += $endpoint.Weight
        if ($rand -le $cumWeight) {
            $selectedEndpoint = $endpoint
            break
        }
    }
    
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    
    try {
        if ($selectedEndpoint.IsMocked) {
            $mockLatency = Get-Random -Min 20 -Max 60
            Start-Sleep -Milliseconds $mockLatency
            $success = (Get-Random -Max 100) -lt 97
        } else {
            $response = Invoke-RestMethod $selectedEndpoint.URL -TimeoutSec 5
            $success = $true
        }
    } catch {
        $success = $false
    }
    
    $sw.Stop()
    $latency = $sw.ElapsedMilliseconds
    
    $ArchResults.TotalRequests++
    
    if ($success) {
        $ArchResults.SuccessRequests++
        $ArchResults.Latencies += $latency
        
        $component = $ArchResults.LoadBalancing.Distribution[$selectedEndpoint.Component]
        $component.Count++
        if ($component.Count -eq 1) {
            $component.AvgLatency = $latency
        } else {
            $component.AvgLatency = (($component.AvgLatency * ($component.Count - 1)) + $latency) / $component.Count
        }
        
        if ($latency -gt 200) {
            $ArchResults.SlowRequests += @{ 
                Id = $i; Endpoint = $selectedEndpoint.Name; 
                Component = $selectedEndpoint.Component; Latency = $latency 
            }
        }
    } else {
        $ArchResults.FailedRequests++
        $ArchResults.LoadBalancing.Distribution[$selectedEndpoint.Component].Errors++
    }
    
    if ($i % 100 -eq 0) {
        $elapsed = (Get-Date) - $TestStart
        $rate = [math]::Round($ArchResults.TotalRequests / $elapsed.TotalSeconds, 1)
        $successRate = [math]::Round(($ArchResults.SuccessRequests / $ArchResults.TotalRequests) * 100, 2)
        Write-Host "Progress: $i/$TotalRequests - Taxa: $successRate pct - Throughput: $rate req/s" -ForegroundColor Blue
    }
}

$TestEnd = Get-Date
$Duration = ($TestEnd - $TestStart).TotalSeconds

$finalThroughput = [math]::Round($ArchResults.TotalRequests / $Duration, 2)
$finalSuccessRate = [math]::Round(($ArchResults.SuccessRequests / $ArchResults.TotalRequests) * 100, 2)

if ($ArchResults.Latencies.Count -gt 0) {
    $stats = $ArchResults.Latencies | Measure-Object -Average -Min -Max
    $avgLatency = [math]::Round($stats.Average, 2)
    $minLatency = $stats.Minimum
    $maxLatency = $stats.Maximum
    
    $sorted = $ArchResults.Latencies | Sort-Object
    $p95 = $sorted[[math]::Floor($sorted.Count * 0.95)]
    $p99 = $sorted[[math]::Floor($sorted.Count * 0.99)]
} else {
    $avgLatency = 0; $minLatency = 0; $maxLatency = 0; $p95 = 0; $p99 = 0
}

# RELATÓRIO FINAL
Write-Host "`n======================================================================" -ForegroundColor Magenta
Write-Host "RELATÓRIO ARQUITETURAL COMPLETO" -ForegroundColor Magenta
Write-Host "======================================================================" -ForegroundColor Magenta

Write-Host "`nRESUMO GERAL:" -ForegroundColor White
Write-Host "Requests totais: $($ArchResults.TotalRequests)" -ForegroundColor Cyan
Write-Host "Sucessos: $($ArchResults.SuccessRequests)" -ForegroundColor Green
Write-Host "Falhas: $($ArchResults.FailedRequests)" -ForegroundColor Red
Write-Host "Taxa de sucesso: $finalSuccessRate pct" -ForegroundColor $(if($finalSuccessRate -ge 95) {"Green"} else {"Red"})
Write-Host "Throughput: $finalThroughput req/s" -ForegroundColor Yellow
Write-Host "Duracao: $([math]::Round($Duration, 2))s" -ForegroundColor White

Write-Host "`nLATENCIA:" -ForegroundColor White
Write-Host "Minima: $minLatency ms" -ForegroundColor Green
Write-Host "Media: $avgLatency ms" -ForegroundColor Yellow
Write-Host "Maxima: $maxLatency ms" -ForegroundColor Red
Write-Host "P95: $p95 ms" -ForegroundColor Yellow
Write-Host "P99: $p99 ms" -ForegroundColor Red

Write-Host "`nDISTRIBUIÇÃO POR COMPONENTE ARQUITETURAL:" -ForegroundColor White
$ArchResults.LoadBalancing.Distribution.GetEnumerator() | Sort-Object {$_.Value.Count} -Desc | ForEach-Object {
    $compName = $_.Key
    $compData = $_.Value
    if ($compData.Count -gt 0) {
        $errorRate = [math]::Round(($compData.Errors / ($compData.Count + $compData.Errors)) * 100, 2)
        $avgLat = [math]::Round($compData.AvgLatency, 2)
        $status = if ($compData.Errors -eq 0) { "✅" } else { "❌" }
        Write-Host "$status $compName" -ForegroundColor Cyan
        Write-Host "   Requests: $($compData.Count), Errors: $($compData.Errors) ($errorRate pct)" -ForegroundColor White
        Write-Host "   Latência média: $avgLat ms" -ForegroundColor White
    }
}

Write-Host "`nREQUESTS LENTOS (>200ms):" -ForegroundColor Yellow
if ($ArchResults.SlowRequests.Count -gt 0) {
    Write-Host "Total: $($ArchResults.SlowRequests.Count)" -ForegroundColor Red
    $ArchResults.SlowRequests | Sort-Object Latency -Desc | Select-Object -First 5 | ForEach-Object {
        Write-Host "  Request $($_.Id): $($_.Component) -> $($_.Endpoint) ($($_.Latency) ms)" -ForegroundColor Red
    }
} else {
    Write-Host "Nenhum request lento detectado!" -ForegroundColor Green
}

# SCORE DE CONFORMIDADE
Write-Host "`nANÁLISE DE CONFORMIDADE ARQUITETURAL:" -ForegroundColor Magenta
Write-Host "--------------------------------------------------" -ForegroundColor Magenta

$conformityScore = 0
$componentScore = ($preValidationScore / 100) * 30
$conformityScore += $componentScore

if ($finalSuccessRate -ge 95) { $conformityScore += 25 } elseif ($finalSuccessRate -ge 90) { $conformityScore += 20 }
if ($avgLatency -le 50) { $conformityScore += 20 } elseif ($avgLatency -le 100) { $conformityScore += 15 }
if ($finalThroughput -ge 50) { $conformityScore += 15 } elseif ($finalThroughput -ge 30) { $conformityScore += 10 }
if ($ArchResults.SlowRequests.Count -eq 0) { $conformityScore += 10 }

$ArchResults.ArchitecturalCompliance.Score = [math]::Round($conformityScore, 1)

$complianceLevel = if ($conformityScore -ge 90) { "EXCELENTE" }
elseif ($conformityScore -ge 80) { "MUITO BOM" }
elseif ($conformityScore -ge 70) { "BOM" }
elseif ($conformityScore -ge 60) { "ADEQUADO" }
else { "INADEQUADO" }

$levelColor = if ($conformityScore -ge 80) { "Green" } elseif ($conformityScore -ge 60) { "Yellow" } else { "Red" }

Write-Host "ARCHITECTURAL COMPLIANCE SCORE: $($ArchResults.ArchitecturalCompliance.Score)/100" -ForegroundColor $levelColor
Write-Host "CLASSIFICAÇÃO: $complianceLevel" -ForegroundColor $levelColor

# RECOMENDAÇÕES
Write-Host "`nRECOMENDAÇÕES ARQUITETURAIS:" -ForegroundColor Magenta
if ($ArchResults.ComponentTests.StocksAPI.Status -eq "NOT_IMPLEMENTED") {
    Write-Host "🔧 CRÍTICO: Implementar Stocks API real (/api/stocks/{symbol})" -ForegroundColor Red
}
if ($ArchResults.ComponentTests.ActuatorInfo.Errors -gt 0) {
    Write-Host "🔧 Configurar Actuator Info endpoint para monitoramento" -ForegroundColor Yellow
}
if ($avgLatency -gt 50) {
    Write-Host "🔧 Otimizar latência média (atual: $avgLatency ms)" -ForegroundColor Yellow
}
if ($finalThroughput -lt 100) {
    Write-Host "🔧 Melhorar throughput para cenários de alta carga" -ForegroundColor Yellow
}

# Salvar relatório
$architecturalReport = @{
    TestMetadata = @{
        Type = "ArchitecturalComplianceTest"
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Duration = $Duration
        TotalRequests = $TotalRequests
    }
    ComponentStatus = $ArchResults.ComponentTests
    LoadBalancingResults = $ArchResults.LoadBalancing
    PerformanceMetrics = @{
        TotalRequests = $ArchResults.TotalRequests
        SuccessRate = $finalSuccessRate
        Throughput = $finalThroughput
        Latency = @{ Min = $minLatency; Avg = $avgLatency; Max = $maxLatency; P95 = $p95; P99 = $p99 }
        SlowRequests = $ArchResults.SlowRequests.Count
    }
    ArchitecturalCompliance = $ArchResults.ArchitecturalCompliance
}

if (-not (Test-Path "dashboard\data")) { New-Item -Path "dashboard\data" -Type Directory -Force | Out-Null }

$json = $architecturalReport | ConvertTo-Json -Depth 5
$path = "dashboard\data\architectural-test-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File $path -Encoding UTF8

Write-Host "`nRelatório arquitetural salvo: $path" -ForegroundColor Green
Write-Host "TESTE ARQUITETURAL COMPLETO FINALIZADO!" -ForegroundColor Magenta
