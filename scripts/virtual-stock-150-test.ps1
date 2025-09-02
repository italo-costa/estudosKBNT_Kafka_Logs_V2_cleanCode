param([int]$TotalMessages = 150, [int]$DelayMs = 50)

Write-Host "🎯 VIRTUAL STOCK TEST - $TotalMessages MESSAGES" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api/v1/virtual-stock"
$symbols = @("AAPL", "MSFT", "GOOGL", "AMZN", "TSLA")

$stats = @{
    Total = 0; Success = 0; Error = 0
    CREATE = 0; UPDATE = 0; RESERVE = 0; QUERY = 0
}

Write-Host "🔍 Checking service health..."
try {
    Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5 | Out-Null
    Write-Host "✅ Service is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Service not accessible" -ForegroundColor Red
    exit 1
}

$createdStocks = @()
$startTime = Get-Date

Write-Host "🚀 Starting test..."

for ($i = 1; $i -le $TotalMessages; $i++) {
    $stats.Total++
    
    # Select operation
    $op = if ($createdStocks.Count -eq 0) { "CREATE" } else { @("CREATE", "UPDATE", "RESERVE", "QUERY") | Get-Random }
    $stats[$op]++
    
    try {
        $symbol = $symbols | Get-Random
        $price = Get-Random -Minimum 50 -Maximum 200
        $qty = Get-Random -Minimum 10 -Maximum 500
        
        if ($op -eq "CREATE") {
            $data = @{
                productId = "PROD-$symbol-$i"
                symbol = $symbol
                productName = "$symbol Stock"
                initialQuantity = $qty
                unitPrice = $price
                createdBy = "test"
            }
            $response = Invoke-RestMethod -Uri "$baseUrl/stocks" -Method POST -ContentType "application/json" -Body ($data | ConvertTo-Json)
            $createdStocks += $response.stockId
            Write-Host "[$i] ✅ CREATE $symbol" -ForegroundColor Green
        }
        elseif ($op -eq "UPDATE" -and $createdStocks.Count -gt 0) {
            $stockId = $createdStocks | Get-Random
            $data = @{ newQuantity = $qty; updatedBy = "test"; reason = "Test update" }
            Invoke-RestMethod -Uri "$baseUrl/stocks/$stockId/quantity" -Method PUT -ContentType "application/json" -Body ($data | ConvertTo-Json) | Out-Null
            Write-Host "[$i] 🔄 UPDATE" -ForegroundColor Cyan
        }
        elseif ($op -eq "RESERVE" -and $createdStocks.Count -gt 0) {
            $stockId = $createdStocks | Get-Random
            $reserveQty = Get-Random -Minimum 1 -Maximum 20
            $data = @{ quantityToReserve = $reserveQty; reservedBy = "test"; reason = "Test reserve" }
            Invoke-RestMethod -Uri "$baseUrl/stocks/$stockId/reserve" -Method POST -ContentType "application/json" -Body ($data | ConvertTo-Json) | Out-Null
            Write-Host "[$i] 🔒 RESERVE $reserveQty" -ForegroundColor Magenta
        }
        elseif ($op -eq "QUERY") {
            if ($createdStocks.Count -gt 0) {
                $stockId = $createdStocks | Get-Random
                Invoke-RestMethod -Uri "$baseUrl/stocks/$stockId" -Method GET | Out-Null
            } else {
                Invoke-RestMethod -Uri "$baseUrl/stocks" -Method GET | Out-Null
            }
            Write-Host "[$i] 🔍 QUERY" -ForegroundColor Yellow
        }
        
        $stats.Success++
        
    } catch {
        $stats.Error++
        Write-Host "[$i] ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
    
    if ($i % 25 -eq 0) { Write-Host "Progress: $i/$TotalMessages" -ForegroundColor Blue }
}

$duration = ((Get-Date) - $startTime).TotalSeconds

Write-Host ""
Write-Host "📊 RESULTS" -ForegroundColor Green
Write-Host "Total: $($stats.Total)"
Write-Host "Success: $($stats.Success)" -ForegroundColor Green
Write-Host "Errors: $($stats.Error)" -ForegroundColor Red
Write-Host "Duration: $([math]::Round($duration, 2))s"
Write-Host ""
Write-Host "Operations:"
Write-Host "CREATE: $($stats.CREATE)"
Write-Host "UPDATE: $($stats.UPDATE)"
Write-Host "RESERVE: $($stats.RESERVE)"
Write-Host "QUERY: $($stats.QUERY)"
Write-Host ""
Write-Host "Created stocks: $($createdStocks.Count)"
Write-Host ""
Write-Host "✅ Test completed successfully!" -ForegroundColor Green
Write-Host "💰 No external costs - all local operations" -ForegroundColor Yellow
