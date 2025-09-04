# WORKFLOW DE VALIDACAO - VIRTUAL STOCK SERVICE
# Inicializacao + Testes + 300 Mensagens + Analise
# Versao Otimizada para Ambiente Local (Zero Custos)

param(
    [int]$Messages = 300,
    [int]$Port = 8080,
    [switch]$FullAnalysis,
    [switch]$SaveReports,
    [string]$OutputDir = "C:\workspace\estudosKBNT_Kafka_Logs\reports"
)

$WorkflowStart = Get-Date
$Results = @{
    WorkflowVersion = "1.0.0"
    ExecutionId = (Get-Date).ToString("yyyyMMdd-HHmmss")
    Environment = "Local-Development"
    Phases = @{}
    Metrics = @{}
    Recommendations = @()
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "           WORKFLOW DE VALIDACAO COMPLETO - $Messages MENSAGENS" -ForegroundColor Cyan
Write-Host "           Ambiente: Local | Custos: Zero | Performance: Otimizada" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# === FASE 1: VALIDACAO DE PREREQUISITOS ===
Write-Host "`n[FASE 1] VALIDACAO DE PREREQUISITOS" -ForegroundColor Yellow
$phase1Start = Get-Date

$prerequisites = @{
    JavaPath = "$env:JAVA_HOME\bin\java.exe"
    MavenPath = "C:\maven\apache-maven-3.9.4\bin\mvn.cmd"
    JarPath = "C:\workspace\estudosKBNT_Kafka_Logs\simple-app\target\simple-stock-api-1.0.0.jar"
    WorkspaceRoot = "C:\workspace\estudosKBNT_Kafka_Logs"
}

$prereqResults = @{}

Write-Host "   Verificando ambiente Java..." -ForegroundColor White
if (-not $env:JAVA_HOME) {
    $env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
}

if (Test-Path $prerequisites.JavaPath) {
    $javaVersion = & $prerequisites.JavaPath -version 2>&1 | Select-Object -First 1
    Write-Host "      [OK] Java: $javaVersion" -ForegroundColor Green
    $prereqResults.Java = "OK"
} else {
    Write-Host "      [ERRO] Java nao encontrado" -ForegroundColor Red
    $prereqResults.Java = "FAILED"
}

Write-Host "   Verificando Maven..." -ForegroundColor White
if (Test-Path $prerequisites.MavenPath) {
    try {
        $mavenVersion = & $prerequisites.MavenPath --version 2>&1 | Select-Object -First 1
        Write-Host "      [OK] Maven: $mavenVersion" -ForegroundColor Green
        $prereqResults.Maven = "OK"
    } catch {
        Write-Host "      [ERRO] Maven erro: $($_.Exception.Message)" -ForegroundColor Red
        $prereqResults.Maven = "FAILED"
    }
} else {
    Write-Host "      [ERRO] Maven nao encontrado" -ForegroundColor Red
    $prereqResults.Maven = "FAILED"
}

Write-Host "   Verificando aplicacao compilada..." -ForegroundColor White
if (Test-Path $prerequisites.JarPath) {
    $jarSize = [math]::Round((Get-Item $prerequisites.JarPath).Length / 1MB, 2)
    Write-Host "      [OK] JAR: ${jarSize}MB disponivel" -ForegroundColor Green
    $prereqResults.Application = "OK"
} else {
    Write-Host "      [AVISO] JAR nao encontrado - tentando compilar..." -ForegroundColor Yellow
    
    try {
        Set-Location "C:\workspace\estudosKBNT_Kafka_Logs\simple-app"
        $env:PATH = "C:\maven\apache-maven-3.9.4\bin;$env:PATH"
        & $prerequisites.MavenPath clean package -DskipTests -q
        
        if (Test-Path $prerequisites.JarPath) {
            Write-Host "      [OK] Compilacao bem-sucedida" -ForegroundColor Green
            $prereqResults.Application = "COMPILED"
        } else {
            Write-Host "      [ERRO] Falha na compilacao" -ForegroundColor Red
            $prereqResults.Application = "FAILED"
        }
    } catch {
        Write-Host "      [ERRO] Erro na compilacao: $($_.Exception.Message)" -ForegroundColor Red
        $prereqResults.Application = "FAILED"
    }
}

$Results.Phases.Prerequisites = @{
    Duration = ((Get-Date) - $phase1Start).TotalSeconds
    Results = $prereqResults
    Status = if ($prereqResults.Values -contains "FAILED") { "FAILED" } else { "PASSED" }
}

if ($Results.Phases.Prerequisites.Status -eq "FAILED") {
    Write-Host "`n[ERRO] PREREQUISITOS FALHARAM - Parando workflow" -ForegroundColor Red
    exit 1
}

# === FASE 2: OTIMIZACAO DE RECURSOS (ZERO CUSTOS) ===
Write-Host "`n[FASE 2] OTIMIZACAO DE RECURSOS (ZERO CUSTOS)" -ForegroundColor Yellow
$phase2Start = Get-Date

Write-Host "   Configurando ambiente para eficiencia maxima..." -ForegroundColor White

# Limpar processos anteriores para economizar recursos
$cleanupResults = @{
    JavaProcesses = 0
    PortsFreed = 0
    MemoryFreed = 0
}

Get-Process -Name "java" -ErrorAction SilentlyContinue | ForEach-Object {
    $cleanupResults.JavaProcesses++
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}

$portsInUse = netstat -ano | findstr ":$Port"
if ($portsInUse) {
    $processes = netstat -ano | findstr ":$Port" | ForEach-Object { 
        if ($_ -match '\s+(\d+)$') { 
            $cleanupResults.PortsFreed++
            taskkill /PID $matches[1] /F 2>$null
        } 
    }
}

# Otimizacoes JVM para ambiente local (baixo consumo de memoria)
$jvmOptimizations = @(
    "-Xms128m",              # Heap inicial reduzido
    "-Xmx256m",              # Heap maximo otimizado para local
    "-XX:+UseG1GC",          # Garbage Collector eficiente
    "-XX:MaxGCPauseMillis=100", # Pausas curtas de GC
    "-Dspring.jpa.hibernate.ddl-auto=none", # Sem DDL automatico
    "-Dlogging.level.org.springframework=WARN" # Log reduzido
)

Write-Host "      [OK] Processos limpos: $($cleanupResults.JavaProcesses) Java processes" -ForegroundColor Green
Write-Host "      [OK] Portas liberadas: $($cleanupResults.PortsFreed)" -ForegroundColor Green
Write-Host "      [OK] JVM otimizada para baixo consumo" -ForegroundColor Green

$Results.Phases.ResourceOptimization = @{
    Duration = ((Get-Date) - $phase2Start).TotalSeconds
    Optimizations = $cleanupResults
    JVMSettings = $jvmOptimizations
    Status = "OPTIMIZED"
}

# === FASE 3: INICIALIZACAO CONTROLADA ===
Write-Host "`n[FASE 3] INICIALIZACAO CONTROLADA DA APLICACAO" -ForegroundColor Yellow
$phase3Start = Get-Date

Write-Host "   Iniciando aplicacao com configuracoes otimizadas..." -ForegroundColor White

$appConfig = @(
    "-Dserver.address=127.0.0.1",  # Apenas localhost para economia
    "-Dserver.port=$Port",
    "-Djava.net.preferIPv4Stack=true",
    "-Dspring.profiles.active=local", # Profile especifico para local
    "-Dmanagement.endpoints.web.exposure.include=health,info"
) + $jvmOptimizations

$processArgs = ($appConfig + @("-jar", "`"$($prerequisites.JarPath)`"")) -join " "

Set-Location "C:\workspace\estudosKBNT_Kafka_Logs\simple-app"
$process = Start-Process -FilePath $prerequisites.JavaPath -ArgumentList $processArgs -PassThru -WindowStyle Hidden

if (-not $process) {
    Write-Host "   [ERRO] Falha ao iniciar aplicacao" -ForegroundColor Red
    exit 1
}

Write-Host "   [OK] Aplicacao iniciada - PID: $($process.Id)" -ForegroundColor Green

# Verificacao de inicializacao com timeout otimizado
$initTimeout = 45 # Reduzido para ambiente local
$initAttempt = 0
$appReady = $false

Write-Host "   Aguardando inicializacao (timeout: ${initTimeout}s)..." -ForegroundColor White

do {
    $initAttempt++
    Start-Sleep 1
    
    if ($initAttempt % 5 -eq 0) {
        Write-Host "      [INFO] Tentativa $initAttempt/${initTimeout}..." -ForegroundColor Gray
    }
    
    if ($process.HasExited) {
        Write-Host "   [ERRO] Processo terminou - Exit Code: $($process.ExitCode)" -ForegroundColor Red
        exit 1
    }
    
    try {
        $healthResponse = Invoke-RestMethod -Uri "http://localhost:$Port/actuator/health" -TimeoutSec 3
        if ($healthResponse.status -eq "UP") {
            $appReady = $true
            Write-Host "   [OK] Aplicacao pronta em ${initAttempt}s!" -ForegroundColor Green
        }
    } catch {
        # Continua tentando
    }
    
} while (-not $appReady -and $initAttempt -lt $initTimeout)

if (-not $appReady) {
    Write-Host "   [ERRO] Timeout na inicializacao" -ForegroundColor Red
    $process.Kill()
    exit 1
}

$Results.Phases.Initialization = @{
    Duration = ((Get-Date) - $phase3Start).TotalSeconds
    InitializationTime = $initAttempt
    ProcessId = $process.Id
    Configuration = $appConfig
    Status = "READY"
}

# === FASE 4: VALIDACAO DE ENDPOINTS (CUSTO ZERO) ===
Write-Host "`n[FASE 4] VALIDACAO DE ENDPOINTS" -ForegroundColor Yellow
$phase4Start = Get-Date

$endpoints = @(
    @{Name="Health"; URL="http://localhost:$Port/actuator/health"; Critical=$true},
    @{Name="Info"; URL="http://localhost:$Port/actuator/info"; Critical=$false},
    @{Name="Stocks"; URL="http://localhost:$Port/api/v1/stocks"; Critical=$true},
    @{Name="Test"; URL="http://localhost:$Port/test"; Critical=$false}
)

$endpointResults = @{}

foreach ($endpoint in $endpoints) {
    try {
        $testStart = Get-Date
        $response = Invoke-RestMethod -Uri $endpoint.URL -TimeoutSec 5
        $testEnd = Get-Date
        $latency = [math]::Round(($testEnd - $testStart).TotalMilliseconds)
        
        Write-Host "      [OK] $($endpoint.Name): ${latency}ms" -ForegroundColor Green
        
        $endpointResults[$endpoint.Name] = @{
            Status = "OK"
            Latency = $latency
            Response = $response
        }
        
    } catch {
        Write-Host "      [ERRO] $($endpoint.Name): $($_.Exception.Message)" -ForegroundColor Red
        $endpointResults[$endpoint.Name] = @{
            Status = "FAILED"
            Error = $_.Exception.Message
        }
    }
}

$criticalEndpoints = $endpoints | Where-Object {$_.Critical}
$criticalEndpointsOK = $true
foreach ($criticalEndpoint in $criticalEndpoints) {
    if ($endpointResults[$criticalEndpoint.Name].Status -ne "OK") {
        $criticalEndpointsOK = $false
        break
    }
}

if (-not $criticalEndpointsOK) {
    Write-Host "   [ERRO] Endpoints criticos falharam" -ForegroundColor Red
    $process.Kill()
    exit 1
}

$Results.Phases.EndpointValidation = @{
    Duration = ((Get-Date) - $phase4Start).TotalSeconds
    Results = $endpointResults
    CriticalEndpointsStatus = "PASSED"
    Status = "VALIDATED"
}

# === FASE 5: TESTE DE CARGA OTIMIZADO (300 MENSAGENS) ===
Write-Host "`n[FASE 5] TESTE DE CARGA OTIMIZADO - $Messages MENSAGENS" -ForegroundColor Yellow
$phase5Start = Get-Date

$loadTestResults = @{
    TotalMessages = $Messages
    SuccessfulRequests = 0
    FailedRequests = 0
    ByEndpoint = @{}
    Latencies = @()
    StartTime = Get-Date
}

# Distribuicao inteligente de requests para maximizar cobertura
$endpointDistribution = @(
    @{Name="Health"; URL="http://localhost:$Port/actuator/health"; Weight=30}, # 30% - Monitoramento
    @{Name="Stocks"; URL="http://localhost:$Port/api/v1/stocks"; Weight=50},   # 50% - API principal
    @{Name="Test"; URL="http://localhost:$Port/test"; Weight=15},              # 15% - Diagnostico
    @{Name="Info"; URL="http://localhost:$Port/actuator/info"; Weight=5}       # 5% - Metadados
)

Write-Host "   Distribuicao otimizada de requests:" -ForegroundColor White
$endpointDistribution | ForEach-Object {
    Write-Host "      $($_.Name): $($_.Weight)%" -ForegroundColor Gray
}

Write-Host "`n   Executando teste de carga..." -ForegroundColor White

# Algoritmo de distribuicao proporcional
$requestsPerEndpoint = @{}
$endpointDistribution | ForEach-Object {
    $requestsPerEndpoint[$_.Name] = [math]::Floor($Messages * ($_.Weight / 100))
    $loadTestResults.ByEndpoint[$_.Name] = @{Success=0; Failed=0; Latencies=@()}
}

# Ajustar para garantir total exato
$totalDistributed = ($requestsPerEndpoint.Values | Measure-Object -Sum).Sum
$remaining = $Messages - $totalDistributed
$requestsPerEndpoint["Stocks"] += $remaining # Adicionar resto ao endpoint principal

$currentRequest = 0
foreach ($endpoint in $endpointDistribution) {
    $requestsForThisEndpoint = $requestsPerEndpoint[$endpoint.Name]
    
    for ($i = 1; $i -le $requestsForThisEndpoint; $i++) {
        $currentRequest++
        $requestStart = Get-Date
        
        try {
            $response = Invoke-RestMethod -Uri $endpoint.URL -TimeoutSec 10
            $requestEnd = Get-Date
            $latency = ($requestEnd - $requestStart).TotalMilliseconds
            
            $loadTestResults.SuccessfulRequests++
            $loadTestResults.ByEndpoint[$endpoint.Name].Success++
            $loadTestResults.ByEndpoint[$endpoint.Name].Latencies += $latency
            $loadTestResults.Latencies += $latency
            
        } catch {
            $loadTestResults.FailedRequests++
            $loadTestResults.ByEndpoint[$endpoint.Name].Failed++
        }
        
        # Progress eficiente (sem spam de output)
        if ($currentRequest % 50 -eq 0 -or $currentRequest -eq $Messages) {
            $percentage = [math]::Round(($currentRequest / $Messages) * 100, 1)
            $successRate = [math]::Round(($loadTestResults.SuccessfulRequests / $currentRequest) * 100, 1)
            
            if ($loadTestResults.Latencies.Count -gt 0) {
                $avgLatency = [math]::Round(($loadTestResults.Latencies | Measure-Object -Average).Average, 1)
                Write-Host "      [OK] $currentRequest/$Messages ($percentage%) | Sucesso: $successRate% | Latencia: ${avgLatency}ms" -ForegroundColor Green
            } else {
                Write-Host "      [AVISO] $currentRequest/$Messages ($percentage%) | Sucesso: $successRate%" -ForegroundColor Yellow
            }
        }
        
        # Delay minimo para nao sobrecarregar (economia de recursos)
        Start-Sleep -Milliseconds 20
    }
}

$loadTestResults.EndTime = Get-Date
$loadTestResults.TotalDuration = ($loadTestResults.EndTime - $loadTestResults.StartTime).TotalSeconds

# Calcular metricas finais
if ($loadTestResults.Latencies.Count -gt 0) {
    $latencyStats = $loadTestResults.Latencies | Measure-Object -Average -Minimum -Maximum
    $loadTestResults.AverageLatency = [math]::Round($latencyStats.Average, 2)
    $loadTestResults.MinLatency = [math]::Round($latencyStats.Minimum, 2)
    $loadTestResults.MaxLatency = [math]::Round($latencyStats.Maximum, 2)
} else {
    $loadTestResults.AverageLatency = 0
    $loadTestResults.MinLatency = 0
    $loadTestResults.MaxLatency = 0
}

$loadTestResults.Throughput = if ($loadTestResults.TotalDuration -gt 0) {
    [math]::Round($Messages / $loadTestResults.TotalDuration, 2)
} else { 0 }

$loadTestResults.SuccessRate = [math]::Round(($loadTestResults.SuccessfulRequests / $Messages) * 100, 2)

$Results.Phases.LoadTest = @{
    Duration = ((Get-Date) - $phase5Start).TotalSeconds
    Results = $loadTestResults
    Distribution = $requestsPerEndpoint
    Status = if ($loadTestResults.SuccessRate -ge 95) { "EXCELLENT" } elseif ($loadTestResults.SuccessRate -ge 90) { "GOOD" } else { "NEEDS_ATTENTION" }
}

# === FASE 6: ANALISE DE PERFORMANCE (SEM CUSTOS ADICIONAIS) ===
Write-Host "`n[FASE 6] ANALISE DE PERFORMANCE" -ForegroundColor Yellow
$phase6Start = Get-Date

$performanceAnalysis = @{
    ResourceUsage = @{}
    Bottlenecks = @()
    Optimizations = @()
    QualityScore = 0
}

# Analise de uso de recursos do processo
try {
    $appProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
    if ($appProcess) {
        $performanceAnalysis.ResourceUsage = @{
            CPUTime = [math]::Round($appProcess.TotalProcessorTime.TotalSeconds, 2)
            WorkingSet = [math]::Round($appProcess.WorkingSet64 / 1MB, 2)
            PeakWorkingSet = [math]::Round($appProcess.PeakWorkingSet64 / 1MB, 2)
            Threads = $appProcess.Threads.Count
        }
        
        Write-Host "   Recursos utilizados:" -ForegroundColor White
        Write-Host "      CPU Time: $($performanceAnalysis.ResourceUsage.CPUTime)s" -ForegroundColor Gray
        Write-Host "      Memoria: $($performanceAnalysis.ResourceUsage.WorkingSet)MB" -ForegroundColor Gray
        Write-Host "      Pico de memoria: $($performanceAnalysis.ResourceUsage.PeakWorkingSet)MB" -ForegroundColor Gray
        Write-Host "      Threads: $($performanceAnalysis.ResourceUsage.Threads)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   [AVISO] Nao foi possivel obter metricas de recursos" -ForegroundColor Yellow
}

# Analise de bottlenecks
if ($loadTestResults.MaxLatency -gt 1000) {
    $performanceAnalysis.Bottlenecks += "Alta latencia maxima detectada: $($loadTestResults.MaxLatency)ms"
}

if ($loadTestResults.SuccessRate -lt 95) {
    $performanceAnalysis.Bottlenecks += "Taxa de falha elevada: $($loadTestResults.FailedRequests) de $Messages requests"
}

if ($loadTestResults.Throughput -lt 10) {
    $performanceAnalysis.Bottlenecks += "Throughput baixo: $($loadTestResults.Throughput) req/s"
}

# Sugestoes de otimizacao
$performanceAnalysis.Optimizations += "JVM ja otimizada para ambiente local"
$performanceAnalysis.Optimizations += "Configuracao de rede localhost para reduzir latencia"

if ($loadTestResults.SuccessRate -eq 100) {
    $performanceAnalysis.Optimizations += "Sistema estavel - considere aumentar carga de teste"
}

# Score de qualidade (0-100)
$stabilityScore = if ($performanceAnalysis.Bottlenecks.Count -eq 0) { 100 } else { 70 }
$qualityFactors = @{
    SuccessRate = $loadTestResults.SuccessRate * 0.4          # 40% do score
    LatencyScore = [math]::Max(0, 100 - ($loadTestResults.AverageLatency / 10)) * 0.3  # 30% do score
    ThroughputScore = [math]::Min(100, $loadTestResults.Throughput * 2) * 0.2          # 20% do score
    StabilityScore = $stabilityScore * 0.1  # 10% do score
}

$performanceAnalysis.QualityScore = [math]::Round(($qualityFactors.Values | Measure-Object -Sum).Sum, 1)

$Results.Phases.PerformanceAnalysis = @{
    Duration = ((Get-Date) - $phase6Start).TotalSeconds
    Analysis = $performanceAnalysis
    QualityFactors = $qualityFactors
    Status = if ($performanceAnalysis.QualityScore -ge 90) { "EXCELLENT" } elseif ($performanceAnalysis.QualityScore -ge 75) { "GOOD" } else { "NEEDS_IMPROVEMENT" }
}

# === FASE 7: RELATORIO FINAL E LIMPEZA ===
Write-Host "`n[FASE 7] RELATORIO FINAL" -ForegroundColor Yellow

$totalWorkflowTime = (Get-Date) - $WorkflowStart
$Results.TotalDuration = $totalWorkflowTime.TotalSeconds

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "                    RELATORIO WORKFLOW COMPLETO" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

Write-Host "`n[RESUMO EXECUTIVO]:" -ForegroundColor White
Write-Host "   Execution ID: $($Results.ExecutionId)" -ForegroundColor Gray
Write-Host "   Ambiente: Local Development (Zero Custos)" -ForegroundColor Gray
Write-Host "   Duracao total: $([math]::Round($Results.TotalDuration, 2))s" -ForegroundColor Gray
Write-Host "   Mensagens testadas: $Messages" -ForegroundColor White
Write-Host "   Score de qualidade: $($performanceAnalysis.QualityScore)/100" -ForegroundColor $(if ($performanceAnalysis.QualityScore -ge 90) {"Green"} elseif ($performanceAnalysis.QualityScore -ge 75) {"Yellow"} else {"Red"})

Write-Host "`n[METRICAS DE PERFORMANCE]:" -ForegroundColor White
Write-Host "   Taxa de sucesso: $($loadTestResults.SuccessRate)%" -ForegroundColor $(if ($loadTestResults.SuccessRate -eq 100) {"Green"} else {"Yellow"})
Write-Host "   Throughput: $($loadTestResults.Throughput) req/s" -ForegroundColor Cyan
Write-Host "   Latencia media: $($loadTestResults.AverageLatency)ms" -ForegroundColor Cyan
Write-Host "   Latencia min/max: $($loadTestResults.MinLatency)ms / $($loadTestResults.MaxLatency)ms" -ForegroundColor White

Write-Host "`n[ANALISE DE RECURSOS]:" -ForegroundColor White
Write-Host "   Memoria utilizada: $($performanceAnalysis.ResourceUsage.WorkingSet)MB" -ForegroundColor White
Write-Host "   CPU Time: $($performanceAnalysis.ResourceUsage.CPUTime)s" -ForegroundColor White
Write-Host "   Threads: $($performanceAnalysis.ResourceUsage.Threads)" -ForegroundColor White

Write-Host "`n[DISTRIBUICAO DE REQUESTS]:" -ForegroundColor White
foreach ($endpoint in $endpointDistribution) {
    $success = $loadTestResults.ByEndpoint[$endpoint.Name].Success
    $failed = $loadTestResults.ByEndpoint[$endpoint.Name].Failed
    $total = $success + $failed
    $successRate = if ($total -gt 0) { [math]::Round(($success / $total) * 100, 1) } else { 0 }
    
    Write-Host "   $($endpoint.Name): $success/$total ($successRate%)" -ForegroundColor $(if ($successRate -eq 100) {"Green"} else {"Yellow"})
}

if ($performanceAnalysis.Bottlenecks.Count -gt 0) {
    Write-Host "`n[BOTTLENECKS IDENTIFICADOS]:" -ForegroundColor Yellow
    $performanceAnalysis.Bottlenecks | ForEach-Object {
        Write-Host "   - $_" -ForegroundColor Red
    }
}

Write-Host "`n[OTIMIZACOES APLICADAS]:" -ForegroundColor White
$performanceAnalysis.Optimizations | ForEach-Object {
    Write-Host "   [OK] $_" -ForegroundColor Green
}

Write-Host "`n[AVALIACAO FINAL]:" -ForegroundColor White
$finalStatus = $Results.Phases.LoadTest.Status
switch ($finalStatus) {
    "EXCELLENT" {
        Write-Host "   [EXCELENTE] Sistema performatico e estavel" -ForegroundColor Green
        Write-Host "   Recomendacao: Pronto para aumentar carga de testes" -ForegroundColor Green
    }
    "GOOD" {
        Write-Host "   [BOM] Sistema estavel com pequenas melhorias possiveis" -ForegroundColor Yellow
        Write-Host "   Recomendacao: Investigar latencias ocasionais" -ForegroundColor Yellow
    }
    "NEEDS_ATTENTION" {
        Write-Host "   [NECESSITA ATENCAO] Problemas de estabilidade detectados" -ForegroundColor Red
        Write-Host "   Recomendacao: Revisar configuracoes antes de producao" -ForegroundColor Red
    }
}

# Salvar relatorios se solicitado
if ($SaveReports) {
    Write-Host "`n[SALVANDO RELATORIOS]..." -ForegroundColor White
    
    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    $reportFile = Join-Path $OutputDir "workflow-report-$($Results.ExecutionId).json"
    $Results | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportFile -Encoding UTF8
    
    $csvFile = Join-Path $OutputDir "performance-metrics-$($Results.ExecutionId).csv"
    $metricsData = [PSCustomObject]@{
        ExecutionId = $Results.ExecutionId
        TotalMessages = $loadTestResults.TotalMessages
        SuccessRate = $loadTestResults.SuccessRate
        Throughput = $loadTestResults.Throughput
        AverageLatency = $loadTestResults.AverageLatency
        MinLatency = $loadTestResults.MinLatency
        MaxLatency = $loadTestResults.MaxLatency
        QualityScore = $performanceAnalysis.QualityScore
        MemoryUsage = $performanceAnalysis.ResourceUsage.WorkingSet
        CPUTime = $performanceAnalysis.ResourceUsage.CPUTime
    }
    $metricsData | Export-Csv -Path $csvFile -NoTypeInformation
    
    Write-Host "   [OK] Relatorio JSON: $reportFile" -ForegroundColor Green
    Write-Host "   [OK] Metricas CSV: $csvFile" -ForegroundColor Green
}

Write-Host "`n[LIMPEZA E FINALIZACAO]..." -ForegroundColor White
Write-Host "   Mantendo aplicacao rodando para analises adicionais..." -ForegroundColor Gray
Write-Host "   PID: $($process.Id) | Porta: $Port" -ForegroundColor Gray
Write-Host "   Para finalizar: taskkill /PID $($process.Id) /F" -ForegroundColor Gray

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "           WORKFLOW DE $Messages MENSAGENS CONCLUIDO COM SUCESSO" -ForegroundColor Cyan
Write-Host "           Custos: R$ 0,00 | Ambiente: Local | Score: $($performanceAnalysis.QualityScore)/100" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

return $Results
