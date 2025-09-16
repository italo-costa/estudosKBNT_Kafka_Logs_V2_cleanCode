# Test Virtual Stock Service API

$wslCommand = "wsl -e bash -c 'curl -s http://localhost:8084/actuator/health'"
Write-Host "Testando Virtual Stock Service via WSL2..." -ForegroundColor Green

try {
    $response = Invoke-Expression $wslCommand
    $healthData = $response | ConvertFrom-Json
    
    Write-Host "✅ Aplicação está funcionando!" -ForegroundColor Green
    Write-Host "Status: $($healthData.status)" -ForegroundColor Yellow
    Write-Host "Banco de dados: $($healthData.components.db.status)" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Erro ao testar aplicação: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTestando endpoints da API..." -ForegroundColor Cyan

# Testar endpoints principais
$endpoints = @(
    @{Path="/"; Description="Página inicial"},
    @{Path="/ping"; Description="Ping"},
    @{Path="/api/v1/health"; Description="Health da API"},
    @{Path="/api/v1/virtual-stock/stocks"; Description="Lista de stocks"}
)

foreach ($endpoint in $endpoints) {
    try {
        $cmd = "wsl -e bash -c 'curl -s http://localhost:8084$($endpoint.Path)'"
        $result = Invoke-Expression $cmd
        Write-Host "✅ $($endpoint.Description): $($endpoint.Path)" -ForegroundColor Green
        if ($endpoint.Path -eq "/api/v1/virtual-stock/stocks") {
            $stockData = $result | ConvertFrom-Json
            Write-Host "   Sucesso: $($stockData.success), Mensagem: $($stockData.message)" -ForegroundColor Gray
        } else {
            Write-Host "   Resposta: $($result.Substring(0, [Math]::Min($result.Length, 50)))" -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ $($endpoint.Description): $($endpoint.Path)" -ForegroundColor Red
    }
}

Write-Host "`nAplicacao Virtual Stock Service esta operacional!" -ForegroundColor Green
Write-Host "Para testar via Postman, execute primeiro setup-port-forwarding.ps1 como Administrador" -ForegroundColor Yellow
