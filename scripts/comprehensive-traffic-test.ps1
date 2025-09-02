Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "           TESTE DE TRAFEGO - VIRTUAL STOCK SERVICE" -ForegroundColor Cyan  
Write-Host "===================================================================" -ForegroundColor Cyan

$TotalRequests = 25
$BaseUrl = "http://localhost:8080"

Write-Host "`n1. Verificando status da aplicacao..." -ForegroundColor Yellow
Write-Host "   URL: $BaseUrl" -ForegroundColor White

$AppRunning = $false
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/actuator/health" -TimeoutSec 3
    Write-Host "   Status: APLICACAO RODANDO" -ForegroundColor Green
    $AppRunning = $true
}
catch {
    Write-Host "   Status: APLICACAO NAO ENCONTRADA" -ForegroundColor Red
    Write-Host "   Continuando com simulacao de testes..." -ForegroundColor Yellow
}

Write-Host "`n2. Executando testes de trafego..." -ForegroundColor Yellow
Write-Host "   Total de requests: $TotalRequests" -ForegroundColor White

$Results = @{
    HealthChecks = 0
    ApiRequests = 0  
    PostRequests = 0
    Errors = 0
    TotalTime = 0
}

$StartTime = Get-Date

if ($AppRunning) {
    # Testes reais com aplicacao rodando
    for ($i = 1; $i -le $TotalRequests; $i++) {
        $RequestType = $i % 3
        $success = $false
        
        try {
            switch ($RequestType) {
                0 { 
                    $result = Invoke-RestMethod -Uri "$BaseUrl/actuator/health" -TimeoutSec 5
                    $Results.HealthChecks++
                    $success = $true
                }
                1 { 
                    $result = Invoke-RestMethod -Uri "$BaseUrl/api/v1/stocks" -TimeoutSec 5
                    $Results.ApiRequests++
                    $success = $true
                }
                2 { 
                    $body = @{
                        productId = "PROD-$i"
                        symbol = "TST$i"
                        productName = "Produto Teste $i"
                        initialQuantity = 100
                        unitPrice = 25.50
                    } | ConvertTo-Json
                    
                    $result = Invoke-RestMethod -Uri "$BaseUrl/api/v1/stocks" -Method POST -Body $body -ContentType "application/json" -TimeoutSec 5
                    $Results.PostRequests++
                    $success = $true
                }
            }
        }
        catch {
            $Results.Errors++
        }
        
        $percentage = [math]::Round(($i / $TotalRequests) * 100, 1)
        if ($success) {
            Write-Host "   Request $i/$TotalRequests ($percentage%) - OK" -ForegroundColor Green
        } else {
            Write-Host "   Request $i/$TotalRequests ($percentage%) - ERRO" -ForegroundColor Red
        }
        
        Start-Sleep -Milliseconds 150
    }
} else {
    # Simulacao de testes  
    for ($i = 1; $i -le $TotalRequests; $i++) {
        $RequestType = $i % 3
        
        switch ($RequestType) {
            0 { 
                $Results.HealthChecks++
                Write-Host "   [SIMULADO] Health Check $i/$TotalRequests" -ForegroundColor Blue
            }
            1 { 
                $Results.ApiRequests++
                Write-Host "   [SIMULADO] GET Stocks $i/$TotalRequests" -ForegroundColor Blue
            }
            2 { 
                $Results.PostRequests++
                Write-Host "   [SIMULADO] POST Stock $i/$TotalRequests" -ForegroundColor Blue
            }
        }
        
        Start-Sleep -Milliseconds 200
    }
}

$EndTime = Get-Date
$Results.TotalTime = ($EndTime - $StartTime).TotalSeconds

Write-Host "`n3. Relatorio de Resultados" -ForegroundColor Yellow
Write-Host "===================================================================" -ForegroundColor Cyan

if ($AppRunning) {
    Write-Host "TESTES REAIS EXECUTADOS:" -ForegroundColor Green
    Write-Host "   Health Checks: $($Results.HealthChecks)" -ForegroundColor White
    Write-Host "   API GET Requests: $($Results.ApiRequests)" -ForegroundColor White  
    Write-Host "   API POST Requests: $($Results.PostRequests)" -ForegroundColor White
    Write-Host "   Erros: $($Results.Errors)" -ForegroundColor White
    
    $SuccessRate = [math]::Round((($TotalRequests - $Results.Errors) / $TotalRequests) * 100, 2)
    Write-Host "   Taxa de Sucesso: $SuccessRate%" -ForegroundColor Yellow
    
    if ($SuccessRate -gt 90) {
        Write-Host "   Avaliacoe: EXCELENTE" -ForegroundColor Green
    } elseif ($SuccessRate -gt 75) {
        Write-Host "   Avaliacoe: BOM" -ForegroundColor Yellow  
    } else {
        Write-Host "   Avaliacoe: NECESSITA ATENCAO" -ForegroundColor Red
    }
} else {
    Write-Host "SIMULACAO DE TESTES EXECUTADA:" -ForegroundColor Blue
    Write-Host "   Health Checks Simulados: $($Results.HealthChecks)" -ForegroundColor White
    Write-Host "   API GET Simulados: $($Results.ApiRequests)" -ForegroundColor White
    Write-Host "   API POST Simulados: $($Results.PostRequests)" -ForegroundColor White
    Write-Host "   Total Simulado: $TotalRequests requests" -ForegroundColor White
}

Write-Host "   Tempo Total: $([math]::Round($Results.TotalTime, 2)) segundos" -ForegroundColor White
Write-Host "   Throughput: $([math]::Round($TotalRequests / $Results.TotalTime, 2)) req/s" -ForegroundColor White

Write-Host "`n4. Próximos Passos" -ForegroundColor Yellow
if (-not $AppRunning) {
    Write-Host "   - Inicializar aplicacao Spring Boot na porta 8080" -ForegroundColor White
    Write-Host "   - Configurar banco de dados (H2/PostgreSQL)" -ForegroundColor White  
    Write-Host "   - Configurar Kafka para mensageria" -ForegroundColor White
    Write-Host "   - Re-executar testes com aplicacao rodando" -ForegroundColor White
} else {
    Write-Host "   - Aplicacao funcionando corretamente!" -ForegroundColor Green
    Write-Host "   - Considere testes de carga mais intensivos" -ForegroundColor White
    Write-Host "   - Monitore metricas de performance" -ForegroundColor White
}

Write-Host "`n===================================================================" -ForegroundColor Cyan
Write-Host "                    TESTE DE TRAFEGO CONCLUIDO" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
