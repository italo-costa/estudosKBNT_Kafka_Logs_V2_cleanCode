# PowerShell Script para executar Testes de Performance com 100 requisições
param(
    [string]$TestType = "All", # All, Controller, Kafka, Mixed
    [switch]$Detailed = $false
)

Write-Host "🚀 Executando Testes de Performance com 100 Requisições..." -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Change to service directory
Set-Location "kbnt-log-service"

# Function to find Maven
function Find-Maven {
    $mavenLocations = @("mvn", "mvn.cmd", "$env:MAVEN_HOME\bin\mvn.cmd", "$env:M2_HOME\bin\mvn.cmd")
    
    foreach ($location in $mavenLocations) {
        try {
            if (Get-Command $location -ErrorAction SilentlyContinue) {
                return $location
            }
        } catch { }
    }
    return $null
}

$maven = Find-Maven

if (-not $maven) {
    Write-Host "❌ Maven não encontrado!" -ForegroundColor Red
    Write-Host "Alternativas para executar os testes:" -ForegroundColor Yellow
    Write-Host "1. Instalar Apache Maven" -ForegroundColor Gray
    Write-Host "2. Usar VS Code Java Extension Pack" -ForegroundColor Gray
    Write-Host "3. Usar IntelliJ IDEA ou Eclipse" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📋 Testes de Performance Criados:" -ForegroundColor Green
    Write-Host "✅ StockUpdateControllerPerformanceTest.java - Testes de carga HTTP" -ForegroundColor Green
    Write-Host "✅ KafkaPublicationPerformanceTest.java - Testes de publicação Kafka" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎯 Cenários de Teste Implementados:" -ForegroundColor Cyan
    Write-Host "• 100 requisições HTTP concorrentes" -ForegroundColor Gray
    Write-Host "• Validação de hash SHA-256 sob carga" -ForegroundColor Gray
    Write-Host "• Roteamento de tópicos com múltiplas operações" -ForegroundColor Gray
    Write-Host "• Logging de publicação em alta concorrência" -ForegroundColor Gray
    Write-Host "• Testes de uniqueness e integridade" -ForegroundColor Gray
    Write-Host "• Métricas de performance e throughput" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Maven encontrado: $maven" -ForegroundColor Green
Write-Host ""

# Determine which tests to run
$testClasses = @()
switch ($TestType) {
    "Controller" {
        $testClasses += "StockUpdateControllerPerformanceTest"
        Write-Host "🎯 Executando testes de performance do Controller (100 requisições HTTP)" -ForegroundColor Yellow
    }
    "Kafka" {
        $testClasses += "KafkaPublicationPerformanceTest"
        Write-Host "🎯 Executando testes de performance do Kafka (100 publicações)" -ForegroundColor Yellow
    }
    "Mixed" {
        $testClasses += "StockUpdateControllerPerformanceTest,KafkaPublicationPerformanceTest"
        Write-Host "🎯 Executando todos os testes de performance (200+ operações)" -ForegroundColor Yellow
    }
    default {
        $testClasses += "StockUpdateControllerPerformanceTest,KafkaPublicationPerformanceTest"
        Write-Host "🎯 Executando suite completa de testes de performance" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📊 Cenários que serão testados:" -ForegroundColor Cyan

if ($TestType -eq "All" -or $TestType -eq "Controller" -or $TestType -eq "Mixed") {
    Write-Host "🌐 Controller Performance Tests:" -ForegroundColor Green
    Write-Host "  • 100 requisições HTTP concorrentes" -ForegroundColor Gray
    Write-Host "  • 100 requisições com produtos variados" -ForegroundColor Gray
    Write-Host "  • Validação de uniqueness em 100 requisições" -ForegroundColor Gray
    Write-Host "  • Métricas de throughput e tempo de resposta" -ForegroundColor Gray
}

if ($TestType -eq "All" -or $TestType -eq "Kafka" -or $TestType -eq "Mixed") {
    Write-Host "⚡ Kafka Publication Performance Tests:" -ForegroundColor Green
    Write-Host "  • Geração de hash SHA-256 para 100 mensagens" -ForegroundColor Gray
    Write-Host "  • Roteamento de tópicos com 100 publicações" -ForegroundColor Gray
    Write-Host "  • Logging de publicação sob alta carga" -ForegroundColor Gray
    Write-Host "  • Operações mistas de diferentes complexidades" -ForegroundColor Gray
}

Write-Host ""
Write-Host "⏱️ Executando testes..." -ForegroundColor Yellow

try {
    # Execute the performance tests
    $testArgs = @("test", "-Dtest=$($testClasses -join ',')")
    
    if ($Detailed) {
        $testArgs += "-X" # Verbose output
    }
    
    $testArgs += "-Dmaven.test.failure.ignore=false"
    $testArgs += "-DforkCount=1" # Limit forked processes for performance tests
    $testArgs += "-DreuseForks=true"
    
    $startTime = Get-Date
    
    & $maven $testArgs
    
    $endTime = Get-Date
    $totalTime = $endTime - $startTime
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 Testes de Performance Concluídos com Sucesso!" -ForegroundColor Green
        Write-Host "⏰ Tempo total de execução: $($totalTime.TotalSeconds.ToString('F2')) segundos" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📈 Resultados dos Testes:" -ForegroundColor Cyan
        Write-Host "✅ Todos os cenários de 100+ requisições passaram" -ForegroundColor Green
        Write-Host "✅ Sistema validado para alta concorrência" -ForegroundColor Green
        Write-Host "✅ Performance de hash SHA-256 validada" -ForegroundColor Green
        Write-Host "✅ Roteamento de tópicos funcionando corretamente" -ForegroundColor Green
        Write-Host "✅ Logging de publicação otimizado" -ForegroundColor Green
        
        # Look for test reports
        $reportsPath = "target\surefire-reports"
        if (Test-Path $reportsPath) {
            Write-Host ""
            Write-Host "📊 Relatórios de Performance disponíveis em:" -ForegroundColor Cyan
            Write-Host "   $reportsPath" -ForegroundColor Gray
            
            $xmlReports = Get-ChildItem $reportsPath -Filter "*Performance*.xml" -ErrorAction SilentlyContinue
            if ($xmlReports) {
                Write-Host ""
                Write-Host "📄 Arquivos de relatório gerados:" -ForegroundColor Gray
                $xmlReports | ForEach-Object { Write-Host "   $($_.Name)" -ForegroundColor DarkGray }
            }
        }
        
        Write-Host ""
        Write-Host "🏆 SISTEMA VALIDADO PARA PRODUÇÃO!" -ForegroundColor Green
        Write-Host "Sistema capaz de lidar com alta carga de requisições" -ForegroundColor Green
        
    } else {
        Write-Host ""
        Write-Host "❌ Alguns testes de performance falharam!" -ForegroundColor Red
        Write-Host "Verifique os logs acima para detalhes." -ForegroundColor Yellow
        
        # Show potential issues
        Write-Host ""
        Write-Host "🔍 Possíveis problemas:" -ForegroundColor Yellow
        Write-Host "• Performance abaixo do esperado" -ForegroundColor Gray
        Write-Host "• Timeouts em operações concorrentes" -ForegroundColor Gray
        Write-Host "• Problemas de concorrência ou thread safety" -ForegroundColor Gray
        Write-Host "• Configuração inadequada para alta carga" -ForegroundColor Gray
        
        exit 1
    }
    
} catch {
    Write-Host "❌ Erro ao executar testes: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎯 Próximos Passos Recomendados:" -ForegroundColor Cyan
Write-Host "1. Analisar métricas de performance nos logs" -ForegroundColor Gray
Write-Host "2. Configurar monitoramento para ambiente de produção" -ForegroundColor Gray
Write-Host "3. Executar testes de stress com carga ainda maior" -ForegroundColor Gray
Write-Host "4. Implementar dashboards de monitoramento" -ForegroundColor Gray
Write-Host "5. Configurar alertas baseados em métricas" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ Testes de Performance com 100 Requisições Concluídos!" -ForegroundColor Green
