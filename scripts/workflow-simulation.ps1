# =============================================================================
# KBNT Virtual Stock Architecture - Local Java Applications Simulation
# =============================================================================

param(
    [string]$Operation = "start",
    [switch]$WithLogs = $true,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

# Configuration
$ProjectRoot = "c:\workspace\estudosKBNT_Kafka_Logs"
$LogsDir = Join-Path $ProjectRoot "logs"

# Ensure logs directory exists
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

# Colors for output
$Colors = @{
    Header = "Cyan"
    Success = "Green" 
    Warning = "Yellow"
    Error = "Red"
    Info = "Blue"
    Progress = "Magenta"
}

function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "MAIN"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Component] [$Level] $Message"
    
    $color = switch ($Level) {
        "SUCCESS" { $Colors.Success }
        "WARNING" { $Colors.Warning }
        "ERROR" { $Colors.Error }
        "PROGRESS" { $Colors.Progress }
        default { $Colors.Info }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    if ($WithLogs) {
        $logEntry | Out-File -FilePath (Join-Path $LogsDir "simulation.log") -Append -Encoding UTF8
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host ""
}

function Simulate-KafkaMessage {
    param(
        [string]$Topic,
        [string]$Message,
        [string]$ProducerService = "VIRTUAL-STOCK-SERVICE"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $kafkaLog = "[$timestamp] [KAFKA-BROKER] [INFO] Received message on topic '$Topic' from producer '$ProducerService'"
    $messageLog = "[$timestamp] [KAFKA-BROKER] [INFO] Message content: $Message"
    $consumerLog = "[$timestamp] [ACL-VIRTUAL-STOCK-SERVICE] [INFO] Consuming message from topic '$Topic'"
    $processLog = "[$timestamp] [ACL-VIRTUAL-STOCK-SERVICE] [INFO] Processing stock update event"
    
    Write-Host $kafkaLog -ForegroundColor $Colors.Progress
    Write-Host $messageLog -ForegroundColor $Colors.Info
    Write-Host $consumerLog -ForegroundColor $Colors.Success
    Write-Host $processLog -ForegroundColor $Colors.Success
    
    if ($WithLogs) {
        $kafkaLog | Out-File -FilePath (Join-Path $LogsDir "kafka-simulation.log") -Append -Encoding UTF8
        $messageLog | Out-File -FilePath (Join-Path $LogsDir "kafka-simulation.log") -Append -Encoding UTF8
        $consumerLog | Out-File -FilePath (Join-Path $LogsDir "acl-consumer-simulation.log") -Append -Encoding UTF8
        $processLog | Out-File -FilePath (Join-Path $LogsDir "acl-consumer-simulation.log") -Append -Encoding UTF8
    }
}

function Simulate-DatabaseOperation {
    param(
        [string]$Operation,
        [string]$Entity,
        [string]$Data
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $dbLog = "[$timestamp] [POSTGRESQL] [INFO] Executing $Operation on $Entity"
    $dataLog = "[$timestamp] [POSTGRESQL] [INFO] Data: $Data"
    $commitLog = "[$timestamp] [POSTGRESQL] [INFO] Transaction committed successfully"
    
    Write-Host $dbLog -ForegroundColor $Colors.Info
    Write-Host $dataLog -ForegroundColor $Colors.Info
    Write-Host $commitLog -ForegroundColor $Colors.Success
    
    if ($WithLogs) {
        $dbLog | Out-File -FilePath (Join-Path $LogsDir "database-simulation.log") -Append -Encoding UTF8
        $dataLog | Out-File -FilePath (Join-Path $LogsDir "database-simulation.log") -Append -Encoding UTF8
        $commitLog | Out-File -FilePath (Join-Path $LogsDir "database-simulation.log") -Append -Encoding UTF8
    }
}

function Simulate-StockCreationWorkflow {
    Write-Header "SIMULATING STOCK CREATION WORKFLOW"
    
    $stockData = @{
        stockId = "STK-" + (Get-Random -Minimum 10000 -Maximum 99999)
        productId = "AAPL-001"
        symbol = "AAPL"
        productName = "Apple Inc. Stock"
        initialQuantity = 150
        unitPrice = 175.50
        createdBy = "simulation-system"
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    # Step 1: Virtual Stock Service receives request
    Write-LogMessage "Incoming stock creation request" "INFO" "VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Request payload: $($stockData | ConvertTo-Json -Compress)" "INFO" "VIRTUAL-STOCK-SERVICE"
    
    # Step 2: Virtual Stock Service validates and creates domain event
    Write-LogMessage "Validating stock data..." "PROGRESS" "VIRTUAL-STOCK-SERVICE"
    Start-Sleep -Seconds 1
    Write-LogMessage "Creating Stock aggregate with ID: $($stockData.stockId)" "SUCCESS" "VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Generating StockCreatedEvent domain event" "INFO" "VIRTUAL-STOCK-SERVICE"
    
    # Step 3: Virtual Stock Service publishes to Kafka
    $eventMessage = @{
        eventType = "StockCreated"
        eventId = "EVT-" + (Get-Random -Minimum 10000 -Maximum 99999)
        stockId = $stockData.stockId
        productId = $stockData.productId
        symbol = $stockData.symbol
        quantity = $stockData.initialQuantity
        unitPrice = $stockData.unitPrice
        timestamp = $stockData.timestamp
        metadata = @{
            source = "VIRTUAL-STOCK-SERVICE"
            version = "1.0"
            correlationId = "COR-" + (Get-Random -Minimum 10000 -Maximum 99999)
        }
    } | ConvertTo-Json -Compress
    
    Write-LogMessage "Publishing StockCreatedEvent to Kafka topic 'stock-events'" "INFO" "VIRTUAL-STOCK-SERVICE"
    Simulate-KafkaMessage -Topic "stock-events" -Message $eventMessage -ProducerService "VIRTUAL-STOCK-SERVICE"
    
    # Step 4: ACL Virtual Stock Service processes event
    Start-Sleep -Seconds 1
    Write-LogMessage "Received StockCreatedEvent from Kafka" "INFO" "ACL-VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Applying Anti-Corruption Layer patterns" "PROGRESS" "ACL-VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Transforming external event to internal model" "INFO" "ACL-VIRTUAL-STOCK-SERVICE"
    
    # Step 5: ACL saves to database
    $dbRecord = @{
        id = $stockData.stockId
        symbol = $stockData.symbol
        name = $stockData.productName
        current_quantity = $stockData.initialQuantity
        unit_price = $stockData.unitPrice
        created_at = $stockData.timestamp
        updated_at = $stockData.timestamp
        status = "ACTIVE"
    } | ConvertTo-Json -Compress
    
    Simulate-DatabaseOperation -Operation "INSERT" -Entity "stock_records" -Data $dbRecord
    
    # Step 6: Success response
    Write-LogMessage "Stock creation workflow completed successfully" "SUCCESS" "VIRTUAL-STOCK-SERVICE"
    
    return $stockData.stockId
}

function Simulate-StockUpdateWorkflow {
    param([string]$StockId)
    
    Write-Header "SIMULATING STOCK UPDATE WORKFLOW"
    
    $updateData = @{
        stockId = $StockId
        previousQuantity = 150
        newQuantity = 200
        updatedBy = "simulation-system"
        reason = "Inventory adjustment - simulation test"
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    # Step 1: Virtual Stock Service receives update request
    Write-LogMessage "Incoming stock quantity update request for Stock ID: $StockId" "INFO" "VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Update payload: $($updateData | ConvertTo-Json -Compress)" "INFO" "VIRTUAL-STOCK-SERVICE"
    
    # Step 2: Virtual Stock Service loads aggregate and updates
    Write-LogMessage "Loading Stock aggregate from repository..." "PROGRESS" "VIRTUAL-STOCK-SERVICE"
    Start-Sleep -Seconds 1
    Write-LogMessage "Stock aggregate loaded successfully" "SUCCESS" "VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Updating quantity from $($updateData.previousQuantity) to $($updateData.newQuantity)" "INFO" "VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Generating StockUpdatedEvent domain event" "INFO" "VIRTUAL-STOCK-SERVICE"
    
    # Step 3: Virtual Stock Service publishes update event
    $updateEventMessage = @{
        eventType = "StockUpdated"
        eventId = "EVT-" + (Get-Random -Minimum 10000 -Maximum 99999)
        stockId = $updateData.stockId
        previousQuantity = $updateData.previousQuantity
        newQuantity = $updateData.newQuantity
        changeAmount = $updateData.newQuantity - $updateData.previousQuantity
        updatedBy = $updateData.updatedBy
        reason = $updateData.reason
        timestamp = $updateData.timestamp
        metadata = @{
            source = "VIRTUAL-STOCK-SERVICE"
            version = "1.0"
            correlationId = "COR-" + (Get-Random -Minimum 10000 -Maximum 99999)
        }
    } | ConvertTo-Json -Compress
    
    Write-LogMessage "Publishing StockUpdatedEvent to Kafka topic 'stock-events'" "INFO" "VIRTUAL-STOCK-SERVICE"
    Simulate-KafkaMessage -Topic "stock-events" -Message $updateEventMessage -ProducerService "VIRTUAL-STOCK-SERVICE"
    
    # Step 4: ACL Virtual Stock Service processes update event
    Start-Sleep -Seconds 1
    Write-LogMessage "Received StockUpdatedEvent from Kafka" "INFO" "ACL-VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Applying Anti-Corruption Layer for update event" "PROGRESS" "ACL-VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "Calculating inventory impact: +$($updateData.newQuantity - $updateData.previousQuantity) units" "INFO" "ACL-VIRTUAL-STOCK-SERVICE"
    
    # Step 5: ACL updates database
    $updateDbRecord = @{
        stock_id = $updateData.stockId
        previous_quantity = $updateData.previousQuantity
        new_quantity = $updateData.newQuantity
        change_reason = $updateData.reason
        updated_by = $updateData.updatedBy
        updated_at = $updateData.timestamp
    } | ConvertTo-Json -Compress
    
    Simulate-DatabaseOperation -Operation "UPDATE" -Entity "stock_records" -Data $updateDbRecord
    
    # Step 6: Success response
    Write-LogMessage "Stock update workflow completed successfully" "SUCCESS" "VIRTUAL-STOCK-SERVICE"
    Write-LogMessage "New stock quantity: $($updateData.newQuantity)" "INFO" "VIRTUAL-STOCK-SERVICE"
}

function Show-WorkflowSummary {
    Write-Header "WORKFLOW SIMULATION SUMMARY"
    
    Write-LogMessage "Components involved in the stock update workflow:" "INFO" "SUMMARY"
    Write-Host "   1. VIRTUAL-STOCK-SERVICE (Microservice A)" -ForegroundColor $Colors.Success
    Write-Host "      - Hexagonal Architecture with Domain-Driven Design" -ForegroundColor $Colors.Info
    Write-Host "      - Stock aggregate management" -ForegroundColor $Colors.Info
    Write-Host "      - Domain event publishing" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "   2. KAFKA-BROKER (Message Broker)" -ForegroundColor $Colors.Progress  
    Write-Host "      - Red Hat AMQ Streams compatible" -ForegroundColor $Colors.Info
    Write-Host "      - Topic: stock-events" -ForegroundColor $Colors.Info
    Write-Host "      - Event streaming and persistence" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "   3. ACL-VIRTUAL-STOCK-SERVICE (Microservice B)" -ForegroundColor $Colors.Success
    Write-Host "      - Anti-Corruption Layer pattern" -ForegroundColor $Colors.Info
    Write-Host "      - Event consumption and transformation" -ForegroundColor $Colors.Info
    Write-Host "      - External system integration" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "   4. POSTGRESQL (Database)" -ForegroundColor $Colors.Info
    Write-Host "      - Persistent data storage" -ForegroundColor $Colors.Info
    Write-Host "      - ACID transaction support" -ForegroundColor $Colors.Info
    Write-Host "      - Stock records management" -ForegroundColor $Colors.Info
    Write-Host ""
    
    Write-LogMessage "Message flow demonstrated:" "INFO" "SUMMARY"
    Write-Host "   Stock Request -> Virtual Stock Service -> Kafka -> ACL Service -> Database" -ForegroundColor $Colors.Header
    Write-Host ""
    
    Write-LogMessage "Log files generated:" "INFO" "SUMMARY"
    $logFiles = Get-ChildItem -Path $LogsDir -Filter "*.log" | Sort-Object Name
    foreach ($logFile in $logFiles) {
        $size = [math]::Round($logFile.Length / 1KB, 2)
        Write-Host "   $($logFile.Name) (${size} KB)" -ForegroundColor $Colors.Info
    }
}

function Show-LogsInRealTime {
    Write-Header "MONITORING LOGS IN REAL-TIME"
    
    Write-LogMessage "Available log monitoring commands:" "INFO" "MONITORING"
    Write-Host "   Get-Content '$LogsDir\simulation.log' -Tail 20 -Wait" -ForegroundColor $Colors.Info
    Write-Host "   Get-Content '$LogsDir\kafka-simulation.log' -Tail 20 -Wait" -ForegroundColor $Colors.Info
    Write-Host "   Get-Content '$LogsDir\acl-consumer-simulation.log' -Tail 20 -Wait" -ForegroundColor $Colors.Info
    Write-Host "   Get-Content '$LogsDir\database-simulation.log' -Tail 20 -Wait" -ForegroundColor $Colors.Info
    Write-Host ""
    
    Write-LogMessage "Recent log entries:" "INFO" "MONITORING"
    
    $logFiles = @(
        @{ Name = "Main Simulation"; Path = Join-Path $LogsDir "simulation.log" },
        @{ Name = "Kafka Messages"; Path = Join-Path $LogsDir "kafka-simulation.log" },
        @{ Name = "ACL Consumer"; Path = Join-Path $LogsDir "acl-consumer-simulation.log" },
        @{ Name = "Database Operations"; Path = Join-Path $LogsDir "database-simulation.log" }
    )
    
    foreach ($logFile in $logFiles) {
        if (Test-Path $logFile.Path) {
            Write-Host ""
            Write-Host "--- $($logFile.Name) (Last 5 lines) ---" -ForegroundColor $Colors.Header
            Get-Content $logFile.Path -Tail 5 | ForEach-Object {
                Write-Host $_ -ForegroundColor $Colors.Info
            }
        }
    }
}

# Main execution
switch ($Operation.ToLower()) {
    "start" {
        Write-Header "KBNT VIRTUAL STOCK ARCHITECTURE - WORKFLOW SIMULATION"
        
        Write-LogMessage "Starting complete stock update workflow simulation..." "INFO" "MAIN"
        Write-LogMessage "Note: This simulation demonstrates the message flow without requiring Docker/Kafka" "INFO" "MAIN"
        Write-Host ""
        
        # Simulate stock creation
        $stockId = Simulate-StockCreationWorkflow
        
        Write-Host ""
        Start-Sleep -Seconds 2
        
        # Simulate stock update
        Simulate-StockUpdateWorkflow -StockId $stockId
        
        Write-Host ""
        Show-WorkflowSummary
        Show-LogsInRealTime
    }
    
    "create" {
        Write-Header "STOCK CREATION SIMULATION"
        Simulate-StockCreationWorkflow
        Show-LogsInRealTime
    }
    
    "update" {
        Write-Header "STOCK UPDATE SIMULATION" 
        $stockId = "STK-" + (Get-Random -Minimum 10000 -Maximum 99999)
        Simulate-StockUpdateWorkflow -StockId $stockId
        Show-LogsInRealTime
    }
    
    "logs" {
        Show-LogsInRealTime
    }
    
    default {
        Write-Host "Usage: .\workflow-simulation.ps1 [-Operation <start|create|update|logs>] [-WithLogs] [-Verbose]" -ForegroundColor $Colors.Warning
        Write-Host ""
        Write-Host "Operations:" -ForegroundColor $Colors.Header
        Write-Host "   start  - Complete workflow simulation (create + update)" -ForegroundColor $Colors.Info
        Write-Host "   create - Stock creation workflow only" -ForegroundColor $Colors.Info
        Write-Host "   update - Stock update workflow only" -ForegroundColor $Colors.Info
        Write-Host "   logs   - Show recent logs and monitoring commands" -ForegroundColor $Colors.Info
    }
}
