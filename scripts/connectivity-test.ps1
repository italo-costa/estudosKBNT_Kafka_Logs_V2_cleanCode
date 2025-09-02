param()

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "           TESTE DE CONECTIVIDADE - SPRING BOOT" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$endpoints = @(
    "http://localhost:8080/test",
    "http://localhost:8080/actuator/health", 
    "http://localhost:8080/actuator/info",
    "http://localhost:8080/api/v1/stocks",
    "http://127.0.0.1:8080/actuator/health"
)

Write-Host "`n1. Verificando processos Java..." -ForegroundColor Yellow
$javaProcesses = Get-Process | Where-Object {$_.ProcessName -eq "java"} | Select-Object Id, ProcessName, StartTime
if ($javaProcesses) {
    $javaProcesses | Format-Table -AutoSize
    Write-Host "   Java processes: ENCONTRADOS" -ForegroundColor Green
} else {
    Write-Host "   Java processes: NENHUM" -ForegroundColor Red
}

Write-Host "`n2. Verificando portas em uso..." -ForegroundColor Yellow
$ports = @(8080, 8081, 9090)
foreach ($port in $ports) {
    $portCheck = netstat -ano | findstr ":$port"
    if ($portCheck) {
        Write-Host "   Porta ${port}: EM USO" -ForegroundColor Green
        Write-Host "     $portCheck" -ForegroundColor White
    } else {
        Write-Host "   Porta ${port}: LIVRE" -ForegroundColor Yellow
    }
}

Write-Host "`n3. Testando conectividade HTTP..." -ForegroundColor Yellow

foreach ($url in $endpoints) {
    Write-Host "   Testando: $url" -ForegroundColor White
    
    try {
        $startTime = Get-Date
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 5
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "     SUCESSO ($([math]::Round($duration))ms)" -ForegroundColor Green
        
        if ($response -is [hashtable] -or $response -is [PSCustomObject]) {
            Write-Host "     Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
        } else {
            Write-Host "     Response: $($response.ToString().Substring(0, [Math]::Min(100, $response.ToString().Length)))" -ForegroundColor Cyan
        }
        
    } catch [System.Net.WebException] {
        Write-Host "     ERRO DE REDE: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "     HTTP Status: $statusCode" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "     ERRO: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep 1
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    TESTE CONCLUIDO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
