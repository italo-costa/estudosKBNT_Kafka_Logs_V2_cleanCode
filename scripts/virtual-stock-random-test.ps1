# Virtual Stock Random Test - 150 Messages
# Generates 150 random virtual stock operations without external costs

param(
    [int]$TotalMessages = 150,
    [int]$DelayMs = 100,
    [switch]$Verbose,
    [switch]$ShowDetails
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "🎯 " -ForegroundColor Blue -NoNewline
Write-Host "VIRTUAL STOCK RANDOM TEST - $TotalMessages MESSAGES" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Virtual Stock Service Configuration
$VirtualStockBaseUrl = "http://localhost:8080/api/v1/virtual-stock"

# Random stock symbols and data
$stockSymbols = @("AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "META", "NVDA", "NFLX", "BABA", "ORCL", "CRM", "ADBE")
$operations = @("CREATE", "UPDATE", "RESERVE", "QUERY")
$randomNames = @("Apple Inc.", "Microsoft Corp", "Alphabet Inc", "Amazon.com Inc", "Tesla Inc", "Meta Platforms", 
                 "NVIDIA Corp", "Netflix Inc", "Alibaba Group", "Oracle Corp", "Salesforce Inc", "Adobe Inc")

# Test Statistics
$stats = @{
    TotalRequests = 0
    SuccessCount = 0
    ErrorCount = 0
    Operations = @{
        CREATE = 0
        UPDATE = 0  
        RESERVE = 0
        QUERY = 0
    }
    StartTime = Get-Date
}

Write-Host "📊 Test Configuration:" -ForegroundColor Yellow
Write-Host "• Total Messages: $TotalMessages" -ForegroundColor White
Write-Host "• Delay per request: ${DelayMs}ms" -ForegroundColor White
Write-Host "• Target Service: Virtual Stock Service (localhost:8080)" -ForegroundColor White
Write-Host "• Available Symbols: $($stockSymbols -join ', ')" -ForegroundColor White
Write-Host ""

# Check if Virtual Stock Service is running
Write-Host "🔍 Checking Virtual Stock Service..." -ForegroundColor Yellow
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
    Write-Host "Please start the environment first: .\scripts\start-complete-environment.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🚀 Starting Random Virtual Stock Test..." -ForegroundColor Green
Write-Host ""

# Created stocks tracking
$createdStocks = @{}

for ($i = 1; $i -le $TotalMessages; $i++) {
    $stats.TotalRequests++
    
    # Random operation selection with weighted distribution
    $operationWeights = @{
        "CREATE" = 30   # 30% chance
        "UPDATE" = 25   # 25% chance  
        "RESERVE" = 25  # 25% chance
        "QUERY" = 20    # 20% chance
    }
    
    $random = Get-Random -Minimum 1 -Maximum 101
    $operation = if ($random -le 30) { "CREATE" } 
                elseif ($random -le 55) { "UPDATE" }
                elseif ($random -le 80) { "RESERVE" }
                else { "QUERY" }
    
    # If no stocks created yet, force CREATE operation
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
        
        switch ($operation) {
            "CREATE" {
                $stockData = @{
                    productId = "PROD-$symbol-$(Get-Random -Minimum 1000 -Maximum 9999)"
                    symbol = $symbol
                    productName = $randomNames | Get-Random
                    initialQuantity = $quantity
                    unitPrice = $price
                    createdBy = "random-test"
                }
                
                $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks" -Method POST -ContentType "application/json" -Body ($stockData | ConvertTo-Json)
                $createdStocks[$response.stockId] = @{ Symbol = $symbol; Quantity = $quantity; Price = $price }
                $success = $true
                
                if ($ShowDetails) {
                    Write-Host "[$i/$TotalMessages] ✅ CREATE: $symbol - Qty: $quantity @ $$price (ID: $($response.stockId))" -ForegroundColor Green
                }
            }
            
            "UPDATE" {
                if ($createdStocks.Count -gt 0) {
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
                } else {
                    # Fallback to CREATE if no stocks available
                    $operation = "CREATE"
                    $i-- # Retry this iteration
                    continue
                }
            }
            
            "RESERVE" {
                if ($createdStocks.Count -gt 0) {
                    $stockId = $createdStocks.Keys | Get-Random
                    $stock = $createdStocks[$stockId]
                    $reserveQty = Get-Random -Minimum 1 -Maximum ([math]::Min(50, [math]::Floor($stock.Quantity / 2)))
                    
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
                } else {
                    # Fallback to CREATE if no stocks available
                    $operation = "CREATE"
                    $i-- # Retry this iteration
                    continue
                }
            }
            
            "QUERY" {
                if ($createdStocks.Count -gt 0) {
                    $stockId = $createdStocks.Keys | Get-Random
                    $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks/$stockId" -Method GET
                    $success = $true
                    
                    if ($ShowDetails) {
                        Write-Host "[$i/$TotalMessages] 🔍 QUERY: $($response.symbol) - Qty: $($response.availableQuantity)" -ForegroundColor Yellow
                    }
                } else {
                    # Query all stocks if none created yet
                    $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks" -Method GET
                    $success = $true
                    
                    if ($ShowDetails) {
                        Write-Host "[$i/$TotalMessages] 🔍 QUERY ALL: Found $($response.Count) stocks" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        if ($success) {
            $stats.SuccessCount++
        }
        
        # Progress indicator (every 10 requests)
        if ($i % 10 -eq 0 -and -not $ShowDetails) {
            $progress = [math]::Round(($i / $TotalMessages) * 100, 1)
            Write-Host "Progress: $i/$TotalMessages ($progress%) - Success: $($stats.SuccessCount) | Errors: $($stats.ErrorCount)" -ForegroundColor Blue
        }
        
    } catch {
        $stats.ErrorCount++
        if ($Verbose) {
            Write-Host "[$i/$TotalMessages] ❌ ERROR in $operation`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Small delay to avoid overwhelming the service
    if ($DelayMs -gt 0) {
        Start-Sleep -Milliseconds $DelayMs
    }
}

$stats.EndTime = Get-Date
$duration = ($stats.EndTime - $stats.StartTime).TotalSeconds

Write-Host ""
Write-Host "📊 TEST RESULTS SUMMARY" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "Total Messages: $($stats.TotalRequests)" -ForegroundColor White
Write-Host "Successful Operations: $($stats.SuccessCount)" -ForegroundColor Green
Write-Host "Failed Operations: $($stats.ErrorCount)" -ForegroundColor Red
Write-Host "Success Rate: $([math]::Round(($stats.SuccessCount / $stats.TotalRequests) * 100, 2))%" -ForegroundColor Yellow
Write-Host "Total Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor White
Write-Host "Average Rate: $([math]::Round($stats.TotalRequests / $duration, 2)) requests/second" -ForegroundColor Yellow
Write-Host ""

Write-Host "Operation Breakdown:" -ForegroundColor Cyan
foreach ($op in $stats.Operations.Keys) {
    $count = $stats.Operations[$op]
    $percentage = [math]::Round(($count / $stats.TotalRequests) * 100, 1)
    Write-Host "• $op`: $count ($percentage%)" -ForegroundColor White
}

Write-Host ""
Write-Host "Created Stocks: $($createdStocks.Count)" -ForegroundColor Yellow
Write-Host ""

if ($Verbose -and $createdStocks.Count -gt 0) {
    Write-Host "📋 Created Stocks Details:" -ForegroundColor Cyan
    $createdStocks.GetEnumerator() | ForEach-Object {
        Write-Host "• ID: $($_.Key) | Symbol: $($_.Value.Symbol) | Qty: $($_.Value.Quantity) | Price: $$($_.Value.Price)" -ForegroundColor White
    }
    Write-Host ""
}

Write-Host "✅ Random Virtual Stock Test completed successfully!" -ForegroundColor Green
Write-Host "💰 No external costs incurred - all operations performed locally" -ForegroundColor Yellow
