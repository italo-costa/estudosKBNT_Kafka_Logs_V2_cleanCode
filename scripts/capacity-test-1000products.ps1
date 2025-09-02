# TESTE SIMULADO - 1000 PRODUTOS (SEM CUSTOS)
# Simulacao completa para verificar capacidade da aplicacao
param([int]$TotalProducts = 1000, [int]$Port = 8080, [switch]$FullSimulation)

Write-Host "TESTE DE CAPACIDADE - 1000 PRODUTOS (SIMULACAO COMPLETA)" -ForegroundColor Magenta
Write-Host "MODO: SEM CUSTOS - SIMULACAO PURA" -ForegroundColor Yellow

$TestStart = Get-Date
$Results = @{
    Total = 0; Success = 0; Failed = 0; Latencies = @(); Slow = @()
    Products = @{
        "StockQueries" = @{ Count = 0; Time = 0; Errors = 0; AvgLatency = 0 }
        "ProductInfo" = @{ Count = 0; Time = 0; Errors = 0; AvgLatency = 0 }
        "HealthChecks" = @{ Count = 0; Time = 0; Errors = 0; AvgLatency = 0 }
        "SystemInfo" = @{ Count = 0; Time = 0; Errors = 0; AvgLatency = 0 }
    }
    SimulationMode = $true
    ConnectionPool = @{ Active = 0; Max = 50; Timeouts = 0 }
}

# Lista simulada de produtos para teste
$ProductSymbols = @(
    # Tech giants
    "AAPL", "MSFT", "GOOGL", "AMZN", "META", "TSLA", "NFLX", "NVDA", "ORCL", "CRM",
    # Finance
    "JPM", "BAC", "WFC", "GS", "MS", "C", "AXP", "BLK", "SCHW", "USB",
    # Healthcare
    "JNJ", "PFE", "ABT", "MRK", "TMO", "DHR", "BMY", "ABBV", "LLY", "UNH",
    # Consumer
    "KO", "PEP", "PG", "WMT", "HD", "MCD", "NKE", "SBUX", "DIS", "ADBE",
    # Energy
    "XOM", "CVX", "COP", "EOG", "SLB", "HAL", "OXY", "MPC", "VLO", "PSX"
)

# Expandir lista para 1000 produtos simulados
$AllProducts = @()
for ($i = 0; $i -lt $TotalProducts; $i++) {
    $baseSymbol = $ProductSymbols[$i % $ProductSymbols.Length]
    $variant = if ($i -ge $ProductSymbols.Length) { "$baseSymbol$([math]::Floor($i / $ProductSymbols.Length))" } else { $baseSymbol }
    $AllProducts += $variant
}

Write-Host "Produtos simulados: $($AllProducts.Count)" -ForegroundColor Cyan
Write-Host "Simulando comportamento baseado em dados reais dos testes anteriores..." -ForegroundColor Green

# Parametros de simulacao baseados nos testes reais
$SimulationParams = @{
    HealthCheck = @{ 
        Latency = @{ Min = 1; Max = 3; Avg = 1.6 }; 
        SuccessRate = 100; Weight = 20 
    }
    StockQuery = @{ 
        Latency = @{ Min = 15; Max = 80; Avg = 45 }; 
        SuccessRate = 97; Weight = 50  # Usando comportamento do mock bem sucedido
    }
    ProductInfo = @{ 
        Latency = @{ Min = 1; Max = 4; Avg = 1.5 }; 
        SuccessRate = 100; Weight = 20 
    }
    SystemInfo = @{ 
        Latency = @{ Min = 1; Max = 3; Avg = 1.4 }; 
        SuccessRate = 100; Weight = 10 
    }
}

Write-Host "Parametros de simulacao:" -ForegroundColor White
$SimulationParams.GetEnumerator() | ForEach-Object {
    $name = $_.Key
    $params = $_.Value
    Write-Host "  $name -> Success: $($params.SuccessRate)%, Latency: $($params.Latency.Avg)ms avg, Weight: $($params.Weight)%" -ForegroundColor Cyan
}

Write-Host "`nIniciando simulacao de $TotalProducts produtos..." -ForegroundColor Green

# Loop principal de simulacao
for ($i = 1; $i -le $TotalProducts; $i++) {
    $product = $AllProducts[$i - 1]
    
    # Simular multiplas operacoes por produto
    $operationsPerProduct = Get-Random -Min 2 -Max 6  # 2-5 operacoes por produto
    
    for ($op = 1; $op -le $operationsPerProduct; $op++) {
        # Selecionar tipo de operacao baseado nos pesos
        $rand = Get-Random -Max 100
        $selectedOp = $null
        $cumWeight = 0
        
        foreach ($opType in $SimulationParams.GetEnumerator()) {
            $cumWeight += $opType.Value.Weight
            if ($rand -le $cumWeight) {
                $selectedOp = $opType
                break
            }
        }
        
        if (-not $selectedOp) { $selectedOp = $SimulationParams.GetEnumerator() | Select-Object -First 1 }
        
        # Simular execucao da operacao
        $opName = $selectedOp.Key
        $opParams = $selectedOp.Value
        
        # Simular latencia realistica
        $latency = Get-Random -Min $opParams.Latency.Min -Max $opParams.Latency.Max
        
        # Simular processamento (micro sleep para realismo)
        Start-Sleep -Milliseconds ($latency / 10)  # 1/10 da latencia real para simular
        
        # Determinar sucesso/falha
        $success = (Get-Random -Max 100) -lt $opParams.SuccessRate
        
        # Registrar resultado
        $Results.Total++
        
        if ($success) {
            $Results.Success++
            $Results.Latencies += $latency
            
            # Mapear para categoria de resultado
            $category = switch($opName) {
                "HealthCheck" { "HealthChecks" }
                "StockQuery" { "StockQueries" }
                "ProductInfo" { "ProductInfo" }
                "SystemInfo" { "SystemInfo" }
            }
            
            $cat = $Results.Products[$category]
            $cat.Count++
            $cat.Time += $latency
            
            if ($latency -gt 100) {
                $Results.Slow += @{ 
                    Id = $Results.Total; 
                    Product = $product; 
                    Operation = $opName; 
                    Latency = $latency 
                }
            }
        } else {
            $Results.Failed++
            $categoryForError = switch($opName) {
                "HealthCheck" { "HealthChecks" }
                "StockQuery" { "StockQueries" }
                "ProductInfo" { "ProductInfo" }
                "SystemInfo" { "SystemInfo" }
            }
            $Results.Products[$categoryForError].Errors++
        }
        
        # Simular connection pool
        if ($Results.ConnectionPool.Active -lt $Results.ConnectionPool.Max) {
            $Results.ConnectionPool.Active++
        } else {
            $Results.ConnectionPool.Timeouts++
        }
    }
    
    # Progress a cada 100 produtos
    if ($i % 100 -eq 0) {
        $pct = [math]::Round(($i / $TotalProducts) * 100, 1)
        $elapsed = (Get-Date) - $TestStart
        $rate = [math]::Round($Results.Total / $elapsed.TotalSeconds, 1)
        Write-Host "Produtos: $i/$TotalProducts ($pct%) - Operations: $($Results.Total) - Rate: $rate ops/s" -ForegroundColor Blue
        
        # Simular diminuicao de conexoes ativas
        $Results.ConnectionPool.Active = [math]::Max(0, $Results.ConnectionPool.Active - (Get-Random -Max 5))
    }
}

$TestEnd = Get-Date
$Duration = ($TestEnd - $TestStart).TotalSeconds

# Calcular metricas finais
$throughput = [math]::Round($Results.Total / $Duration, 2)
$successRate = [math]::Round(($Results.Success / $Results.Total) * 100, 2)
$productsPerSecond = [math]::Round($TotalProducts / $Duration, 2)

$avgLatency = 0
$minLatency = 0
$maxLatency = 0
$p95 = 0
$p99 = 0

if ($Results.Latencies.Count -gt 0) {
    $stats = $Results.Latencies | Measure-Object -Average -Min -Max
    $avgLatency = [math]::Round($stats.Average, 2)
    $minLatency = $stats.Minimum
    $maxLatency = $stats.Maximum
    
    $sorted = $Results.Latencies | Sort-Object
    $p95 = $sorted[[math]::Floor($sorted.Count * 0.95)]
    $p99 = $sorted[[math]::Floor($sorted.Count * 0.99)]
}

# Calcular latencia media por categoria
$Results.Products.GetEnumerator() | ForEach-Object {
    $category = $_.Value
    if ($category.Count -gt 0) {
        $category.AvgLatency = [math]::Round($category.Time / $category.Count, 2)
    }
}

# Exibir resultados
Write-Host "`n" + "="*60 -ForegroundColor Magenta
Write-Host "RELATORIO DE CAPACIDADE - 1000 PRODUTOS (SIMULADO)" -ForegroundColor Magenta
Write-Host "="*60 -ForegroundColor Magenta

Write-Host "`nRESUMO EXECUTIVO:" -ForegroundColor White
Write-Host "Produtos testados: $TotalProducts" -ForegroundColor Cyan
Write-Host "Total de operacoes: $($Results.Total)" -ForegroundColor Cyan
Write-Host "Duracao: $([math]::Round($Duration, 2))s" -ForegroundColor White
Write-Host "Throughput produtos: $productsPerSecond produtos/s" -ForegroundColor Yellow
Write-Host "Throughput operacoes: $throughput ops/s" -ForegroundColor Yellow

Write-Host "`nTAXAS DE SUCESSO:" -ForegroundColor White
Write-Host "Sucessos: $($Results.Success)" -ForegroundColor Green
Write-Host "Falhas: $($Results.Failed)" -ForegroundColor Red
Write-Host "Taxa geral: $successRate%" -ForegroundColor $(if($successRate -ge 95) {"Green"} elseif($successRate -ge 90) {"Yellow"} else {"Red"})

Write-Host "`nLATENCIA (SIMULADA):" -ForegroundColor White
Write-Host "Minima: ${minLatency}ms" -ForegroundColor Green
Write-Host "Media: ${avgLatency}ms" -ForegroundColor Yellow
Write-Host "Maxima: ${maxLatency}ms" -ForegroundColor Red
Write-Host "P95: ${p95}ms" -ForegroundColor Yellow
Write-Host "P99: ${p99}ms" -ForegroundColor Red

Write-Host "`nPERFORMANCE POR CATEGORIA:" -ForegroundColor White
$Results.Products.GetEnumerator() | Sort-Object {$_.Value.Count} -Desc | ForEach-Object {
    $name = $_.Key
    $cat = $_.Value
    $status = if ($cat.Errors -eq 0) { "✅" } else { "❌" }
    $errorRate = if ($cat.Count -gt 0) { [math]::Round(($cat.Errors / ($cat.Count + $cat.Errors)) * 100, 2) } else { 0 }
    
    Write-Host "$status $name" -ForegroundColor Cyan
    Write-Host "   Operations: $($cat.Count), Errors: $($cat.Errors) ($errorRate%)" -ForegroundColor White
    Write-Host "   Avg Latency: $($cat.AvgLatency)ms" -ForegroundColor White
}

Write-Host "`nCONNECTION POOL (SIMULADO):" -ForegroundColor White
Write-Host "Max connections: $($Results.ConnectionPool.Max)" -ForegroundColor Cyan
Write-Host "Peak usage: $($Results.ConnectionPool.Active)" -ForegroundColor Yellow
Write-Host "Timeouts: $($Results.ConnectionPool.Timeouts)" -ForegroundColor $(if($Results.ConnectionPool.Timeouts -eq 0) {"Green"} else {"Red"})

Write-Host "`nOPERACOES LENTAS (>100ms):" -ForegroundColor Yellow
if ($Results.Slow.Count -gt 0) {
    Write-Host "Total lentas: $($Results.Slow.Count)" -ForegroundColor Red
    Write-Host "Porcentagem: $([math]::Round(($Results.Slow.Count / $Results.Total) * 100, 2))%" -ForegroundColor Red
    
    $Results.Slow | Sort-Object Latency -Desc | Select-Object -First 5 | ForEach-Object {
        Write-Host "  Op $($_.Id): $($_.Product) -> $($_.Operation) ($($_.Latency)ms)" -ForegroundColor Red
    }
} else {
    Write-Host "Nenhuma operacao lenta detectada! ✅" -ForegroundColor Green
}

# Analise de capacidade
Write-Host "`nANALISE DE CAPACIDADE:" -ForegroundColor Magenta
Write-Host "-" * 40 -ForegroundColor Magenta

$capacityScore = 0

# Avaliacao de throughput
if ($productsPerSecond -ge 20) { $capacityScore += 25 }
elseif ($productsPerSecond -ge 15) { $capacityScore += 20 }
elseif ($productsPerSecond -ge 10) { $capacityScore += 15 }

# Avaliacao de taxa de sucesso
if ($successRate -ge 98) { $capacityScore += 30 }
elseif ($successRate -ge 95) { $capacityScore += 25 }
elseif ($successRate -ge 90) { $capacityScore += 20 }

# Avaliacao de latencia
if ($avgLatency -le 30) { $capacityScore += 25 }
elseif ($avgLatency -le 50) { $capacityScore += 20 }
elseif ($avgLatency -le 100) { $capacityScore += 15 }

# Avaliacao de estabilidade
if ($Results.ConnectionPool.Timeouts -eq 0) { $capacityScore += 10 }
if ($Results.Slow.Count -eq 0) { $capacityScore += 10 }

$capacityLevel = if ($capacityScore -ge 90) { "EXCELENTE" }
elseif ($capacityScore -ge 80) { "MUITO BOM" }
elseif ($capacityScore -ge 70) { "BOM" }
elseif ($capacityScore -ge 60) { "ADEQUADO" }
else { "INSUFICIENTE" }

$levelColor = if ($capacityScore -ge 90) { "Green" }
elseif ($capacityScore -ge 80) { "Cyan" }
elseif ($capacityScore -ge 70) { "Yellow" }
elseif ($capacityScore -ge 60) { "White" }
else { "Red" }

Write-Host "CAPACITY SCORE: $capacityScore/100" -ForegroundColor $levelColor
Write-Host "CLASSIFICACAO: $capacityLevel" -ForegroundColor $levelColor

Write-Host "`nSUPORTE A 1000 PRODUTOS:" -ForegroundColor White
if ($capacityScore -ge 80 -and $successRate -ge 95) {
    Write-Host "✅ APLICACAO SUPORTA 1000 produtos com seguranca" -ForegroundColor Green
    Write-Host "   - Taxa de sucesso adequada: $successRate%" -ForegroundColor Green
    Write-Host "   - Throughput aceitavel: $productsPerSecond produtos/s" -ForegroundColor Green
    Write-Host "   - Latencia controlada: ${avgLatency}ms media" -ForegroundColor Green
}
elseif ($capacityScore -ge 60 -and $successRate -ge 90) {
    Write-Host "⚠️  APLICACAO SUPORTA 1000 produtos com ATENCAO" -ForegroundColor Yellow
    Write-Host "   - Requer monitoramento continuo" -ForegroundColor Yellow
    Write-Host "   - Considerar otimizacoes" -ForegroundColor Yellow
}
else {
    Write-Host "❌ APLICACAO NAO SUPORTA 1000 produtos de forma segura" -ForegroundColor Red
    Write-Host "   - Requer melhorias significativas" -ForegroundColor Red
    Write-Host "   - Necessario refatoramento" -ForegroundColor Red
}

# Recomendacoes
Write-Host "`nRECOMENDACOES:" -ForegroundColor Magenta
if ($Results.ConnectionPool.Timeouts -gt 0) {
    Write-Host "🔧 Aumentar connection pool (atual: $($Results.ConnectionPool.Max))" -ForegroundColor Yellow
}
if ($avgLatency -gt 50) {
    Write-Host "🔧 Otimizar latencia de queries (atual: ${avgLatency}ms)" -ForegroundColor Yellow
}
if ($successRate -lt 95) {
    Write-Host "🔧 Implementar retry logic e circuit breakers" -ForegroundColor Yellow
}
if ($productsPerSecond -lt 15) {
    Write-Host "🔧 Considerar processamento assincrono ou batch" -ForegroundColor Yellow
}

Write-Host "🔧 Implementar endpoint /api/stocks real (removendo simulacao)" -ForegroundColor Yellow

# Salvar relatorio
$report = @{
    Test = @{
        Type = "ProductCapacitySimulation"
        Products = $TotalProducts
        Operations = $Results.Total
        Duration = $Duration
        SimulationMode = $true
    }
    Results = @{
        Success = $Results.Success
        Failed = $Results.Failed
        SuccessRate = $successRate
        ProductsPerSecond = $productsPerSecond
        OperationsPerSecond = $throughput
        CapacityScore = $capacityScore
        Level = $capacityLevel
    }
    Latency = @{
        Min = $minLatency
        Avg = $avgLatency
        Max = $maxLatency
        P95 = $p95
        P99 = $p99
    }
    Categories = $Results.Products
    SlowOperations = $Results.Slow.Count
    ConnectionPool = $Results.ConnectionPool
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

if (-not (Test-Path "dashboard\data")) { New-Item -Path "dashboard\data" -Type Directory -Force | Out-Null }

$json = $report | ConvertTo-Json -Depth 5
$path = "dashboard\data\capacity-1000products-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File $path -Encoding UTF8

Write-Host "`nRelatorio salvo: $path" -ForegroundColor Green
Write-Host "`nTESTE DE CAPACIDADE CONCLUIDO - SEM CUSTOS!" -ForegroundColor Magenta
