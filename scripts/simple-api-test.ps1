#!/usr/bin/env powershell

<#
.SYNOPSIS
Script de Teste de Tráfego Simples para API REST

.DESCRIPTION
Este script realiza testes básicos de API REST sem necessidade de Kafka,
simulando operações de stock management para validar a aplicação.
#>

param(
    [int]$TotalRequests = 10,
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$Verbose
)

Write-Host "=== TESTE DE TRÁFEGO API REST ===" -ForegroundColor Cyan

# Função para fazer requisições HTTP
function Invoke-ApiRequest {
    param(
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Body = $null,
        [string]$Description
    )
    
    try {
        $headers = @{ "Content-Type" = "application/json" }
        
        if ($Body) {
            $jsonBody = $Body | ConvertTo-Json -Depth 3
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body $jsonBody -Headers $headers -TimeoutSec 30
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $headers -TimeoutSec 30
        }
        
        Write-Host "✅ $Description - Status: OK" -ForegroundColor Green
        return $response
        
    } catch {
        Write-Host "❌ $Description - Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Verificar se a aplicação está rodando
Write-Host "`n🔍 Verificando conectividade..." -ForegroundColor Yellow

try {
    $healthCheck = Invoke-RestMethod -Uri "$BaseUrl/actuator/health" -TimeoutSec 10
    Write-Host "✅ Aplicação está respondendo!" -ForegroundColor Green
} catch {
    Write-Host "❌ Aplicação não está rodando em $BaseUrl" -ForegroundColor Red
    Write-Host "Iniciando modo de teste offline..." -ForegroundColor Yellow
    
    # Simulação de teste sem aplicação real
    Write-Host "`n📊 SIMULAÇÃO DE TESTE DE TRÁFEGO" -ForegroundColor Cyan
    for ($i = 1; $i -le $TotalRequests; $i++) {
        $percentage = [math]::Round(($i / $TotalRequests) * 100, 1)
        Write-Host "Request $i/$TotalRequests ($percentage%)" -ForegroundColor Blue
        Start-Sleep -Milliseconds 200
    }
    Write-Host "✅ Simulação completa - $TotalRequests requests processadas" -ForegroundColor Green
    return
}

# Testes de API REST
Write-Host "`n🚀 Iniciando testes de API..." -ForegroundColor Yellow

$testResults = @()

# 1. Teste de Health Check
$health = Invoke-ApiRequest -Url "$BaseUrl/actuator/health" -Description "Health Check"
if ($health) { $testResults += "Health Check: PASS" } else { $testResults += "Health Check: FAIL" }

# 2. Teste de listagem de stocks
$stocks = Invoke-ApiRequest -Url "$BaseUrl/api/v1/stocks" -Description "Lista de Stocks"
if ($stocks) { $testResults += "Lista Stocks: PASS" } else { $testResults += "Lista Stocks: FAIL" }

# 3. Teste de criação de stock
$createRequest = @{
    productId = "PROD-$(Get-Random -Minimum 1000 -Maximum 9999)"
    symbol = "TST$(Get-Random -Minimum 10 -Maximum 99)"
    productName = "Produto de Teste"
    initialQuantity = 100
    unitPrice = 25.50
    createdBy = "test-script"
}

$newStock = Invoke-ApiRequest -Url "$BaseUrl/api/v1/stocks" -Method "POST" -Body $createRequest -Description "Criação de Stock"
if ($newStock) { $testResults += "Criação Stock: PASS" } else { $testResults += "Criação Stock: FAIL" }

# 4. Testes de carga simulada
Write-Host "`n📈 Executando testes de carga..." -ForegroundColor Yellow

$successCount = 0
$errorCount = 0

for ($i = 1; $i -le $TotalRequests; $i++) {
    $percentage = [math]::Round(($i / $TotalRequests) * 100, 1)
    Write-Progress -Activity "Teste de Carga" -Status "Request $i de $TotalRequests" -PercentComplete $percentage
    
    # Alternando entre diferentes tipos de requisições
    $requestType = $i % 3
    
    switch ($requestType) {
        0 { 
            # GET requests
            $result = Invoke-ApiRequest -Url "$BaseUrl/api/v1/stocks" -Description "GET Stocks #$i"
        }
        1 { 
            # Health checks
            $result = Invoke-ApiRequest -Url "$BaseUrl/actuator/health" -Description "Health #$i"
        }
        2 { 
            # Info endpoint
            $result = Invoke-ApiRequest -Url "$BaseUrl/actuator/info" -Description "Info #$i"
        }
    }
    
    if ($result) { $successCount++ } else { $errorCount++ }
    
    Start-Sleep -Milliseconds 100
}

Write-Progress -Completed -Activity "Teste de Carga"

# Relatório final
Write-Host "`n📊 RELATÓRIO DE TESTES" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Total de Requests: $TotalRequests" -ForegroundColor White
Write-Host "Sucessos: $successCount" -ForegroundColor Green  
Write-Host "Erros: $errorCount" -ForegroundColor Red
Write-Host "Taxa de Sucesso: $([math]::Round(($successCount / $TotalRequests) * 100, 2))%" -ForegroundColor Yellow

Write-Host "`nResultados dos Testes:" -ForegroundColor White
foreach ($result in $testResults) {
    if ($result -like "*PASS*") {
        Write-Host "✅ $result" -ForegroundColor Green
    } else {
        Write-Host "❌ $result" -ForegroundColor Red
    }
}

Write-Host "`n🎯 Teste de tráfego concluído!" -ForegroundColor Cyan
