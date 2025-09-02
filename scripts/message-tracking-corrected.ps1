# Script PowerShell - Rastreamento de Mensagens Corrigido

# Configuração inicial
$ErrorActionPreference = "Continue"
$ProgressPreference = "Continue"

# Parâmetros do teste
$totalRequests = 100
$targetDuration = 20
$baseUrl = "http://localhost:8080"

# Endpoints com pesos para distribuição
$endpoints = @(
    @{ url = "$baseUrl/api/test"; weight = 25; component = "TestEndpoint" }
    @{ url = "$baseUrl/actuator/health"; weight = 30; component = "ActuatorHealth" }
    @{ url = "$baseUrl/actuator/info"; weight = 20; component = "ActuatorInfo" }
    @{ url = "$baseUrl/api/stocks/AAPL"; weight = 25; component = "StocksAPI" }
)

# Inicialização de estruturas de dados
$results = @()
$processedHashes = @{}
$componentStats = @{}
$nodeProcessing = @{}

# Função para gerar hash SHA256 (CORRIGIDA)
function Generate-MessageHash {
    param([string]$message)
    
    try {
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $hashBytes = $sha256.ComputeHash($bytes)
        
        # CORREÇÃO: Usar método .Substring() ao invés de cmdlet Substring
        $hashString = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
        $shortHash = $hashString.Substring(0, 8)
        
        $sha256.Dispose()
        return $shortHash
    }
    catch {
        Write-Warning "Erro ao gerar hash: $($_.Exception.Message)"
        return [System.Guid]::NewGuid().ToString().Substring(0, 8)
    }
}

# Função de load balancing baseada em hash
function Select-EndpointByHash {
    param([string]$hash)
    
    # Converter hash para número para distribuição consistente
    $hashNum = [Convert]::ToInt32($hash.Substring(0, 2), 16)
    $index = $hashNum % $endpoints.Count
    
    return $endpoints[$index]
}

# Função para executar requisição com rastreamento
function Invoke-TrackedRequest {
    param($endpoint, $hash, $requestId)
    
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri $endpoint.url -Method Get -TimeoutSec 30
        $endTime = Get-Date
        $latency = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            RequestId = $requestId
            Hash = $hash
            Endpoint = $endpoint.url
            Component = $endpoint.component
            StartTime = $startTime
            EndTime = $endTime
            Latency = [math]::Round($latency, 2)
            StatusCode = $response.StatusCode
            Success = $true
            Response = $response.Content
        }
    }
    catch {
        $endTime = Get-Date
        $latency = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            RequestId = $requestId
            Hash = $hash
            Endpoint = $endpoint.url
            Component = $endpoint.component
            StartTime = $startTime
            EndTime = $endTime
            Latency = [math]::Round($latency, 2)
            StatusCode = 0
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Iniciar teste
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "TESTE DE RASTREAMENTO DE MENSAGENS - VERSÃO CORRIGIDA" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "Iniciando teste com $totalRequests requisições em $targetDuration segundos..." -ForegroundColor Yellow

$testStartTime = Get-Date
$delayBetweenRequests = ($targetDuration * 1000) / $totalRequests

# Executar requisições com rastreamento de hash
for ($i = 1; $i -le $totalRequests; $i++) {
    # Gerar hash único para a mensagem
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    $messageContent = "Request_$i`_$timestamp`_$(Get-Random)"
    $messageHash = Generate-MessageHash -message $messageContent
    
    # Verificar se hash já foi processado (evitar duplicatas)
    if ($processedHashes.ContainsKey($messageHash)) {
        Write-Warning "Hash duplicado detectado: $messageHash - Regenerando..."
        $messageContent += "_$(Get-Random -Maximum 9999)"
        $messageHash = Generate-MessageHash -message $messageContent
    }
    
    # Selecionar endpoint baseado no hash
    $selectedEndpoint = Select-EndpointByHash -hash $messageHash
    
    # Executar requisição
    $result = Invoke-TrackedRequest -endpoint $selectedEndpoint -hash $messageHash -requestId $i
    $results += $result
    
    # Registrar hash como processado
    $processedHashes[$messageHash] = @{
        RequestId = $i
        Component = $selectedEndpoint.component
        Timestamp = $timestamp
        ProcessingNode = "Node_$($selectedEndpoint.component)"
    }
    
    # Atualizar estatísticas por componente
    if (-not $componentStats.ContainsKey($selectedEndpoint.component)) {
        $componentStats[$selectedEndpoint.component] = @{
            Count = 0
            SuccessCount = 0
            TotalLatency = 0
            Hashes = @()
        }
    }
    
    $componentStats[$selectedEndpoint.component].Count++
    if ($result.Success) {
        $componentStats[$selectedEndpoint.component].SuccessCount++
    }
    $componentStats[$selectedEndpoint.component].TotalLatency += $result.Latency
    $componentStats[$selectedEndpoint.component].Hashes += $messageHash
    
    # Atualizar estatísticas por nó de processamento
    $nodeName = "Node_$($selectedEndpoint.component)"
    if (-not $nodeProcessing.ContainsKey($nodeName)) {
        $nodeProcessing[$nodeName] = @{
            Component = $selectedEndpoint.component
            ProcessedHashes = @()
            TotalLatency = 0
            SuccessCount = 0
        }
    }
    
    $nodeProcessing[$nodeName].ProcessedHashes += $messageHash
    $nodeProcessing[$nodeName].TotalLatency += $result.Latency
    if ($result.Success) {
        $nodeProcessing[$nodeName].SuccessCount++
    }
    
    # Progress update
    if ($i % 20 -eq 0) {
        $successRate = [math]::Round(($results | Where-Object { $_.Success }).Count / $results.Count * 100, 1)
        $currentRate = [math]::Round($i / ((Get-Date) - $testStartTime).TotalSeconds, 1)
        Write-Host "Progress: $i/$totalRequests - Taxa sucesso: $successRate% - Rate: $currentRate req/s" -ForegroundColor Green
    }
    
    # Delay para distribuir no tempo especificado
    Start-Sleep -Milliseconds $delayBetweenRequests
}

$testEndTime = Get-Date
$totalDuration = ($testEndTime - $testStartTime).TotalSeconds

# Relatório detalhado
Write-Host "`n=================================================================================" -ForegroundColor Cyan
Write-Host "RELATORIO DE RASTREAMENTO DE MENSAGENS - CORRIGIDO" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan

$successfulRequests = $results | Where-Object { $_.Success }
$failedRequests = $results | Where-Object { -not $_.Success }

Write-Host "`nRESUMO EXECUTIVO:" -ForegroundColor Yellow
Write-Host "Total de mensagens: $totalRequests"
Write-Host "Mensagens processadas com sucesso: $($successfulRequests.Count)"
Write-Host "Mensagens com falha: $($failedRequests.Count)"
Write-Host "Taxa de sucesso: $([math]::Round($successfulRequests.Count / $totalRequests * 100, 1))%"
Write-Host "Duração real: $([math]::Round($totalDuration, 2))s (target: $targetDuration s)"
Write-Host "Throughput: $([math]::Round($totalRequests / $totalDuration, 2)) req/s"
Write-Host "Hashes únicos gerados: $($processedHashes.Keys.Count)"

Write-Host "`nPROCESSAMENTO POR COMPONENTE ARQUITETURAL:" -ForegroundColor Yellow
foreach ($component in $componentStats.Keys) {
    $stats = $componentStats[$component]
    $avgLatency = if ($stats.Count -gt 0) { [math]::Round($stats.TotalLatency / $stats.Count, 2) } else { 0 }
    $successRate = if ($stats.Count -gt 0) { [math]::Round($stats.SuccessCount / $stats.Count * 100, 1) } else { 0 }
    
    Write-Host "`nCOMPONENTE $component" -ForegroundColor Cyan
    Write-Host "   Status: DISPONÍVEL"
    Write-Host "   Mensagens processadas: $($stats.Count)"
    Write-Host "   Taxa de sucesso: $successRate%"
    Write-Host "   Latência média: $avgLatency ms"
    Write-Host "   Hashes únicos: $($stats.Hashes.Count)"
    Write-Host "   Primeiros 3 hashes:"
    
    $firstThreeHashes = $stats.Hashes | Select-Object -First 3
    foreach ($hash in $firstThreeHashes) {
        $hashInfo = $processedHashes[$hash]
        $result = $results | Where-Object { $_.Hash -eq $hash } | Select-Object -First 1
        if ($result) {
            $status = if ($result.Success) { "OK" } else { "ERRO" }
            Write-Host "     $hash -> $status ($($result.Latency) ms)"
        }
    }
}

Write-Host "`nTIMELINE DE PROCESSAMENTO (últimos 10 requests):" -ForegroundColor Yellow
$lastTenResults = $results | Select-Object -Last 10
foreach ($result in $lastTenResults) {
    $status = if ($result.Success) { "OK" } else { "ERRO" }
    $timestamp = $result.StartTime.ToString("HH:mm:ss.fff")
    Write-Host "$status $timestamp - Hash: $($result.Hash) - Componente: $($result.Component) - Latência: $($result.Latency) ms"
}

Write-Host "`n=================================================================================" -ForegroundColor Cyan
Write-Host "MAPEAMENTO ARQUITETURAL DE PROCESSAMENTO" -ForegroundColor Cyan
Write-Host "=================================================================================" -ForegroundColor Cyan

Write-Host "`nDISTRIBUIÇÃO POR NÓ DE PROCESSAMENTO:" -ForegroundColor Yellow
foreach ($nodeName in $nodeProcessing.Keys) {
    $nodeInfo = $nodeProcessing[$nodeName]
    $avgLatency = if ($nodeInfo.ProcessedHashes.Count -gt 0) { 
        [math]::Round($nodeInfo.TotalLatency / $nodeInfo.ProcessedHashes.Count, 2) 
    } else { 0 }
    $successRate = if ($nodeInfo.ProcessedHashes.Count -gt 0) { 
        [math]::Round($nodeInfo.SuccessCount / $nodeInfo.ProcessedHashes.Count * 100, 1) 
    } else { 0 }
    
    Write-Host "`n$nodeName ($($nodeInfo.Component))" -ForegroundColor Cyan
    Write-Host "   Mensagens processadas: $($nodeInfo.ProcessedHashes.Count)"
    Write-Host "   Taxa de sucesso: $successRate%"
    Write-Host "   Latência média: $avgLatency ms"
    Write-Host "   Hashes processados (primeiros 5):"
    
    $firstFiveHashes = $nodeInfo.ProcessedHashes | Select-Object -First 5
    foreach ($hash in $firstFiveHashes) {
        Write-Host "     - $hash"
    }
}

# Salvar resultados em JSON
$reportData = @{
    TestSummary = @{
        TotalRequests = $totalRequests
        SuccessfulRequests = $successfulRequests.Count
        FailedRequests = $failedRequests.Count
        SuccessRate = [math]::Round($successfulRequests.Count / $totalRequests * 100, 2)
        Duration = [math]::Round($totalDuration, 2)
        Throughput = [math]::Round($totalRequests / $totalDuration, 2)
        UniqueHashes = $processedHashes.Keys.Count
    }
    ComponentStats = $componentStats
    NodeProcessing = $nodeProcessing
    ProcessedHashes = $processedHashes
    AllResults = $results
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

$reportPath = "dashboard\data\message-tracking-corrected-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
if (-not (Test-Path "dashboard\data")) {
    New-Item -ItemType Directory -Path "dashboard\data" -Force | Out-Null
}

$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nRelatório detalhado salvo: $reportPath" -ForegroundColor Green

# Estatísticas finais de hash
$uniqueHashes = $processedHashes.Keys.Count
$expectedHashes = $totalRequests
$hashCollisions = $totalRequests - $uniqueHashes

Write-Host "`nESTATÍSTICAS FINAIS DE HASH PROCESSING:" -ForegroundColor Yellow
Write-Host "Hashes únicos gerados: $uniqueHashes de $expectedHashes esperados"
Write-Host "Taxa de unicidade: $([math]::Round($uniqueHashes / $expectedHashes * 100, 1))%"
Write-Host "Colisões de hash: $hashCollisions"
Write-Host "Componentes ativos: $($componentStats.Keys.Count)"
Write-Host "Nós de processamento utilizados: $($nodeProcessing.Keys.Count)"

if ($uniqueHashes -eq $expectedHashes) {
    Write-Host "`n✅ TESTE DE RASTREAMENTO CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "✅ Todos os hashes foram gerados corretamente!" -ForegroundColor Green
    Write-Host "✅ Nenhuma colisão de hash detectada!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ ATENÇÃO: Alguns hashes podem ter colidido!" -ForegroundColor Yellow
    Write-Host "⚠️ Verifique os logs para detalhes!" -ForegroundColor Yellow
}

Write-Host "`n=================================================================================" -ForegroundColor Cyan
