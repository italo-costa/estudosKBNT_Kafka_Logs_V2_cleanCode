# Script PowerShell - Rastreamento de Mensagens Simples
$ErrorActionPreference = "Continue"

# Configuração
$totalRequests = 100
$baseUrl = "http://localhost:8080"

$endpoints = @(
    @{ url = "$baseUrl/api/test"; component = "TestEndpoint" }
    @{ url = "$baseUrl/actuator/health"; component = "ActuatorHealth" }
    @{ url = "$baseUrl/actuator/info"; component = "ActuatorInfo" }
    @{ url = "$baseUrl/api/stocks/AAPL"; component = "StocksAPI" }
)

$results = @()
$hashes = @{}

# Função para gerar hash
function Generate-Hash {
    param([string]$message)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)
    $hashBytes = $sha256.ComputeHash($bytes)
    $hashString = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
    $sha256.Dispose()
    return $hashString.Substring(0, 8)
}

Write-Host "Iniciando teste de rastreamento de mensagens..." -ForegroundColor Green
Write-Host "Total de requisições: $totalRequests" -ForegroundColor Yellow

$startTime = Get-Date

for ($i = 1; $i -le $totalRequests; $i++) {
    # Gerar hash único
    $message = "Request_$i`_$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss-fff')_$(Get-Random)"
    $hash = Generate-Hash -message $message
    
    # Selecionar endpoint baseado no hash
    $hashValue = [Convert]::ToInt32($hash.Substring(0, 2), 16)
    $endpointIndex = $hashValue % $endpoints.Count
    $selectedEndpoint = $endpoints[$endpointIndex]
    
    $reqStartTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri $selectedEndpoint.url -Method Get -TimeoutSec 5
        $reqEndTime = Get-Date
        $latency = ($reqEndTime - $reqStartTime).TotalMilliseconds
        
        $result = @{
            Id = $i
            Hash = $hash
            Endpoint = $selectedEndpoint.url
            Component = $selectedEndpoint.component
            StartTime = $reqStartTime
            Latency = [math]::Round($latency, 2)
            Success = $true
            StatusCode = $response.StatusCode
        }
    }
    catch {
        $reqEndTime = Get-Date
        $latency = ($reqEndTime - $reqStartTime).TotalMilliseconds
        
        $result = @{
            Id = $i
            Hash = $hash
            Endpoint = $selectedEndpoint.url
            Component = $selectedEndpoint.component
            StartTime = $reqStartTime
            Latency = [math]::Round($latency, 2)
            Success = $false
            Error = $_.Exception.Message
        }
    }
    
    $results += $result
    $hashes[$hash] = $result
    
    if ($i % 25 -eq 0) {
        $successRate = ($results | Where-Object { $_.Success }).Count / $results.Count * 100
        Write-Host "Progresso: $i/$totalRequests - Sucesso: $([math]::Round($successRate, 1))%" -ForegroundColor Green
    }
    
    Start-Sleep -Milliseconds 200
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Relatório
Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "RELATORIO DE RASTREAMENTO DE MENSAGENS" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$successful = $results | Where-Object { $_.Success }
$failed = $results | Where-Object { -not $_.Success }

Write-Host "`nRESUMO EXECUTIVO:" -ForegroundColor Yellow
Write-Host "Total de mensagens: $totalRequests"
Write-Host "Mensagens processadas com sucesso: $($successful.Count)"
Write-Host "Mensagens com falha: $($failed.Count)"
Write-Host "Taxa de sucesso: $([math]::Round($successful.Count / $totalRequests * 100, 1))%"
Write-Host "Duração: $([math]::Round($duration, 2)) segundos"
Write-Host "Throughput: $([math]::Round($totalRequests / $duration, 2)) req/s"
Write-Host "Hashes únicos gerados: $($hashes.Keys.Count)"

Write-Host "`nPROCESSAMENTO POR COMPONENTE:" -ForegroundColor Yellow

$componentStats = $results | Group-Object -Property Component
foreach ($group in $componentStats) {
    $componentResults = $group.Group
    $successCount = ($componentResults | Where-Object { $_.Success }).Count
    $avgLatency = ($componentResults | Measure-Object -Property Latency -Average).Average
    
    Write-Host "`n$($group.Name):" -ForegroundColor Cyan
    Write-Host "  Mensagens: $($group.Count)"
    Write-Host "  Sucessos: $successCount"
    Write-Host "  Taxa sucesso: $([math]::Round($successCount / $group.Count * 100, 1))%"
    Write-Host "  Latência média: $([math]::Round($avgLatency, 2)) ms"
    
    # Mostrar alguns hashes
    Write-Host "  Hashes (primeiros 3):"
    $componentResults | Select-Object -First 3 | ForEach-Object {
        $status = if ($_.Success) { "OK" } else { "ERRO" }
        Write-Host "    $($_.Hash) -> $status ($($_.Latency) ms)"
    }
}

Write-Host "`nTIMELINE (últimos 10 requests):" -ForegroundColor Yellow
$results | Select-Object -Last 10 | ForEach-Object {
    $status = if ($_.Success) { "OK" } else { "ERRO" }
    $time = $_.StartTime.ToString("HH:mm:ss.fff")
    Write-Host "$status $time - Hash: $($_.Hash) - $($_.Component) - $($_.Latency)ms"
}

# Salvar dados
$reportData = @{
    Summary = @{
        TotalRequests = $totalRequests
        SuccessCount = $successful.Count
        FailureCount = $failed.Count
        SuccessRate = [math]::Round($successful.Count / $totalRequests * 100, 2)
        Duration = [math]::Round($duration, 2)
        Throughput = [math]::Round($totalRequests / $duration, 2)
        UniqueHashes = $hashes.Keys.Count
    }
    Results = $results
    Hashes = $hashes
    ComponentStats = @{}
}

foreach ($group in $componentStats) {
    $componentResults = $group.Group
    $successCount = ($componentResults | Where-Object { $_.Success }).Count
    $avgLatency = ($componentResults | Measure-Object -Property Latency -Average).Average
    
    $reportData.ComponentStats[$group.Name] = @{
        Count = $group.Count
        SuccessCount = $successCount
        SuccessRate = [math]::Round($successCount / $group.Count * 100, 2)
        AvgLatency = [math]::Round($avgLatency, 2)
        Hashes = $componentResults | ForEach-Object { $_.Hash }
    }
}

if (-not (Test-Path "dashboard\data")) {
    New-Item -ItemType Directory -Path "dashboard\data" -Force | Out-Null
}

$reportPath = "dashboard\data\message-tracking-final-$(Get-Date -Format 'yyyyMMdd-HHmm').json"
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRelatório salvo: $reportPath" -ForegroundColor Green

if ($hashes.Keys.Count -eq $totalRequests) {
    Write-Host "`n✅ TESTE CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "✅ Todos os hashes foram gerados corretamente!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Alguns hashes podem ter colidido!" -ForegroundColor Yellow
}

Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
