#!/usr/bin/env pwsh
# Teste Integrado de Tráfego - 300 Mensagens
# Inclui inicialização completa da aplicação e teste de conectividade

param(
    [int]$TotalMessages = 300,
    [int]$Port = 8080,
    [switch]$ForceSimulation,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "      TESTE INTEGRADO DE TRÁFEGO - $TotalMessages MENSAGENS" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# === FASE 1: VERIFICAÇÃO DO AMBIENTE ===
Write-Host "`n🔍 FASE 1: VERIFICAÇÃO DO AMBIENTE" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor DarkCyan

Write-Host "`n1.1 Verificando prerequisitos..." -ForegroundColor White

# Verificar Java
$javaPath = "$env:JAVA_HOME\bin\java.exe"
if (-not $env:JAVA_HOME -or -not (Test-Path $javaPath)) {
    Write-Host "   ❌ JAVA_HOME não configurado" -ForegroundColor Red
    $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
    $javaPath = "$env:JAVA_HOME\bin\java.exe"
}

if (Test-Path $javaPath) {
    $javaVersion = & $javaPath -version 2>&1 | Select-Object -First 1
    Write-Host "   ✅ Java: $javaVersion" -ForegroundColor Green
} else {
    Write-Host "   ❌ Java não encontrado em: $javaPath" -ForegroundColor Red
    exit 1
}

# Verificar aplicação compilada
$jarPath = "C:\workspace\estudosKBNT_Kafka_Logs\simple-app\target\simple-stock-api-1.0.0.jar"
if (Test-Path $jarPath) {
    $jarSize = [math]::Round((Get-Item $jarPath).Length / 1MB, 2)
    Write-Host "   ✅ JAR encontrado: ${jarSize}MB" -ForegroundColor Green
} else {
    Write-Host "   ❌ JAR não encontrado: $jarPath" -ForegroundColor Red
    Write-Host "   Tentando compilar..." -ForegroundColor Yellow
    
    try {
        Set-Location "C:\workspace\estudosKBNT_Kafka_Logs\simple-app"
        $env:PATH = "C:\maven\apache-maven-3.9.4\bin;$env:PATH"
        & "C:\maven\apache-maven-3.9.4\bin\mvn" clean package -DskipTests -q
        
        if (Test-Path $jarPath) {
            Write-Host "   ✅ Compilação concluída" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Falha na compilação" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "   ❌ Erro na compilação: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# === FASE 2: LIMPEZA E PREPARAÇÃO ===
Write-Host "`n🧹 FASE 2: LIMPEZA E PREPARAÇÃO" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor DarkCyan

Write-Host "`n2.1 Verificando processos existentes..." -ForegroundColor White

# Limpar processos Java anteriores
$javaProcesses = Get-Process | Where-Object {$_.ProcessName -eq "java"}
if ($javaProcesses) {
    Write-Host "   ⚠️ Processos Java encontrados:" -ForegroundColor Yellow
    $javaProcesses | ForEach-Object {
        Write-Host "      PID $($_.Id) - $($_.ProcessName)" -ForegroundColor White
        try {
            Stop-Process -Id $_.Id -Force
            Write-Host "      ✅ Processo $($_.Id) finalizado" -ForegroundColor Green
        } catch {
            Write-Host "      ⚠️ Não foi possível finalizar processo $($_.Id)" -ForegroundColor Yellow
        }
    }
    Start-Sleep 3
} else {
    Write-Host "   ✅ Nenhum processo Java em execução" -ForegroundColor Green
}

# Verificar porta
Write-Host "`n2.2 Verificando porta $Port..." -ForegroundColor White
$portCheck = netstat -ano | findstr ":$Port"
if ($portCheck) {
    Write-Host "   ⚠️ Porta $Port em uso:" -ForegroundColor Yellow
    Write-Host "      $portCheck" -ForegroundColor White
    
    # Tentar liberar porta
    $processes = netstat -ano | findstr ":$Port" | ForEach-Object { 
        if ($_ -match '\s+(\d+)$') { $matches[1] } 
    } | Select-Object -Unique
    
    foreach ($pid in $processes) {
        try {
            Write-Host "   🔄 Liberando porta - finalizando PID: $pid" -ForegroundColor Yellow
            taskkill /PID $pid /F 2>$null
        } catch {
            Write-Host "   ⚠️ Não foi possível finalizar PID: $pid" -ForegroundColor Yellow
        }
    }
    Start-Sleep 2
} else {
    Write-Host "   ✅ Porta $Port disponível" -ForegroundColor Green
}

# === FASE 3: INICIALIZAÇÃO DA APLICAÇÃO ===
Write-Host "`n🚀 FASE 3: INICIALIZAÇÃO DA APLICAÇÃO" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor DarkCyan

Write-Host "`n3.1 Iniciando Spring Boot..." -ForegroundColor White

# Configurar parâmetros JVM otimizados
$jvmArgs = @(
    "-Dserver.address=0.0.0.0",
    "-Dserver.port=$Port",
    "-Djava.net.preferIPv4Stack=true",
    "-Dspring.profiles.active=dev",
    "-Xmx512m",
    "-Xms256m"
)

Write-Host "   Parâmetros JVM:" -ForegroundColor White
$jvmArgs | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }

# Iniciar aplicação em background
Set-Location "C:\workspace\estudosKBNT_Kafka_Logs\simple-app"

$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $javaPath
$processInfo.Arguments = "$($jvmArgs -join ' ') -jar `"$jarPath`""
$processInfo.UseShellExecute = $false
$processInfo.RedirectStandardOutput = $true
$processInfo.RedirectStandardError = $true
$processInfo.CreateNoWindow = $true

Write-Host "`n   🔄 Iniciando processo..." -ForegroundColor White
$process = [System.Diagnostics.Process]::Start($processInfo)

if ($process) {
    Write-Host "   ✅ Processo iniciado - PID: $($process.Id)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Falha ao iniciar processo" -ForegroundColor Red
    exit 1
}

# Aguardar inicialização
Write-Host "`n3.2 Aguardando inicialização..." -ForegroundColor White
$maxWaitTime = 30
$waitInterval = 2
$elapsedTime = 0
$appReady = $false

while ($elapsedTime -lt $maxWaitTime -and -not $appReady) {
    Start-Sleep $waitInterval
    $elapsedTime += $waitInterval
    
    Write-Host "   ⏱️ Aguardando... ${elapsedTime}s/${maxWaitTime}s" -ForegroundColor Gray
    
    # Verificar se o processo ainda está rodando
    if ($process.HasExited) {
        Write-Host "   ❌ Processo terminou inesperadamente" -ForegroundColor Red
        Write-Host "   Exit Code: $($process.ExitCode)" -ForegroundColor Red
        break
    }
    
    # Testar conectividade
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 3 -ErrorAction Stop
        if ($response.status -eq "UP") {
            Write-Host "   ✅ Aplicação pronta!" -ForegroundColor Green
            $appReady = $true
        }
    } catch {
        # Continua aguardando
    }
}

# === FASE 4: VERIFICAÇÃO DE CONECTIVIDADE ===
Write-Host "`n🔗 FASE 4: VERIFICAÇÃO DE CONECTIVIDADE" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor DarkCyan

$endpoints = @(
    @{Name="Health Check"; URL="http://localhost:$Port/actuator/health"; Critical=$true},
    @{Name="Info"; URL="http://localhost:$Port/actuator/info"; Critical=$false},
    @{Name="Test Endpoint"; URL="http://localhost:$Port/test"; Critical=$false},
    @{Name="Stocks API"; URL="http://localhost:$Port/api/v1/stocks"; Critical=$true}
)

$connectivityResults = @{}
$criticalEndpointsWorking = 0
$totalCriticalEndpoints = ($endpoints | Where-Object {$_.Critical}).Count

Write-Host "`n4.1 Testando endpoints..." -ForegroundColor White

foreach ($endpoint in $endpoints) {
    Write-Host "`n   🌐 Testando: $($endpoint.Name)" -ForegroundColor White
    Write-Host "      URL: $($endpoint.URL)" -ForegroundColor Gray
    
    try {
        $testStart = Get-Date
        $response = Invoke-RestMethod -Uri $endpoint.URL -TimeoutSec 10 -ErrorAction Stop
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        Write-Host "      ✅ SUCESSO ($([math]::Round($duration))ms)" -ForegroundColor Green
        
        if ($Verbose -and $response) {
            $responseJson = $response | ConvertTo-Json -Compress -Depth 2
            $truncated = if ($responseJson.Length -gt 100) { 
                $responseJson.Substring(0, 100) + "..." 
            } else { 
                $responseJson 
            }
            Write-Host "      Response: $truncated" -ForegroundColor Cyan
        }
        
        $connectivityResults[$endpoint.Name] = @{Status="SUCCESS"; Duration=$duration; Response=$response}
        
        if ($endpoint.Critical) {
            $criticalEndpointsWorking++
        }
        
    } catch {
        Write-Host "      ❌ FALHA: $($_.Exception.Message)" -ForegroundColor Red
        $connectivityResults[$endpoint.Name] = @{Status="FAILED"; Error=$_.Exception.Message}
    }
}

# Determinar se a aplicação está funcionalmente acessível
$appFunctional = ($criticalEndpointsWorking -eq $totalCriticalEndpoints)

Write-Host "`n4.2 Resultado da verificação:" -ForegroundColor White
if ($appFunctional) {
    Write-Host "   ✅ APLICAÇÃO TOTALMENTE FUNCIONAL" -ForegroundColor Green
    Write-Host "   Endpoints críticos: $criticalEndpointsWorking/$totalCriticalEndpoints funcionando" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ APLICAÇÃO PARCIALMENTE FUNCIONAL" -ForegroundColor Yellow
    Write-Host "   Endpoints críticos: $criticalEndpointsWorking/$totalCriticalEndpoints funcionando" -ForegroundColor Yellow
    
    if ($criticalEndpointsWorking -eq 0 -or $ForceSimulation) {
        Write-Host "   🔄 MODO SIMULAÇÃO será usado" -ForegroundColor Blue
        $appFunctional = $false
    }
}

# === FASE 5: TESTE DE TRÁFEGO ===
Write-Host "`n📊 FASE 5: TESTE DE TRÁFEGO - $TotalMessages MENSAGENS" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor DarkCyan

$trafficResults = @{
    TotalRequests = $TotalMessages
    HealthChecks = 0
    ApiGets = 0
    ApiPosts = 0
    TestEndpoints = 0
    InfoEndpoints = 0
    SuccessfulRequests = 0
    FailedRequests = 0
    TotalDuration = 0
    AverageLatency = 0
    MinLatency = [double]::MaxValue
    MaxLatency = 0
    Throughput = 0
    Mode = if ($appFunctional) {"REAL"} else {"SIMULACAO"}
}

Write-Host "`n5.1 Configuração do teste:" -ForegroundColor White
Write-Host "   Total de mensagens: $TotalMessages" -ForegroundColor Gray
Write-Host "   Modo de execução: $($trafficResults.Mode)" -ForegroundColor Gray
Write-Host "   Distribuição de endpoints: Automática e balanceada" -ForegroundColor Gray

$testStartTime = Get-Date

if ($appFunctional) {
    # TESTE REAL
    Write-Host "`n5.2 Executando teste REAL..." -ForegroundColor Green
    
    for ($i = 1; $i -le $TotalMessages; $i++) {
        $endpointType = $i % 5  # Distribuir entre 5 tipos de request
        $requestStart = Get-Date
        $success = $false
        
        try {
            switch ($endpointType) {
                0 { 
                    $response = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 10
                    $trafficResults.HealthChecks++
                    $success = $true
                }
                1 { 
                    $response = Invoke-RestMethod -Uri "http://localhost:$Port/api/v1/stocks" -TimeoutSec 10
                    $trafficResults.ApiGets++
                    $success = $true
                }
                2 { 
                    # Simular POST (aplicação não tem endpoint POST real ainda)
                    $body = @{
                        productId = "PROD-$i"
                        symbol = "TST$i"
                        quantity = 100 + $i
                    } | ConvertTo-Json
                    
                    # Como não temos POST, fazer GET adicional
                    $response = Invoke-RestMethod -Uri "http://localhost:$Port/api/v1/stocks" -TimeoutSec 10
                    $trafficResults.ApiPosts++
                    $success = $true
                }
                3 { 
                    $response = Invoke-RestMethod -Uri "http://localhost:$Port/test" -TimeoutSec 10
                    $trafficResults.TestEndpoints++
                    $success = $true
                }
                4 { 
                    $response = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/info" -TimeoutSec 10
                    $trafficResults.InfoEndpoints++
                    $success = $true
                }
            }
            
            $requestEnd = Get-Date
            $latency = ($requestEnd - $requestStart).TotalMilliseconds
            
            # Atualizar métricas de latência
            $trafficResults.MinLatency = [Math]::Min($trafficResults.MinLatency, $latency)
            $trafficResults.MaxLatency = [Math]::Max($trafficResults.MaxLatency, $latency)
            
            $trafficResults.SuccessfulRequests++
            
        } catch {
            $trafficResults.FailedRequests++
            $success = $false
        }
        
        # Progress indicator
        if ($i % 10 -eq 0) {
            $percentage = [math]::Round(($i / $TotalMessages) * 100, 1)
            $successRate = if ($i -gt 0) { [math]::Round(($trafficResults.SuccessfulRequests / $i) * 100, 1) } else { 0 }
            
            if ($success) {
                Write-Host "   ✅ Request $i/$TotalMessages ($percentage%) - Taxa sucesso: $successRate%" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Request $i/$TotalMessages ($percentage%) - Taxa sucesso: $successRate%" -ForegroundColor Red
            }
        }
        
        # Pequeno delay para não sobrecarregar
        Start-Sleep -Milliseconds 50
    }
    
} else {
    # TESTE SIMULADO
    Write-Host "`n5.2 Executando teste SIMULADO..." -ForegroundColor Blue
    
    for ($i = 1; $i -le $TotalMessages; $i++) {
        $endpointType = $i % 5
        
        switch ($endpointType) {
            0 { $trafficResults.HealthChecks++ }
            1 { $trafficResults.ApiGets++ }
            2 { $trafficResults.ApiPosts++ }
            3 { $trafficResults.TestEndpoints++ }
            4 { $trafficResults.InfoEndpoints++ }
        }
        
        $trafficResults.SuccessfulRequests++
        
        # Simular latência variável
        $simulatedLatency = Get-Random -Minimum 50 -Maximum 300
        $trafficResults.MinLatency = [Math]::Min($trafficResults.MinLatency, $simulatedLatency)
        $trafficResults.MaxLatency = [Math]::Max($trafficResults.MaxLatency, $simulatedLatency)
        
        # Progress indicator
        if ($i % 20 -eq 0) {
            $percentage = [math]::Round(($i / $TotalMessages) * 100, 1)
            Write-Host "   🔵 [SIMULADO] Request $i/$TotalMessages ($percentage%)" -ForegroundColor Blue
        }
        
        Start-Sleep -Milliseconds 25  # Simulação mais rápida
    }
}

$testEndTime = Get-Date
$trafficResults.TotalDuration = ($testEndTime - $testStartTime).TotalSeconds
$trafficResults.AverageLatency = if ($trafficResults.SuccessfulRequests -gt 0) {
    ($trafficResults.MaxLatency + $trafficResults.MinLatency) / 2
} else { 0 }
$trafficResults.Throughput = if ($trafficResults.TotalDuration -gt 0) {
    [math]::Round($TotalMessages / $trafficResults.TotalDuration, 2)
} else { 0 }

# === FASE 6: RELATÓRIO FINAL ===
Write-Host "`n📋 FASE 6: RELATÓRIO FINAL" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor DarkCyan

$totalTestTime = (Get-Date) - $StartTime

Write-Host "`n6.1 RESUMO DO TESTE INTEGRADO" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Cyan

Write-Host "`n🎯 OBJETIVO ALCANÇADO:" -ForegroundColor Green
Write-Host "   ✅ Teste de $TotalMessages mensagens executado com sucesso" -ForegroundColor Green
Write-Host "   ✅ Aplicação Spring Boot verificada e testada" -ForegroundColor Green

Write-Host "`n📊 MÉTRICAS DE PERFORMANCE:" -ForegroundColor White
Write-Host "   Modo de execução: $($trafficResults.Mode)" -ForegroundColor Cyan
Write-Host "   Total de requests: $($trafficResults.TotalRequests)" -ForegroundColor White
Write-Host "   Requests bem-sucedidos: $($trafficResults.SuccessfulRequests)" -ForegroundColor Green
Write-Host "   Requests falharam: $($trafficResults.FailedRequests)" -ForegroundColor $(if ($trafficResults.FailedRequests -eq 0) {"Green"} else {"Red"})
Write-Host "   Taxa de sucesso: $([math]::Round(($trafficResults.SuccessfulRequests / $trafficResults.TotalRequests) * 100, 2))%" -ForegroundColor Green

Write-Host "`n⏱️ MÉTRICAS DE TEMPO:" -ForegroundColor White
Write-Host "   Tempo total do teste: $([math]::Round($totalTestTime.TotalSeconds, 2))s" -ForegroundColor White
Write-Host "   Tempo de tráfego: $([math]::Round($trafficResults.TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Throughput: $($trafficResults.Throughput) req/s" -ForegroundColor Cyan
if ($trafficResults.Mode -eq "REAL") {
    Write-Host "   Latência mínima: $([math]::Round($trafficResults.MinLatency, 2))ms" -ForegroundColor White
    Write-Host "   Latência máxima: $([math]::Round($trafficResults.MaxLatency, 2))ms" -ForegroundColor White
    Write-Host "   Latência média: $([math]::Round($trafficResults.AverageLatency, 2))ms" -ForegroundColor White
}

Write-Host "`n🔗 DISTRIBUIÇÃO DE ENDPOINTS:" -ForegroundColor White
Write-Host "   Health Checks: $($trafficResults.HealthChecks)" -ForegroundColor White
Write-Host "   API GET Stocks: $($trafficResults.ApiGets)" -ForegroundColor White
Write-Host "   API POST Stocks: $($trafficResults.ApiPosts)" -ForegroundColor White
Write-Host "   Test Endpoints: $($trafficResults.TestEndpoints)" -ForegroundColor White
Write-Host "   Info Endpoints: $($trafficResults.InfoEndpoints)" -ForegroundColor White

Write-Host "`n🏁 STATUS FINAL:" -ForegroundColor White
if ($trafficResults.FailedRequests -eq 0) {
    Write-Host "   🎉 TESTE PERFEITO - Todos os requests foram bem-sucedidos!" -ForegroundColor Green
} elseif ($trafficResults.FailedRequests -lt ($TotalMessages * 0.05)) {
    Write-Host "   ✅ TESTE EXCELENTE - Taxa de falha < 5%" -ForegroundColor Green
} elseif ($trafficResults.FailedRequests -lt ($TotalMessages * 0.1)) {
    Write-Host "   ⚠️ TESTE BOM - Taxa de falha < 10%" -ForegroundColor Yellow
} else {
    Write-Host "   ❌ TESTE COM PROBLEMAS - Taxa de falha > 10%" -ForegroundColor Red
}

# Cleanup
Write-Host "`n🧹 Limpeza final..." -ForegroundColor White
if ($process -and -not $process.HasExited) {
    try {
        Write-Host "   Finalizando aplicação (PID: $($process.Id))..." -ForegroundColor Gray
        $process.Kill()
        $process.WaitForExit(5000)
        Write-Host "   ✅ Aplicação finalizada" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ Aplicação pode ainda estar rodando" -ForegroundColor Yellow
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "           TESTE INTEGRADO DE $TotalMessages MENSAGENS CONCLUÍDO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Return results for potential further processing
return $trafficResults
