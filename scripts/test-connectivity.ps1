#!/usr/bin/env pwsh
# Script de teste de conectividade para aplicação Spring Boot

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
        
        Write-Host "     ✅ SUCESSO ($([math]::Round($duration))ms)" -ForegroundColor Green
        
        if ($response -is [hashtable] -or $response -is [PSCustomObject]) {
            Write-Host "     Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Cyan
        } else {
            Write-Host "     Response: $($response.ToString().Substring(0, [Math]::Min(100, $response.ToString().Length)))" -ForegroundColor Cyan
        }
        
    } catch [System.Net.WebException] {
        Write-Host "     ❌ ERRO DE REDE: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            Write-Host "     HTTP Status: $statusCode" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "     ❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Start-Sleep 1
}

Write-Host "`n4. Teste alternativo com curl..." -ForegroundColor Yellow
try {
    Write-Host "   Executando: curl -v http://localhost:8080/actuator/health" -ForegroundColor White
    $curlResult = curl -v http://localhost:8080/actuator/health 2>&1
    Write-Host "   Curl resultado: $curlResult" -ForegroundColor Cyan
} catch {
    Write-Host "   Curl não disponível ou falhou: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n5. Informações do sistema..." -ForegroundColor Yellow
Write-Host "   Sistema Operacional: $($env:OS)" -ForegroundColor White
Write-Host "   Nome do Computador: $($env:COMPUTERNAME)" -ForegroundColor White
Write-Host "   Usuário: $($env:USERNAME)" -ForegroundColor White
Write-Host "   Java Home: $($env:JAVA_HOME)" -ForegroundColor White

Write-Host "`n6. Teste de firewall..." -ForegroundColor Yellow
try {
    $firewallRules = netsh advfirewall firewall show rule name="Java-Spring-Boot-8080" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Regra de firewall: EXISTE" -ForegroundColor Green
    } else {
        Write-Host "   Regra de firewall: NÃO EXISTE" -ForegroundColor Yellow
        Write-Host "   Execute como Administrador para criar:" -ForegroundColor Yellow
        Write-Host "   netsh advfirewall firewall add rule name=`"Java-Spring-Boot-8080`" dir=in action=allow protocol=TCP localport=8080" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   Verificação de firewall falhou: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    TESTE DE CONECTIVIDADE CONCLUÍDO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Mostrar recomendações baseadas nos resultados
Write-Host "`n📋 RECOMENDACOES:" -ForegroundColor Yellow
Write-Host "1. Se nenhum endpoint funcionou:" -ForegroundColor White
Write-Host "   - Execute como Administrador para configurar firewall" -ForegroundColor White
Write-Host "   - Tente porta alternativa: java -Dserver.port=8081" -ForegroundColor White
Write-Host "`n2. Se apenas localhost:8080 nao funciona:" -ForegroundColor White  
Write-Host "   - Problema de binding - use -Dserver.address=0.0.0.0" -ForegroundColor White
Write-Host "`n3. Se curl funciona mas PowerShell nao:" -ForegroundColor White
Write-Host "   - Problema de configuracao de proxy do PowerShell" -ForegroundColor White
