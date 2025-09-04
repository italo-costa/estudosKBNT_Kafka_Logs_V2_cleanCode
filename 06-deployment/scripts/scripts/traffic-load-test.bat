@echo off
setlocal EnableDelayedExpansion

REM ################################################################################
REM # KBNT Traffic Load Test with Elasticsearch Integration - Windows PowerShell
REM # Generates realistic message traffic between Producer → Kafka → Consumer
REM ################################################################################

REM Configuration
set "PRODUCER_URL=http://localhost:8080"
set "CONSUMER_URL=http://localhost:8081"
set "KIBANA_URL=http://localhost:5601"
set "ELASTICSEARCH_URL=http://localhost:9200"

REM Test parameters
if "%TOTAL_MESSAGES%"=="" set TOTAL_MESSAGES=500
if "%CONCURRENT_THREADS%"=="" set CONCURRENT_THREADS=10
if "%BATCH_SIZE%"=="" set BATCH_SIZE=50
if "%DELAY_BETWEEN_BATCHES%"=="" set DELAY_BETWEEN_BATCHES=2

REM Product catalog for realistic simulation
set "PRODUCTS[0]=SMARTPHONE-XYZ123:599.99"
set "PRODUCTS[1]=TABLET-ABC456:399.99"
set "PRODUCTS[2]=NOTEBOOK-DEF789:1299.99"
set "PRODUCTS[3]=HEADPHONE-GHI012:149.99"
set "PRODUCTS[4]=SMARTWATCH-JKL345:299.99"
set "PRODUCTS[5]=SPEAKER-MNO678:89.99"
set "PRODUCTS[6]=CAMERA-PQR901:799.99"
set "PRODUCTS[7]=DRONE-STU234:699.99"
set "PRODUCTS[8]=MONITOR-VWX567:249.99"
set "PRODUCTS[9]=KEYBOARD-YZA890:79.99"

set "OPERATIONS[0]=INCREASE"
set "OPERATIONS[1]=DECREASE"
set "OPERATIONS[2]=SET"
set "OPERATIONS[3]=SYNC"

set "PRIORITIES[0]=LOW"
set "PRIORITIES[1]=NORMAL"
set "PRIORITIES[2]=HIGH"
set "PRIORITIES[3]=CRITICAL"

set "EXCHANGES[0]=NYSE"
set "EXCHANGES[1]=NASDAQ"
set "EXCHANGES[2]=LSE"
set "EXCHANGES[3]=TSE"

REM ################################################################################
REM # Utility Functions
REM ################################################################################

:log
    set "level=%~1"
    set "message=%~2"
    set "timestamp=%date% %time%"
    
    if "%level%"=="INFO" (
        echo [INFO] %timestamp% - %message%
    ) else if "%level%"=="SUCCESS" (
        echo [SUCCESS] %timestamp% - %message%
    ) else if "%level%"=="WARNING" (
        echo [WARNING] %timestamp% - %message%
    ) else if "%level%"=="ERROR" (
        echo [ERROR] %timestamp% - %message%
    ) else if "%level%"=="HEADER" (
        echo.
        echo ========================================
        echo %message%
        echo ========================================
    )
goto :eof

:generate_correlation_id
    set /a rand_num=%RANDOM% %% 9999
    for /f %%i in ('powershell -Command "Get-Date -UFormat %%s"') do set timestamp=%%i
    set "correlation_id=LOAD-TEST-%timestamp%-%rand_num%"
goto :eof

:get_random_product
    set /a idx=%RANDOM% %% 10
    call set "random_product=%%PRODUCTS[%idx%]%%"
goto :eof

:get_random_operation
    set /a idx=%RANDOM% %% 4
    call set "random_operation=%%OPERATIONS[%idx%]%%"
goto :eof

:get_random_priority
    set /a idx=%RANDOM% %% 4
    call set "random_priority=%%PRIORITIES[%idx%]%%"
goto :eof

:get_random_exchange
    set /a idx=%RANDOM% %% 4
    call set "random_exchange=%%EXCHANGES[%idx%]%%"
goto :eof

:generate_realistic_quantity
    set "operation=%~1"
    if "%operation%"=="INCREASE" (
        set /a quantity=%RANDOM% %% 1000 + 100
    ) else if "%operation%"=="DECREASE" (
        set /a quantity=%RANDOM% %% 500 + 50
    ) else if "%operation%"=="SET" (
        set /a quantity=%RANDOM% %% 5000 + 1000
    ) else if "%operation%"=="SYNC" (
        set /a quantity=%RANDOM% %% 2000 + 500
    ) else (
        set /a quantity=%RANDOM% %% 1000 + 100
    )
goto :eof

REM ################################################################################
REM # Service Health Checks
REM ################################################################################

:check_services
    call :log "HEADER" "CHECKING SERVICE AVAILABILITY"
    set "all_healthy=true"
    
    REM Check Producer Service
    curl -f "%PRODUCER_URL%/actuator/health" >nul 2>&1
    if !errorlevel! equ 0 (
        call :log "SUCCESS" "✓ Producer Service is healthy"
    ) else (
        call :log "ERROR" "✗ Producer Service is not accessible"
        set "all_healthy=false"
    )
    
    REM Check Consumer Service
    curl -f "%CONSUMER_URL%/api/consumer/actuator/health" >nul 2>&1
    if !errorlevel! equ 0 (
        call :log "SUCCESS" "✓ Consumer Service is healthy"
    ) else (
        call :log "ERROR" "✗ Consumer Service is not accessible"
        set "all_healthy=false"
    )
    
    REM Check Elasticsearch
    curl -f "%ELASTICSEARCH_URL%/_cluster/health" >nul 2>&1
    if !errorlevel! equ 0 (
        call :log "SUCCESS" "✓ Elasticsearch is healthy"
    ) else (
        call :log "WARNING" "⚠ Elasticsearch is not accessible (will use PostgreSQL fallback)"
    )
    
    REM Check Kibana
    curl -f "%KIBANA_URL%/api/status" >nul 2>&1
    if !errorlevel! equ 0 (
        call :log "SUCCESS" "✓ Kibana is healthy"
    ) else (
        call :log "WARNING" "⚠ Kibana is not accessible (dashboards won't be available)"
    )
    
    if "%all_healthy%"=="false" (
        call :log "ERROR" "Some critical services are unavailable"
        exit /b 1
    )
goto :eof

REM ################################################################################
REM # Message Generation and Sending
REM ################################################################################

:send_stock_update_message
    set "correlation_id=%~1"
    set "product_info=%~2"
    set "operation=%~3"
    set "priority=%~4"
    set "quantity=%~5"
    set "exchange=%~6"
    
    REM Parse product info
    for /f "tokens=1,2 delims=:" %%a in ("%product_info%") do (
        set "product_id=%%a"
        set "price=%%b"
    )
    
    REM Get current timestamp
    for /f %%i in ('powershell -Command "Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ'"') do set "timestamp=%%i"
    for /f %%i in ('powershell -Command "Get-Date -UFormat %%s"') do set "batch_timestamp=%%i"
    
    REM Create temporary JSON file
    set "json_file=%TEMP%\kbnt_payload_%correlation_id%.json"
    (
        echo {
        echo   "correlationId": "%correlation_id%",
        echo   "productId": "%product_id%",
        echo   "quantity": %quantity%,
        echo   "price": %price%,
        echo   "operation": "%operation%",
        echo   "priority": "%priority%",
        echo   "exchange": "%exchange%",
        echo   "timestamp": "%timestamp%",
        echo   "metadata": {
        echo     "test_run": true,
        echo     "load_test_batch": "%batch_timestamp%",
        echo     "source": "traffic-load-test"
        echo   }
        echo }
    ) > "%json_file%"
    
    REM Send message to producer
    curl -s -w "%%{http_code}" -X POST ^
         -H "Content-Type: application/json" ^
         -H "X-Correlation-ID: %correlation_id%" ^
         -H "X-Source: load-test" ^
         -d "@%json_file%" ^
         "%PRODUCER_URL%/api/stock/update" > "%TEMP%\curl_response_%correlation_id%.txt" 2>&1
    
    REM Read response
    set /p response=<"%TEMP%\curl_response_%correlation_id%.txt"
    set "http_code=!response:~-3!"
    
    REM Cleanup temp files
    del "%json_file%" 2>nul
    del "%TEMP%\curl_response_%correlation_id%.txt" 2>nul
    
    if "%http_code%"=="200" (
        echo SUCCESS:%correlation_id%:%product_id%:%operation%:%priority%
        exit /b 0
    ) else if "%http_code%"=="201" (
        echo SUCCESS:%correlation_id%:%product_id%:%operation%:%priority%
        exit /b 0
    ) else (
        echo FAILED:%correlation_id%:%product_id%:%operation%:%priority%:HTTP_%http_code%
        exit /b 1
    )
goto :eof

:send_message_batch
    set "batch_id=%~1"
    set "batch_size=%~2"
    
    call :log "INFO" "Sending batch %batch_id% with %batch_size% messages..."
    
    set "success_count=0"
    set "fail_count=0"
    
    for /L %%i in (1,1,%batch_size%) do (
        call :generate_correlation_id
        call :get_random_product
        call :get_random_operation
        call :get_random_priority
        call :generate_realistic_quantity "!random_operation!"
        call :get_random_exchange
        
        call :send_stock_update_message "!correlation_id!" "!random_product!" "!random_operation!" "!random_priority!" "!quantity!" "!random_exchange!"
        
        if !errorlevel! equ 0 (
            set /a success_count+=1
        ) else (
            set /a fail_count+=1
        )
        
        REM Small delay to avoid overwhelming the system
        timeout /t 1 /nobreak >nul 2>&1
    )
    
    call :log "SUCCESS" "Batch %batch_id% completed: !success_count! successes, !fail_count! failures"
goto :eof

REM ################################################################################
REM # Load Test Execution
REM ################################################################################

:run_load_test
    call :log "HEADER" "STARTING LOAD TEST"
    call :log "INFO" "Test Parameters:"
    call :log "INFO" "  Total Messages: %TOTAL_MESSAGES%"
    call :log "INFO" "  Concurrent Threads: %CONCURRENT_THREADS%"
    call :log "INFO" "  Batch Size: %BATCH_SIZE%"
    call :log "INFO" "  Delay Between Batches: %DELAY_BETWEEN_BATCHES%s"
    
    REM Calculate total batches
    set /a total_batches=(%TOTAL_MESSAGES% + %BATCH_SIZE% - 1) / %BATCH_SIZE%
    
    call :log "INFO" "Starting %total_batches% batches..."
    
    REM Get start time
    for /f %%i in ('powershell -Command "Get-Date -UFormat %%s"') do set "start_time=%%i"
    
    REM Run batches
    for /L %%b in (1,1,%total_batches%) do (
        set /a remaining_messages=%TOTAL_MESSAGES% - ((%%b - 1) * %BATCH_SIZE%)
        
        if !remaining_messages! leq 0 goto :load_test_complete
        
        if !remaining_messages! lss %BATCH_SIZE% (
            set "current_batch_size=!remaining_messages!"
        ) else (
            set "current_batch_size=%BATCH_SIZE%"
        )
        
        REM Send batch
        call :send_message_batch %%b !current_batch_size!
        
        call :log "INFO" "Completed %%b/%total_batches% batches"
        
        REM Delay between batches
        if %%b lss %total_batches% timeout /t %DELAY_BETWEEN_BATCHES% /nobreak >nul 2>&1
    )
    
    :load_test_complete
    REM Get end time and calculate duration
    for /f %%i in ('powershell -Command "Get-Date -UFormat %%s"') do set "end_time=%%i"
    set /a duration=%end_time% - %start_time%
    set /a throughput=%TOTAL_MESSAGES% / %duration%
    
    call :log "SUCCESS" "Load test completed in %duration%s"
    call :log "INFO" "Average throughput: %throughput% messages/second"
goto :eof

REM ################################################################################
REM # Kibana Dashboard Setup
REM ################################################################################

:setup_kibana_dashboard
    call :log "HEADER" "SETTING UP KIBANA DASHBOARD"
    
    curl -f "%KIBANA_URL%/api/status" >nul 2>&1
    if !errorlevel! neq 0 (
        call :log "ERROR" "Kibana is not accessible. Cannot create dashboard."
        goto :eof
    )
    
    REM Wait for data to be indexed
    call :log "INFO" "Waiting for data to be indexed in Elasticsearch..."
    timeout /t 30 /nobreak >nul 2>&1
    
    REM Create data view
    call :log "INFO" "Creating Kibana data view..."
    set "data_view_json=%TEMP%\data_view.json"
    (
        echo {
        echo   "data_view": {
        echo     "title": "kbnt-consumption-logs-*",
        echo     "name": "KBNT Traffic Monitoring",
        echo     "timeFieldName": "@timestamp"
        echo   }
        echo }
    ) > "%data_view_json%"
    
    curl -X POST "%KIBANA_URL%/api/data_views/data_view" ^
         -H "Content-Type: application/json" ^
         -H "kbn-xsrf: true" ^
         -d "@%data_view_json%" >nul 2>&1
    
    del "%data_view_json%" 2>nul
    
    call :log "SUCCESS" "✓ Kibana data view created/verified"
    
    call :log "INFO" "Dashboard URL: %KIBANA_URL%/app/dashboards"
    call :log "INFO" "Data View: kbnt-consumption-logs-*"
    
    call :log "INFO" "Suggested Kibana visualizations to create:"
    call :log "INFO" "  1. Line Chart: Messages processed over time (@timestamp, count)"
    call :log "INFO" "  2. Pie Chart: Status distribution (status.keyword)"
    call :log "INFO" "  3. Histogram: Processing time distribution (processing_time_ms)"
    call :log "INFO" "  4. Data Table: Recent messages (correlation_id, product_id, status, processing_time_ms)"
    call :log "INFO" "  5. Metric: Total messages processed"
    call :log "INFO" "  6. Area Chart: Message volume by priority"
goto :eof

REM ################################################################################
REM # Results Analysis
REM ################################################################################

:analyze_test_results
    call :log "HEADER" "ANALYZING TEST RESULTS"
    
    REM Wait for processing to complete
    call :log "INFO" "Waiting for message processing to complete..."
    timeout /t 60 /nobreak >nul 2>&1
    
    REM Get final statistics
    curl -s "%CONSUMER_URL%/api/consumer/monitoring/statistics?hours=1" > "%TEMP%\final_stats.json" 2>nul
    
    if exist "%TEMP%\final_stats.json" (
        for /f "tokens=*" %%i in ('powershell -Command "(Get-Content '%TEMP%\final_stats.json' | ConvertFrom-Json).total_messages"') do set "total=%%i"
        for /f "tokens=*" %%i in ('powershell -Command "(Get-Content '%TEMP%\final_stats.json' | ConvertFrom-Json).successful_messages"') do set "successful=%%i"
        for /f "tokens=*" %%i in ('powershell -Command "(Get-Content '%TEMP%\final_stats.json' | ConvertFrom-Json).failed_messages"') do set "failed=%%i"
        for /f "tokens=*" %%i in ('powershell -Command "(Get-Content '%TEMP%\final_stats.json' | ConvertFrom-Json).average_processing_time_ms"') do set "avg_time=%%i"
        
        if "!total!" neq "0" (
            for /f "tokens=*" %%i in ('powershell -Command "[math]::Round((!successful! * 100 / !total!), 2)"') do set "success_rate=%%i"
        ) else (
            set "success_rate=0"
        )
        
        call :log "SUCCESS" "📊 FINAL RESULTS:"
        call :log "SUCCESS" "  Total Messages Processed: !total!"
        call :log "SUCCESS" "  Successful: !successful!"
        call :log "SUCCESS" "  Failed: !failed!"
        call :log "SUCCESS" "  Success Rate: !success_rate!%%"
        call :log "SUCCESS" "  Average Processing Time: !avg_time!ms"
        
        del "%TEMP%\final_stats.json" 2>nul
    ) else (
        call :log "ERROR" "Could not retrieve final statistics"
    )
    
    REM Check Elasticsearch document count
    curl -f "%ELASTICSEARCH_URL%/_cluster/health" >nul 2>&1
    if !errorlevel! equ 0 (
        curl -s "%ELASTICSEARCH_URL%/kbnt-consumption-logs-*/_count" > "%TEMP%\es_count.json" 2>nul
        if exist "%TEMP%\es_count.json" (
            for /f "tokens=*" %%i in ('powershell -Command "(Get-Content '%TEMP%\es_count.json' | ConvertFrom-Json).count"') do set "es_doc_count=%%i"
            call :log "SUCCESS" "  Documents in Elasticsearch: !es_doc_count!"
            del "%TEMP%\es_count.json" 2>nul
        )
    )
goto :eof

REM ################################################################################
REM # Main Execution
REM ################################################################################

:main
    call :log "HEADER" "KBNT TRAFFIC LOAD TEST WITH KIBANA DASHBOARD"
    call :log "INFO" "Starting comprehensive traffic test..."
    
    REM Step 1: Check service health
    call :check_services
    if !errorlevel! neq 0 (
        call :log "ERROR" "Service health check failed. Please ensure all services are running."
        exit /b 1
    )
    
    REM Step 2: Set up Kibana dashboard
    call :setup_kibana_dashboard
    
    REM Step 3: Run the load test
    call :run_load_test
    
    REM Step 4: Analyze results
    call :analyze_test_results
    
    REM Step 5: Final instructions
    call :log "HEADER" "TEST COMPLETED - KIBANA DASHBOARD ACCESS"
    call :log "SUCCESS" "🎉 Traffic load test completed successfully!"
    call :log "INFO" ""
    call :log "INFO" "📊 Access your Kibana dashboard:"
    call :log "INFO" "  URL: %KIBANA_URL%/app/dashboards"
    call :log "INFO" "  Data View: kbnt-consumption-logs-*"
    call :log "INFO" "  Time Range: Last 1 hour"
    call :log "INFO" ""
    call :log "INFO" "🔍 Useful Kibana searches:"
    call :log "INFO" "  All test messages: metadata.test_run:true"
    call :log "INFO" "  Failed messages: status:FAILED"
    call :log "INFO" "  High priority: priority:HIGH"
    call :log "INFO" "  Specific product: product_id:SMARTPHONE*"
    call :log "INFO" ""
    call :log "INFO" "📈 Recommended visualizations:"
    call :log "INFO" "  1. Messages over time (Line chart)"
    call :log "INFO" "  2. Status distribution (Pie chart)"
    call :log "INFO" "  3. Processing time histogram"
    call :log "INFO" "  4. Error analysis table"
    call :log "INFO" ""
    call :log "SUCCESS" "Open %KIBANA_URL% to view real-time traffic data!"
goto :eof

REM ################################################################################
REM # Script Execution
REM ################################################################################

if "%~1"=="monitor" (
    call :check_services
    goto :eof
) else if "%~1"=="dashboard" (
    call :setup_kibana_dashboard
    goto :eof
) else if "%~1"=="analyze" (
    call :analyze_test_results
    goto :eof
) else if "%~1"=="help" (
    echo Usage: %0 [run^|monitor^|dashboard^|analyze]
    echo.
    echo Commands:
    echo   run       - Run complete traffic load test (default)
    echo   monitor   - Only monitor existing traffic
    echo   dashboard - Only setup Kibana dashboard
    echo   analyze   - Only analyze existing results
    goto :eof
) else (
    call :main
)

endlocal
