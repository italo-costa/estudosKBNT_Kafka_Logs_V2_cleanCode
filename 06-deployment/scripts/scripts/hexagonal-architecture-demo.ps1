# Virtual Stock Architecture Demo Script
# Demonstrates the hexagonal architecture with Virtual Stock Service and ACL Virtual Stock Service

param(
    [int]$StockItems = 10,
    [int]$ReservationCount = 5,
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "VIRTUAL STOCK ARCHITECTURE DEMONSTRATION" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Architecture Overview:" -ForegroundColor Yellow
Write-Host "• Virtual Stock Service (Microservice A) - Hexagonal Architecture" -ForegroundColor White
Write-Host "• ACL Virtual Stock Service (Microservice B) - Anti-Corruption Layer" -ForegroundColor White
Write-Host "• Red Hat AMQ Streams (Kafka) - Event Communication" -ForegroundColor White
Write-Host ""

# Check if services are running
Write-Host "Checking Services Status..." -ForegroundColor Yellow

$VirtualStockStatus = try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -TimeoutSec 3
    if ($response.StatusCode -eq 200) { "RUNNING" } else { "ERROR" }
} catch { "NOT RUNNING" }

$ACLStockStatus = try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/actuator/health" -TimeoutSec 3
    if ($response.StatusCode -eq 200) { "RUNNING" } else { "ERROR" }
} catch { "NOT RUNNING" }

Write-Host "Virtual Stock Service (Port 8080): $VirtualStockStatus" -ForegroundColor $(if($VirtualStockStatus -like "*RUNNING*") {"Green"} else {"Red"})
Write-Host "ACL Virtual Stock Service (Port 8081): $ACLStockStatus" -ForegroundColor $(if($ACLStockStatus -like "*RUNNING*") {"Green"} else {"Red"})
Write-Host ""

if ($VirtualStockStatus -like "*NOT RUNNING*" -or $ACLStockStatus -like "*NOT RUNNING*") {
    Write-Host "Services not running. Please start them first:" -ForegroundColor Yellow
    Write-Host "   .\scripts\start-complete-environment.ps1" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Demo Configuration
$VirtualStockBaseUrl = "http://localhost:8080/api/v1/virtual-stock"
$products = @(
    @{ productId = "AAPL"; symbol = "AAPL"; productName = "Apple Inc."; price = 150.00 },
    @{ productId = "MSFT"; symbol = "MSFT"; productName = "Microsoft Corp."; price = 280.00 },
    @{ productId = "GOOGL"; symbol = "GOOGL"; productName = "Alphabet Inc."; price = 2500.00 },
    @{ productId = "TSLA"; symbol = "TSLA"; productName = "Tesla Inc."; price = 800.00 },
    @{ productId = "AMZN"; symbol = "AMZN"; productName = "Amazon.com Inc."; price = 3200.00 }
)

$createdStocks = @()
$headers = @{ "Content-Type" = "application/json" }

Write-Host "PHASE 1: Creating Virtual Stock Items" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

for ($i = 0; $i -lt [Math]::Min($StockItems, $products.Count); $i++) {
    $product = $products[$i]
    $quantity = Get-Random -Minimum 50 -Maximum 200
    
    $createRequest = @{
        productId = $product.productId
        symbol = $product.symbol
        productName = $product.productName
        initialQuantity = $quantity
        unitPrice = $product.price
        createdBy = "demo-system"
    } | ConvertTo-Json

    Write-Host "Creating stock: $($product.symbol) - $($product.productName)" -ForegroundColor White
    
    try {
        $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks" -Method POST -Body $createRequest -Headers $headers
        
        if ($response.success) {
            $stock = $response.data
            $createdStocks += $stock
            
            Write-Host "   SUCCESS: Created ID=$($stock.stockId.Substring(0,8))... Qty=$($stock.quantity) Price=$($stock.unitPrice)" -ForegroundColor Green
            
            if ($Verbose) {
                Write-Host "      Status: $($stock.status) | Total Value: $($stock.totalValue)" -ForegroundColor Gray
            }
        } else {
            Write-Host "   FAILED: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "Created $($createdStocks.Count) stock items successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "PHASE 2: Stock Quantity Updates" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

$updatedStocks = @()
$updateCount = [Math]::Min(3, $createdStocks.Count)

for ($i = 0; $i -lt $updateCount; $i++) {
    $stock = $createdStocks[$i]
    $newQuantity = Get-Random -Minimum 10 -Maximum 300
    
    $updateRequest = @{
        newQuantity = $newQuantity
        updatedBy = "demo-admin"
        reason = "Stock level adjustment - Demo"
    } | ConvertTo-Json

    Write-Host "Updating quantity for $($stock.symbol): $($stock.quantity) -> $newQuantity" -ForegroundColor White
    
    try {
        $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks/$($stock.stockId)/quantity" -Method PUT -Body $updateRequest -Headers $headers
        
        if ($response.success) {
            $updatedStock = $response.data
            $updatedStocks += $updatedStock
            
            $change = $newQuantity - $stock.quantity
            $changeColor = if ($change -gt 0) { "Green" } else { "Yellow" }
            $changeSymbol = if ($change -gt 0) { "UP" } else { "DOWN" }
            
            Write-Host "   SUCCESS: $changeSymbol Change: $change | New Status: $($updatedStock.status)" -ForegroundColor $changeColor
        } else {
            Write-Host "   FAILED: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""

Write-Host "PHASE 3: Stock Reservations" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

$reservedStocks = @()
$reservationStocks = $createdStocks | Where-Object { $_.isAvailable -eq $true } | Select-Object -First $ReservationCount

foreach ($stock in $reservationStocks) {
    $maxReservation = [Math]::Min($stock.quantity, 20)
    $reserveQuantity = Get-Random -Minimum 1 -Maximum $maxReservation
    
    $reserveRequest = @{
        quantityToReserve = $reserveQuantity
        reservedBy = "demo-order-service"
        reason = "Order #$(Get-Random -Minimum 10000 -Maximum 99999)"
    } | ConvertTo-Json

    Write-Host "Reserving $reserveQuantity units from $($stock.symbol) (Available: $($stock.quantity))" -ForegroundColor White
    
    try {
        $response = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks/$($stock.stockId)/reserve" -Method POST -Body $reserveRequest -Headers $headers
        
        if ($response.success) {
            $reservation = $response.data
            $reservedStocks += $reservation
            
            Write-Host "   SUCCESS: Reserved $($reservation.reservedQuantity) units | Remaining: $($reservation.stock.quantity)" -ForegroundColor Green
            
            if ($reservation.stock.isLowStock) {
                Write-Host "   WARNING: LOW STOCK: $($reservation.stock.symbol)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   FAILED: $($response.message)" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""

Write-Host "PHASE 4: System Status Overview" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

try {
    $allStocksResponse = Invoke-RestMethod -Uri "$VirtualStockBaseUrl/stocks" -Method GET
    
    if ($allStocksResponse.success) {
        $allStocks = $allStocksResponse.data
        
        # Calculate statistics
        $totalStocks = $allStocks.Count
        $availableStocks = ($allStocks | Where-Object { $_.isAvailable -eq $true }).Count
        $lowStocks = ($allStocks | Where-Object { $_.isLowStock -eq $true }).Count
        $outOfStock = ($allStocks | Where-Object { $_.status -eq "OUT_OF_STOCK" }).Count
        $totalValue = ($allStocks | Measure-Object -Property totalValue -Sum).Sum
        
        Write-Host "SYSTEM STATISTICS:" -ForegroundColor Yellow
        Write-Host "   Total Stocks: $totalStocks" -ForegroundColor White
        Write-Host "   Available Stocks: $availableStocks" -ForegroundColor Green
        Write-Host "   Low Stock Items: $lowStocks" -ForegroundColor Yellow
        Write-Host "   Out of Stock: $outOfStock" -ForegroundColor Red
        Write-Host "   Total Portfolio Value: $([math]::Round($totalValue, 2))" -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "TOP STOCK VALUES:" -ForegroundColor Yellow
        $topStocks = $allStocks | Sort-Object totalValue -Descending | Select-Object -First 3
        
        foreach ($stock in $topStocks) {
            Write-Host "   $($stock.symbol): $([math]::Round($stock.totalValue, 2)) ($($stock.quantity) x $($stock.unitPrice))" -ForegroundColor White
        }
    }
} catch {
    Write-Host "   ERROR retrieving system status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

Write-Host "DEMO SUMMARY" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

Write-Host "Architecture Components Demonstrated:" -ForegroundColor Green
Write-Host "   • Virtual Stock Service (Hexagonal Architecture)" -ForegroundColor White
Write-Host "   • Domain-Driven Design patterns" -ForegroundColor White
Write-Host "   • Event publishing to Kafka topics" -ForegroundColor White
Write-Host "   • ACL Virtual Stock Service consumption" -ForegroundColor White
Write-Host "   • Anti-Corruption Layer pattern" -ForegroundColor White
Write-Host ""

Write-Host "Operations Performed:" -ForegroundColor Green
Write-Host "   • Created: $($createdStocks.Count) stock items" -ForegroundColor White
Write-Host "   • Updated: $($updatedStocks.Count) quantity changes" -ForegroundColor White  
Write-Host "   • Reserved: $($reservedStocks.Count) stock reservations" -ForegroundColor White
Write-Host ""

Write-Host "To view real-time logs:" -ForegroundColor Yellow
Write-Host "   • Virtual Stock Service: logs/virtual-stock-service.log" -ForegroundColor White
Write-Host "   • ACL Service: logs/kbnt-stock-consumer-service.log" -ForegroundColor White
Write-Host ""

Write-Host "Services Running:" -ForegroundColor Yellow
Write-Host "   • Virtual Stock API: http://localhost:8080/api/v1/virtual-stock" -ForegroundColor White
Write-Host "   • Health Check: http://localhost:8080/actuator/health" -ForegroundColor White
Write-Host "   • ACL Service: http://localhost:8081/actuator/health" -ForegroundColor White
Write-Host ""

Write-Host "ARCHITECTURE DEMONSTRATION COMPLETED!" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host ""
