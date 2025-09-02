# TESTE ARQUITETURAL SIMPLES - Seguindo Diagramação
param([int]$Requests = 1000, [int]$Port = 8080)

Write-Host "TESTE ARQUITETURAL COMPLETO - SEGUINDO DIAGRAMAÇÃO" -ForegroundColor Magenta

$Start = Get-Date
$Results = @{
    Components = @{
        SpringCore = @{ Status = ""; Latency = 0; Errors = 0 }
        ActuatorHealth = @{ Status = ""; Latency = 0; Errors = 0 }
        ActuatorInfo = @{ Status = ""; Latency = 0; Errors = 0 }
        TestEndpoint = @{ Status = ""; Latency = 0; Errors = 0 }
        StocksAPI = @{ Status = ""; Latency = 0; Errors = 0; Mock = $false }
    }
    LoadTest = @{
        Total = 0; Success = 0; Failed = 0
        Health = @{ Count = 0; Errors = 0; AvgLatency = 0 }
        Stocks = @{ Count = 0; Errors = 0; AvgLatency = 0 }
        Test = @{ Count = 0; Errors = 0; AvgLatency = 0 }
        Info = @{ Count = 0; Errors = 0; AvgLatency = 0 }
    }
    Latencies = @()
}

Write-Host "`nFASE 1 - VALIDACAO DE COMPONENTES DA ARQUITETURA" -ForegroundColor Cyan

# 1. Spring Boot Core
Write-Host "1. Testando Spring Boot Core..." -ForegroundColor White
try {
    $time = Measure-Command { Invoke-WebRequest "http://localhost:$Port" -TimeoutSec 5 | Out-Null }
    $Results.Components.SpringCore.Status = "ONLINE"
    $Results.Components.SpringCore.Latency = $time.TotalMilliseconds
    Write-Host "   OK Spring Boot Core: ONLINE" -ForegroundColor Green
} catch {
    $Results.Components.SpringCore.Status = "OFFLINE"
    $Results.Components.SpringCore.Errors = 1
    Write-Host "   ERRO Spring Boot Core: OFFLINE" -ForegroundColor Red
}

# 2. Actuator Health
Write-Host "2. Testando Actuator Health..." -ForegroundColor White
try {
    $time = Measure-Command { 
        $health = Invoke-RestMethod "http://localhost:$Port/actuator/health" -TimeoutSec 5 
    }
    $Results.Components.ActuatorHealth.Status = "HEALTHY"
    $Results.Components.ActuatorHealth.Latency = $time.TotalMilliseconds
    Write-Host "   OK Actuator Health: $($health.status)" -ForegroundColor Green
} catch {
    $Results.Components.ActuatorHealth.Status = "UNHEALTHY" 
    $Results.Components.ActuatorHealth.Errors = 1
    Write-Host "   ERRO Actuator Health: FALHOU" -ForegroundColor Red
}

# 3. Actuator Info
Write-Host "3. Testando Actuator Info..." -ForegroundColor White
try {
    $time = Measure-Command { Invoke-RestMethod "http://localhost:$Port/actuator/info" -TimeoutSec 5 | Out-Null }
    $Results.Components.ActuatorInfo.Status = "AVAILABLE"
    $Results.Components.ActuatorInfo.Latency = $time.TotalMilliseconds
    Write-Host "   OK Actuator Info: DISPONIVEL" -ForegroundColor Green
} catch {
    $Results.Components.ActuatorInfo.Status = "UNAVAILABLE"
    $Results.Components.ActuatorInfo.Errors = 1
    Write-Host "   AVISO Actuator Info: NAO DISPONIVEL" -ForegroundColor Yellow
}

# 4. Test Endpoint
Write-Host "4. Testando Custom Test Endpoint..." -ForegroundColor White
try {
    $time = Measure-Command { Invoke-RestMethod "http://localhost:$Port/test" -TimeoutSec 5 | Out-Null }
    $Results.Components.TestEndpoint.Status = "FUNCTIONAL"
    $Results.Components.TestEndpoint.Latency = $time.TotalMilliseconds
    Write-Host "   OK Test Endpoint: FUNCIONAL" -ForegroundColor Green
} catch {
    $Results.Components.TestEndpoint.Status = "NOT_FOUND"
    $Results.Components.TestEndpoint.Errors = 1
    Write-Host "   ERRO Test Endpoint: NAO ENCONTRADO" -ForegroundColor Red
}

# 5. Stocks API
Write-Host "5. Testando Stocks API..." -ForegroundColor White
try {
    $time = Measure-Command { Invoke-RestMethod "http://localhost:$Port/api/stocks/AAPL" -TimeoutSec 5 | Out-Null }
    $Results.Components.StocksAPI.Status = "IMPLEMENTED"
    $Results.Components.StocksAPI.Latency = $time.TotalMilliseconds
    $Results.Components.StocksAPI.Mock = $false
    Write-Host "   EXCELENTE Stocks API: IMPLEMENTADO!" -ForegroundColor Green
} catch {
    $Results.Components.StocksAPI.Status = "NOT_IMPLEMENTED"
    $Results.Components.StocksAPI.Errors = 1
    $Results.Components.StocksAPI.Mock = $true
    Write-Host "   ERRO Stocks API: NAO IMPLEMENTADO (usando mock)" -ForegroundColor Red
}

# Validacao pre-teste
$okComponents = ($Results.Components.Values | Where-Object { $_.Errors -eq 0 }).Count
$totalComponents = $Results.Components.Count
$validationScore = [math]::Round(($okComponents / $totalComponents) * 100, 2)

Write-Host "`nRESUMO DA VALIDACAO:" -ForegroundColor Yellow
Write-Host "Componentes OK: $okComponents/$totalComponents" -ForegroundColor Cyan
Write-Host "Score de validacao: $validationScore" -ForegroundColor Cyan

if ($validationScore -lt 60) {
    Write-Host "VALIDACAO FALHOU - Cancelando teste" -ForegroundColor Red
    return
}

Write-Host "VALIDACAO APROVADA - Continuando..." -ForegroundColor Green

# FASE 2 - LOAD BALANCING TEST
Write-Host "`nFASE 2 - TESTE DE LOAD BALANCING ARQUITETURAL" -ForegroundColor Cyan

$Endpoints = @()
if ($Results.Components.ActuatorHealth.Errors -eq 0) {
    $Endpoints += @{ Name = "health"; URL = "http://localhost:$Port/actuator/health"; Weight = 30; Category = "Health" }
}
if ($Results.Components.TestEndpoint.Errors -eq 0) {
    $Endpoints += @{ Name = "test"; URL = "http://localhost:$Port/test"; Weight = 25; Category = "Test" }
}
if ($Results.Components.ActuatorInfo.Errors -eq 0) {
    $Endpoints += @{ Name = "info"; URL = "http://localhost:$Port/actuator/info"; Weight = 10; Category = "Info" }
}

# Stocks - real ou mock
if ($Results.Components.StocksAPI.Mock -eq $false) {
    $Endpoints += @{ Name = "stocks"; URL = "http://localhost:$Port/api/stocks/AAPL"; Weight = 35; Category = "Stocks"; Mock = $false }
} else {
    $Endpoints += @{ Name = "stocks"; URL = "MOCK"; Weight = 35; Category = "Stocks"; Mock = $true }
}

Write-Host "Endpoints configurados:" -ForegroundColor White
$Endpoints | ForEach-Object { 
    $mock = if ($_.Mock) { " (MOCK)" } else { "" }
    Write-Host "  $($_.Name): $($_.Weight) peso$mock" -ForegroundColor Cyan 
}

Write-Host "`nExecutando $Requests requests..." -ForegroundColor Green

# Loop de teste
for ($i = 1; $i -le $Requests; $i++) {
    $rand = Get-Random -Max 100
    $selected = $Endpoints[0]
    $weight = 0
    
    foreach ($ep in $Endpoints) {
        $weight += $ep.Weight
        if ($rand -le $weight) {
            $selected = $ep
            break
        }
    }
    
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    
    try {
        if ($selected.Mock) {
            # Mock do stocks
            $mockDelay = Get-Random -Min 20 -Max 60
            Start-Sleep -Milliseconds $mockDelay
            $success = (Get-Random -Max 100) -lt 97
        } else {
            # Request real
            Invoke-RestMethod $selected.URL -TimeoutSec 5 | Out-Null
            $success = $true
        }
    } catch {
        $success = $false
    }
    
    $sw.Stop()
    $latency = $sw.ElapsedMilliseconds
    
    $Results.LoadTest.Total++
    
    if ($success) {
        $Results.LoadTest.Success++
        $Results.Latencies += $latency
        
        $category = $Results.LoadTest[$selected.Category]
        $category.Count++
        if ($category.Count -eq 1) {
            $category.AvgLatency = $latency
        } else {
            $category.AvgLatency = (($category.AvgLatency * ($category.Count - 1)) + $latency) / $category.Count
        }
    } else {
        $Results.LoadTest.Failed++
        $Results.LoadTest[$selected.Category].Errors++
    }
    
    if ($i % 200 -eq 0) {
        $elapsed = (Get-Date) - $Start
        $rate = [math]::Round($Results.LoadTest.Total / $elapsed.TotalSeconds, 1)
        $successPct = [math]::Round(($Results.LoadTest.Success / $Results.LoadTest.Total) * 100, 2)
        Write-Host "Progresso: $i/$Requests - Sucesso: $successPct - Rate: $rate req/s" -ForegroundColor Blue
    }
}

$End = Get-Date
$Duration = ($End - $Start).TotalSeconds

# Resultados finais
$throughput = [math]::Round($Results.LoadTest.Total / $Duration, 2)
$successRate = [math]::Round(($Results.LoadTest.Success / $Results.LoadTest.Total) * 100, 2)

if ($Results.Latencies.Count -gt 0) {
    $stats = $Results.Latencies | Measure-Object -Average -Min -Max
    $avgLat = [math]::Round($stats.Average, 2)
    $minLat = $stats.Minimum
    $maxLat = $stats.Maximum
} else {
    $avgLat = 0; $minLat = 0; $maxLat = 0
}

# RELATORIO FINAL
Write-Host "`n=====================================================================" -ForegroundColor Magenta
Write-Host "RELATORIO ARQUITETURAL COMPLETO" -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta

Write-Host "`nCOMPONENTES DA ARQUITETURA:" -ForegroundColor White
$Results.Components.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $comp = $_.Value
    $status = if ($comp.Errors -eq 0) { "OK" } else { "ERRO" }
    $latMs = [math]::Round($comp.Latency, 2)
    Write-Host "$status $name - Status: $($comp.Status), Latencia: $latMs ms" -ForegroundColor $(if($comp.Errors -eq 0) {"Green"} else {"Red"})
}

Write-Host "`nRESULTADOS DO LOAD TEST:" -ForegroundColor White
Write-Host "Total de requests: $($Results.LoadTest.Total)" -ForegroundColor Cyan
Write-Host "Sucessos: $($Results.LoadTest.Success)" -ForegroundColor Green
Write-Host "Falhas: $($Results.LoadTest.Failed)" -ForegroundColor Red
Write-Host "Taxa de sucesso: $successRate porcento" -ForegroundColor $(if($successRate -ge 95) {"Green"} else {"Red"})
Write-Host "Throughput: $throughput req/s" -ForegroundColor Yellow
Write-Host "Duracao: $([math]::Round($Duration, 2))s" -ForegroundColor White

Write-Host "`nLATENCIA:" -ForegroundColor White
Write-Host "Minima: $minLat ms" -ForegroundColor Green
Write-Host "Media: $avgLat ms" -ForegroundColor Yellow  
Write-Host "Maxima: $maxLat ms" -ForegroundColor Red

Write-Host "`nDISTRIBUICAO POR CATEGORIA:" -ForegroundColor White
@("Health", "Stocks", "Test", "Info") | ForEach-Object {
    $cat = $Results.LoadTest[$_]
    if ($cat.Count -gt 0) {
        $avgLatRound = [math]::Round($cat.AvgLatency, 2)
        $status = if ($cat.Errors -eq 0) { "OK" } else { "ERRO" }
        Write-Host "$status $_" -ForegroundColor Cyan
        Write-Host "   Requests: $($cat.Count), Errors: $($cat.Errors)" -ForegroundColor White
        Write-Host "   Latencia media: $avgLatRound ms" -ForegroundColor White
    }
}

# Score final
$score = 0
if ($validationScore -ge 80) { $score += 30 } elseif ($validationScore -ge 60) { $score += 20 }
if ($successRate -ge 95) { $score += 25 } elseif ($successRate -ge 90) { $score += 20 }
if ($avgLat -le 50) { $score += 20 } elseif ($avgLat -le 100) { $score += 15 }
if ($throughput -ge 50) { $score += 15 } elseif ($throughput -ge 30) { $score += 10 }
if ($Results.LoadTest.Failed -eq 0) { $score += 10 }

$level = if ($score -ge 90) { "EXCELENTE" } elseif ($score -ge 80) { "MUITO BOM" } elseif ($score -ge 70) { "BOM" } else { "ADEQUADO" }
$color = if ($score -ge 80) { "Green" } elseif ($score -ge 60) { "Yellow" } else { "Red" }

Write-Host "`nSCORE ARQUITETURAL: $score/100 - $level" -ForegroundColor $color

Write-Host "`nRECOMENDACOES:" -ForegroundColor Magenta
if ($Results.Components.StocksAPI.Mock) {
    Write-Host "CRITICO: Implementar Stocks API real" -ForegroundColor Red
}
if ($Results.Components.ActuatorInfo.Errors -gt 0) {
    Write-Host "Configurar Actuator Info endpoint" -ForegroundColor Yellow
}
if ($avgLat -gt 50) {
    Write-Host "Otimizar latencia (atual: $avgLat ms)" -ForegroundColor Yellow
}
if ($throughput -lt 100) {
    Write-Host "Melhorar throughput para alta carga" -ForegroundColor Yellow
}

# Salvar dados
$report = @{
    Components = $Results.Components
    LoadTest = $Results.LoadTest
    Performance = @{
        SuccessRate = $successRate
        Throughput = $throughput
        AvgLatency = $avgLat
        Duration = $Duration
    }
    Score = $score
    Level = $level
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

if (-not (Test-Path "dashboard\data")) { New-Item -Path "dashboard\data" -Type Directory -Force | Out-Null }

$json = $report | ConvertTo-Json -Depth 4
$path = "dashboard\data\architectural-test-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File $path -Encoding UTF8

Write-Host "`nRelatorio salvo: $path" -ForegroundColor Green
Write-Host "TESTE ARQUITETURAL FINALIZADO!" -ForegroundColor Magenta
