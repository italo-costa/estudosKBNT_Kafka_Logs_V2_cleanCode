# Virtual Stock Random Test - 150 Messages
param(
    [int]$TotalMessages = 150,
    [int]$DelayMs = 100,
    [switch]$Verbose,
    [switch]$ShowDetails
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "🎯 VIRTUAL STOCK RANDOM TEST - $TotalMessages MESSAGES" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Configuration
$VirtualStockBaseUrl = "http://localhost:8080/api/v1/virtual-stock"
$stockSymbols = @("AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "META", "NVDA", "NFLX")
$operations = @("CREATE", "UPDATE", "RESERVE", "QUERY")

# Statistics
$stats = @{
    TotalRequests = 0
    SuccessCount = 0
    ErrorCount = 0
    Operations = @{ CREATE = 0; UPDATE = 0; RESERVE = 0; QUERY = 0 }
    StartTime = Get-Date
}

Write-Host "📊 Test Configuration:"
Write-Host "• Total Messages: $TotalMessages"
Write-Host "• Delay per request: ${DelayMs}ms"
Write-Host "• Target Service: Virtual Stock Service (localhost:8080)"

# Check service health
Write-Host ""
Write-Host "🔍 Checking Virtual Stock Service..."
try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5
    if ($healthCheck.status -eq "UP") {
        Write-Host "✅ Virtual Stock Service is running" -ForegroundColor Green
    } else {
        Write-Host "❌ Virtual Stock Service is not healthy" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Virtual Stock Service is not accessible" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🚀 Starting Random Virtual Stock Test..."

# Track created stocks
$createdStocks = @{}

for ($i = 1; $i -le $TotalMessages; $i++) {
    $stats.TotalRequests++
    
    # Select random operation
    $random = Get-Random -Minimum 1 -Maximum 101
    $operation = if ($random -le 30) { "CREATE" } 
                elseif ($random -le 55) { "UPDATE" }
                elseif ($random -le 80) { "RESERVE" }
                else { "QUERY" }
    
    # Force CREATE if no stocks exist
    if ($createdStocks.Count -eq 0 -and $operation -ne "CREATE") {
        $operation = "CREATE"
    }
    
    $stats.Operations[$operation]++
    
    try {
        $symbol = $stockSymbols | Get-Random
        $price = [math]::Round((Get-Random -Minimum 50 -Maximum 300) + (Get-Random -Minimum 1 -Maximum 99) / 100, 2)
        $quantity = Get-Random -Minimum 10 -Maximum 1000
        
        $success = $false
        $response = $null
        
        if ($operation -eq "CREATE") {
            $stockData = @{
                productId = "PROD-$symbol-$(Get-Random -Minimum 1000 -Maximum 9999)"
                symbol = $symbol
                productName = "$symbol Corp"
                initialQuantity = $quantity
                unitPrice = $price
                createdBy = "random-test"
            }
            
            $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks" -Method POST -ContentType "application/json" -Body ($stockData | ConvertTo-Json)
            $createdStocks[$response.stockId] = @{ Symbol = $symbol; Quantity = $quantity; Price = $price }
            $success = $true
            
            if ($ShowDetails) {
                Write-Host "[$i/$TotalMessages] ✅ CREATE: $symbol - Qty: $quantity @ `$$price" -ForegroundColor Green
            }
        }
        elseif ($operation -eq "UPDATE" -and $createdStocks.Count -gt 0) {
            $stockId = $createdStocks.Keys | Get-Random
            $newQuantity = Get-Random -Minimum 5 -Maximum 500
            
            $updateData = @{
                newQuantity = $newQuantity
                updatedBy = "random-test"
                reason = "Random update test"
            }
            
            $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks/$stockId/quantity" -Method PUT -ContentType "application/json" -Body ($updateData | ConvertTo-Json)
            $createdStocks[$stockId].Quantity = $newQuantity
            $success = $true
            
            if ($ShowDetails) {
                Write-Host "[$i/$TotalMessages] 🔄 UPDATE: $($createdStocks[$stockId].Symbol) - New Qty: $newQuantity" -ForegroundColor Cyan
            }
        }
        elseif ($operation -eq "RESERVE" -and $createdStocks.Count -gt 0) {
            $stockId = $createdStocks.Keys | Get-Random
            $stock = $createdStocks[$stockId]
            $reserveQty = Get-Random -Minimum 1 -Maximum 50
            
            $reserveData = @{
                quantityToReserve = $reserveQty
                reservedBy = "random-test"
                reason = "Random reservation test"
            }
            
            $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks/$stockId/reserve" -Method POST -ContentType "application/json" -Body ($reserveData | ConvertTo-Json)
            $success = $true
            
            if ($ShowDetails) {
                Write-Host "[$i/$TotalMessages] 🔒 RESERVE: $($stock.Symbol) - Reserved: $reserveQty" -ForegroundColor Magenta
            }
        }
        elseif ($operation -eq "QUERY") {
            if ($createdStocks.Count -gt 0) {
                $stockId = $createdStocks.Keys | Get-Random
                $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks/$stockId" -Method GET
            } else {
                $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks" -Method GET
            }
            $success = $true
            
            if ($ShowDetails) {
                Write-Host "[$i/$TotalMessages] 🔍 QUERY: Successful" -ForegroundColor Yellow
            }
        }
        
        if ($success) {
            $stats.SuccessCount++
        }
        
        # Progress indicator
        if ($i % 10 -eq 0 -and -not $ShowDetails) {
            $progress = [math]::Round(($i / $TotalMessages) * 100, 1)
            Write-Host "Progress: $i/$TotalMessages ($progress%) - Success: $($stats.SuccessCount) | Errors: $($stats.ErrorCount)" -ForegroundColor Blue
        }
        
    } catch {
        $stats.ErrorCount++
        if ($Verbose) {
            Write-Host "[$i/$TotalMessages] ❌ ERROR in $operation : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    if ($DelayMs -gt 0) {
        Start-Sleep -Milliseconds $DelayMs
    }
}

$stats.EndTime = Get-Date
$duration = ($stats.EndTime - $stats.StartTime).TotalSeconds

Write-Host ""
Write-Host "📊 TEST RESULTS SUMMARY" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "Total Messages: $($stats.TotalRequests)"
Write-Host "Successful Operations: $($stats.SuccessCount)" -ForegroundColor Green
Write-Host "Failed Operations: $($stats.ErrorCount)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($stats.SuccessCount / $stats.TotalRequests) * 100, 2))%"
Write-Host "Total Duration: $([math]::Round($duration, 2)) seconds"
Write-Host "Average Rate: $([math]::Round($stats.TotalRequests / $duration, 2)) requests/second"

Write-Host ""
Write-Host "Operation Breakdown:" -ForegroundColor Cyan
foreach ($op in $stats.Operations.Keys) {
    $count = $stats.Operations[$op]
    $percentage = [math]::Round(($count / $stats.TotalRequests) * 100, 1)
    Write-Host "• $op : $count ($percentage%)"
}

Write-Host ""
Write-Host "Created Stocks: $($createdStocks.Count)" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Random Virtual Stock Test completed successfully!" -ForegroundColor Green
Write-Host "💰 No external costs incurred - all operations performed locally" -ForegroundColor Yellow
