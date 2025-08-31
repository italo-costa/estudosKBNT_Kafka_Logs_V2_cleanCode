Write-Host "=== TESTE DE TRAFEGO API REST ===" -ForegroundColor Cyan

param(
    [int]$TotalRequests = 10,
    [string]$BaseUrl = "http://localhost:8080"
)

Write-Host "`nVerificando conectividade com $BaseUrl..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/actuator/health" -TimeoutSec 5
    Write-Host "Aplicacao esta respondendo!" -ForegroundColor Green
    
    Write-Host "`nExecutando $TotalRequests requests..." -ForegroundColor Yellow
    
    $successCount = 0
    for ($i = 1; $i -le $TotalRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$BaseUrl/api/v1/stocks" -TimeoutSec 10
            $successCount++
            Write-Host "Request $i - OK" -ForegroundColor Green
        }
        catch {
            Write-Host "Request $i - ERRO" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 100
    }
    
    Write-Host "`nRESULTADOS:" -ForegroundColor Cyan
    Write-Host "Sucessos: $successCount/$TotalRequests" -ForegroundColor Green
    Write-Host "Taxa: $([math]::Round(($successCount / $TotalRequests) * 100, 2))%" -ForegroundColor Yellow
    
}
catch {
    Write-Host "Aplicacao nao esta rodando em $BaseUrl" -ForegroundColor Red
    Write-Host "Executando simulacao..." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $TotalRequests; $i++) {
        Write-Host "Simulando Request $i/$TotalRequests" -ForegroundColor Blue
        Start-Sleep -Milliseconds 200
    }
    
    Write-Host "`nSimulacao completa - $TotalRequests requests simuladas" -ForegroundColor Green
}

Write-Host "`nTeste concluido!" -ForegroundColor Cyan
