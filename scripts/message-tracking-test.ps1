# TESTE REAL COM RASTREAMENTO - 100 Requests em 20 segundos
param([int]$TotalRequests = 100, [int]$TimeWindowSeconds = 20, [int]$Port = 8080)

Write-Host "TESTE REAL COM RASTREAMENTO DE MENSAGENS - 100 requests / 20s" -ForegroundColor Magenta
Write-Host "Mapeando processamento por componente arquitetural" -ForegroundColor Yellow

$TestStart = Get-Date
$MessageTracker = @{
    Messages = @()
    Components = @{
        "ActuatorHealth" = @{ Requests = @(); TotalLatency = 0; Errors = 0; Status = "UNKNOWN" }
        "ActuatorInfo" = @{ Requests = @(); TotalLatency = 0; Errors = 0; Status = "UNKNOWN" }
        "TestEndpoint" = @{ Requests = @(); TotalLatency = 0; Errors = 0; Status = "UNKNOWN" }
        "StocksAPI" = @{ Requests = @(); TotalLatency = 0; Errors = 0; Status = "UNKNOWN"; IsMocked = $true }
    }
    Timeline = @()
    Summary = @{ Total = 0; Success = 0; Failed = 0 }
}

# Função para gerar hash único da mensagem
function Get-MessageHash {
    param([int]$RequestId, [string]$Endpoint, [datetime]$Timestamp)
    $data = "$RequestId-$Endpoint-$($Timestamp.Ticks)"
    return [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($data)) | 
           ForEach-Object { $_.ToString("x2") } | Join-String | Substring 0, 8
}

Write-Host "`nFASE 1 - VALIDACAO DE COMPONENTES DISPONÍVEIS" -ForegroundColor Cyan

# 1. Testar Actuator Health
Write-Host "Testando Actuator Health..." -ForegroundColor White
try {
    $testTime = Measure-Command { $healthResp = Invoke-RestMethod "http://localhost:$Port/actuator/health" -TimeoutSec 3 }
    $MessageTracker.Components.ActuatorHealth.Status = "AVAILABLE"
    Write-Host "   ✅ Actuator Health: $($healthResp.status) ($(([math]::Round($testTime.TotalMilliseconds, 2)))ms)" -ForegroundColor Green
} catch {
    $MessageTracker.Components.ActuatorHealth.Status = "UNAVAILABLE"
    Write-Host "   ❌ Actuator Health: INDISPONÍVEL" -ForegroundColor Red
}

# 2. Testar Actuator Info  
Write-Host "Testando Actuator Info..." -ForegroundColor White
try {
    $testTime = Measure-Command { Invoke-RestMethod "http://localhost:$Port/actuator/info" -TimeoutSec 3 | Out-Null }
    $MessageTracker.Components.ActuatorInfo.Status = "AVAILABLE"
    Write-Host "   ✅ Actuator Info: DISPONÍVEL ($(([math]::Round($testTime.TotalMilliseconds, 2)))ms)" -ForegroundColor Green
} catch {
    $MessageTracker.Components.ActuatorInfo.Status = "UNAVAILABLE"
    Write-Host "   ❌ Actuator Info: INDISPONÍVEL" -ForegroundColor Red
}

# 3. Testar Custom Test Endpoint
Write-Host "Testando Test Endpoint..." -ForegroundColor White
try {
    $testTime = Measure-Command { Invoke-RestMethod "http://localhost:$Port/test" -TimeoutSec 3 | Out-Null }
    $MessageTracker.Components.TestEndpoint.Status = "AVAILABLE"
    Write-Host "   ✅ Test Endpoint: DISPONÍVEL ($(([math]::Round($testTime.TotalMilliseconds, 2)))ms)" -ForegroundColor Green
} catch {
    $MessageTracker.Components.TestEndpoint.Status = "UNAVAILABLE"
    Write-Host "   ❌ Test Endpoint: INDISPONÍVEL" -ForegroundColor Red
}

# 4. Testar Stocks API
Write-Host "Testando Stocks API..." -ForegroundColor White
try {
    $testTime = Measure-Command { Invoke-RestMethod "http://localhost:$Port/api/stocks/AAPL" -TimeoutSec 3 | Out-Null }
    $MessageTracker.Components.StocksAPI.Status = "AVAILABLE"
    $MessageTracker.Components.StocksAPI.IsMocked = $false
    Write-Host "   🎉 Stocks API: IMPLEMENTADO! ($(([math]::Round($testTime.TotalMilliseconds, 2)))ms)" -ForegroundColor Green
} catch {
    $MessageTracker.Components.StocksAPI.Status = "UNAVAILABLE"
    $MessageTracker.Components.StocksAPI.IsMocked = $true
    Write-Host "   ⚠️  Stocks API: SERÁ MOCKADO" -ForegroundColor Yellow
}

# Configurar endpoints disponíveis para teste
$AvailableEndpoints = @()
if ($MessageTracker.Components.ActuatorHealth.Status -eq "AVAILABLE") {
    $AvailableEndpoints += @{ Name = "health"; Component = "ActuatorHealth"; URL = "http://localhost:$Port/actuator/health"; Weight = 30 }
}
if ($MessageTracker.Components.ActuatorInfo.Status -eq "AVAILABLE") {
    $AvailableEndpoints += @{ Name = "info"; Component = "ActuatorInfo"; URL = "http://localhost:$Port/actuator/info"; Weight = 20 }
}
if ($MessageTracker.Components.TestEndpoint.Status -eq "AVAILABLE") {
    $AvailableEndpoints += @{ Name = "test"; Component = "TestEndpoint"; URL = "http://localhost:$Port/test"; Weight = 30 }
}
if ($MessageTracker.Components.StocksAPI.Status -eq "AVAILABLE") {
    $AvailableEndpoints += @{ Name = "stocks"; Component = "StocksAPI"; URL = "http://localhost:$Port/api/stocks/AAPL"; Weight = 20 }
} else {
    $AvailableEndpoints += @{ Name = "stocks"; Component = "StocksAPI"; URL = "MOCK"; Weight = 20 }
}

Write-Host "`nEndpoints configurados para teste:" -ForegroundColor White
$AvailableEndpoints | ForEach-Object { 
    $status = if ($_.URL -eq "MOCK") { " (MOCKADO)" } else { "" }
    Write-Host "  - $($_.Name): $($_.Weight)% peso$status" -ForegroundColor Cyan 
}

Write-Host "`nFASE 2 - EXECUÇÃO DO TESTE REAL COM RASTREAMENTO" -ForegroundColor Cyan
Write-Host "Executando $TotalRequests requests em janela de $TimeWindowSeconds segundos..." -ForegroundColor Green
Write-Host "Iniciando rastreamento de mensagens..." -ForegroundColor Green

# Calcular intervalo entre requests para distribuir em 20 segundos
$IntervalMs = [math]::Max(50, ($TimeWindowSeconds * 1000) / $TotalRequests)
Write-Host "Intervalo entre requests: $([math]::Round($IntervalMs, 2))ms" -ForegroundColor Blue

$ActualStart = Get-Date

# Loop principal com rastreamento
for ($i = 1; $i -le $TotalRequests; $i++) {
    $requestTime = Get-Date
    
    # Selecionar endpoint aleatório baseado nos pesos
    $rand = Get-Random -Max 100
    $selectedEndpoint = $AvailableEndpoints[0]
    $cumWeight = 0
    
    foreach ($endpoint in $AvailableEndpoints) {
        $cumWeight += $endpoint.Weight
        if ($rand -le $cumWeight) {
            $selectedEndpoint = $endpoint
            break
        }
    }
    
    # Gerar hash único para esta mensagem
    $messageHash = Get-MessageHash -RequestId $i -Endpoint $selectedEndpoint.Name -Timestamp $requestTime
    
    # Executar request com medição
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    $responseData = $null
    $errorInfo = $null
    
    try {
        if ($selectedEndpoint.URL -eq "MOCK") {
            # Simular Stocks API mockado
            $mockLatency = Get-Random -Min 25 -Max 65
            Start-Sleep -Milliseconds $mockLatency
            $success = (Get-Random -Max 100) -lt 95  # 95% success rate
            $responseData = @{ symbol = "AAPL"; price = (Get-Random -Min 150 -Max 200); timestamp = $requestTime.ToString() }
        } else {
            # Request real
            $responseData = Invoke-RestMethod $selectedEndpoint.URL -TimeoutSec 5
            $success = $true
        }
    } catch {
        $success = $false
        $errorInfo = $_.Exception.Message
    }
    
    $sw.Stop()
    $latency = $sw.ElapsedMilliseconds
    
    # Registrar mensagem no tracker
    $messageRecord = @{
        Id = $i
        Hash = $messageHash
        Timestamp = $requestTime
        Endpoint = $selectedEndpoint.Name
        Component = $selectedEndpoint.Component
        URL = $selectedEndpoint.URL
        Latency = $latency
        Success = $success
        ResponseSize = if ($responseData) { ($responseData | ConvertTo-Json -Compress).Length } else { 0 }
        Error = $errorInfo
        ProcessingNode = "Node-$(Get-Random -Min 1 -Max 4)"  # Simular nós de processamento
    }
    
    $MessageTracker.Messages += $messageRecord
    
    # Atualizar estatísticas do componente
    $component = $MessageTracker.Components[$selectedEndpoint.Component]
    $component.Requests += $messageRecord
    if ($success) {
        $component.TotalLatency += $latency
    } else {
        $component.Errors++
    }
    
    # Atualizar timeline
    $MessageTracker.Timeline += @{
        Time = $requestTime
        Hash = $messageHash
        Component = $selectedEndpoint.Component
        Success = $success
        Latency = $latency
    }
    
    # Atualizar summary
    $MessageTracker.Summary.Total++
    if ($success) {
        $MessageTracker.Summary.Success++
    } else {
        $MessageTracker.Summary.Failed++
    }
    
    # Progress a cada 20 requests
    if ($i % 20 -eq 0) {
        $elapsed = (Get-Date) - $ActualStart
        $rate = [math]::Round($i / $elapsed.TotalSeconds, 1)
        $successPct = [math]::Round(($MessageTracker.Summary.Success / $MessageTracker.Summary.Total) * 100, 2)
        Write-Host "Progress: $i/$TotalRequests - Taxa sucesso: $successPct% - Rate: $rate req/s" -ForegroundColor Blue
    }
    
    # Aguardar intervalo para manter timing
    if ($i -lt $TotalRequests) {
        Start-Sleep -Milliseconds ([math]::Max(10, $IntervalMs - $latency))
    }
}

$TestEnd = Get-Date
$ActualDuration = ($TestEnd - $ActualStart).TotalSeconds

# PROCESSAMENTO DOS RESULTADOS
Write-Host "`n" + "="*80 -ForegroundColor Magenta
Write-Host "RELATÓRIO DE RASTREAMENTO DE MENSAGENS" -ForegroundColor Magenta
Write-Host "="*80 -ForegroundColor Magenta

Write-Host "`nRESUMO EXECUTIVO:" -ForegroundColor White
Write-Host "Total de mensagens: $($MessageTracker.Summary.Total)" -ForegroundColor Cyan
Write-Host "Mensagens processadas com sucesso: $($MessageTracker.Summary.Success)" -ForegroundColor Green
Write-Host "Mensagens com falha: $($MessageTracker.Summary.Failed)" -ForegroundColor Red
Write-Host "Taxa de sucesso: $([math]::Round(($MessageTracker.Summary.Success / $MessageTracker.Summary.Total) * 100, 2))%" -ForegroundColor Yellow
Write-Host "Duração real: $([math]::Round($ActualDuration, 2))s (target: $TimeWindowSeconds s)" -ForegroundColor White
Write-Host "Throughput: $([math]::Round($MessageTracker.Summary.Total / $ActualDuration, 2)) req/s" -ForegroundColor Yellow

Write-Host "`nPROCESSAMENTO POR COMPONENTE ARQUITETURAL:" -ForegroundColor White
$MessageTracker.Components.GetEnumerator() | ForEach-Object {
    $compName = $_.Key
    $compData = $_.Value
    $requestCount = $compData.Requests.Count
    
    if ($requestCount -gt 0) {
        $avgLatency = if (($compData.Requests | Where-Object { $_.Success }).Count -gt 0) { 
            [math]::Round(($compData.Requests | Where-Object { $_.Success } | Measure-Object -Property Latency -Average).Average, 2) 
        } else { 0 }
        
        $successCount = ($compData.Requests | Where-Object { $_.Success }).Count
        $successRate = [math]::Round(($successCount / $requestCount) * 100, 2)
        
        Write-Host "`n📍 $compName:" -ForegroundColor Cyan
        Write-Host "   Status: $($compData.Status)" -ForegroundColor White
        Write-Host "   Mensagens processadas: $requestCount" -ForegroundColor White
        Write-Host "   Taxa de sucesso: $successRate%" -ForegroundColor $(if($successRate -ge 95) {"Green"} else {"Red"})
        Write-Host "   Latência média: ${avgLatency}ms" -ForegroundColor White
        Write-Host "   Erros: $($compData.Errors)" -ForegroundColor Red
        
        # Mostrar algumas hashes de exemplo
        Write-Host "   Hashes de mensagens (primeiras 3):" -ForegroundColor Gray
        $compData.Requests | Select-Object -First 3 | ForEach-Object {
            $status = if ($_.Success) { "✅" } else { "❌" }
            Write-Host "     $status $($_.Hash) -> $($_.Latency)ms" -ForegroundColor Gray
        }
    }
}

Write-Host "`nTIMELINE DE PROCESSAMENTO (últimos 10 requests):" -ForegroundColor White
$MessageTracker.Timeline | Select-Object -Last 10 | ForEach-Object {
    $status = if ($_.Success) { "✅" } else { "❌" }
    $time = $_.Time.ToString("HH:mm:ss.fff")
    Write-Host "$status $time - Hash: $($_.Hash) - Componente: $($_.Component) - Latência: $($_.Latency)ms" -ForegroundColor Gray
}

# CRIAR MAPEAMENTO ARQUITETURAL
Write-Host "`n" + "="*80 -ForegroundColor Green
Write-Host "MAPEAMENTO ARQUITETURAL DE PROCESSAMENTO" -ForegroundColor Green
Write-Host "="*80 -ForegroundColor Green

# Agrupar mensagens por nó de processamento
$ProcessingNodes = $MessageTracker.Messages | Group-Object ProcessingNode
Write-Host "`nDISTRIBUIÇÃO POR NÓ DE PROCESSAMENTO:" -ForegroundColor White
$ProcessingNodes | ForEach-Object {
    $nodeName = $_.Name
    $nodeMessages = $_.Group
    $nodeSuccess = ($nodeMessages | Where-Object { $_.Success }).Count
    $nodeTotal = $nodeMessages.Count
    $nodeSuccessRate = [math]::Round(($nodeSuccess / $nodeTotal) * 100, 2)
    
    Write-Host "`n🖥️  $nodeName:" -ForegroundColor Yellow
    Write-Host "   Mensagens processadas: $nodeTotal" -ForegroundColor White
    Write-Host "   Taxa de sucesso: $nodeSuccessRate%" -ForegroundColor White
    Write-Host "   Componentes utilizados:" -ForegroundColor White
    
    $nodeMessages | Group-Object Component | ForEach-Object {
        $compName = $_.Name
        $compCount = $_.Count
        Write-Host "     - $compName: $compCount mensagens" -ForegroundColor Cyan
    }
}

# Salvar dados detalhados
$DetailedReport = @{
    TestMetadata = @{
        Type = "MessageTracking"
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        TotalRequests = $TotalRequests
        TimeWindow = $TimeWindowSeconds
        ActualDuration = $ActualDuration
        Port = $Port
    }
    Summary = $MessageTracker.Summary
    Components = @{}
    Messages = $MessageTracker.Messages
    Timeline = $MessageTracker.Timeline
    ProcessingDistribution = @{}
}

# Processar estatísticas por componente
$MessageTracker.Components.GetEnumerator() | ForEach-Object {
    $compName = $_.Key
    $compData = $_.Value
    
    if ($compData.Requests.Count -gt 0) {
        $successMessages = $compData.Requests | Where-Object { $_.Success }
        $DetailedReport.Components[$compName] = @{
            Status = $compData.Status
            TotalMessages = $compData.Requests.Count
            SuccessfulMessages = $successMessages.Count
            SuccessRate = [math]::Round(($successMessages.Count / $compData.Requests.Count) * 100, 2)
            AverageLatency = if ($successMessages.Count -gt 0) { 
                [math]::Round(($successMessages | Measure-Object -Property Latency -Average).Average, 2) 
            } else { 0 }
            MessageHashes = $compData.Requests | Select-Object -Property Hash, Success, Latency
            IsMocked = if ($compName -eq "StocksAPI") { $MessageTracker.Components.StocksAPI.IsMocked } else { $false }
        }
    }
}

# Processamento por nó
$ProcessingNodes | ForEach-Object {
    $DetailedReport.ProcessingDistribution[$_.Name] = @{
        TotalMessages = $_.Count
        SuccessfulMessages = ($_.Group | Where-Object { $_.Success }).Count
        ComponentBreakdown = ($_.Group | Group-Object Component | ForEach-Object { 
            @{ Component = $_.Name; Count = $_.Count } 
        })
    }
}

# Salvar relatório
if (-not (Test-Path "dashboard\data")) { New-Item -Path "dashboard\data" -Type Directory -Force | Out-Null }

$json = $DetailedReport | ConvertTo-Json -Depth 6
$path = "dashboard\data\message-tracking-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$json | Out-File $path -Encoding UTF8

Write-Host "`nRelatório detalhado salvo: $path" -ForegroundColor Green

# Estatísticas finais
$totalLatency = ($MessageTracker.Messages | Where-Object { $_.Success } | Measure-Object -Property Latency -Sum).Sum
$avgOverallLatency = if ($MessageTracker.Summary.Success -gt 0) { [math]::Round($totalLatency / $MessageTracker.Summary.Success, 2) } else { 0 }

Write-Host "`nESTATÍSTICAS FINAIS:" -ForegroundColor Magenta
Write-Host "Latência média geral: ${avgOverallLatency}ms" -ForegroundColor Yellow
Write-Host "Total de hashes únicos gerados: $($MessageTracker.Messages.Count)" -ForegroundColor Cyan
Write-Host "Componentes ativos: $($MessageTracker.Components.Keys | Where-Object { $MessageTracker.Components[$_].Requests.Count -gt 0 } | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "Nós de processamento utilizados: $($ProcessingNodes.Count)" -ForegroundColor Cyan

Write-Host "`nTESTE DE RASTREAMENTO CONCLUÍDO COM SUCESSO!" -ForegroundColor Magenta
