# Script para Configurar Aplicacao para IP Especifico 172.30.221.62:8084

Write-Host "=== CONFIGURANDO APLICACAO PARA IP 172.30.221.62:8084 ===" -ForegroundColor Green

# 1. Parar containers atuais
Write-Host "1. Parando containers atuais..." -ForegroundColor Yellow
wsl -e bash -c "docker rm -f virtual-stock-stable postgres-kbnt-stable 2>/dev/null || true"

# 2. Verificar IP do WSL2
Write-Host "2. Verificando configuracao de IP..." -ForegroundColor Yellow
$wslIP = wsl -e bash -c "ip addr show eth0 | grep 'inet 172' | awk '{print `$2}' | cut -d'/' -f1"
Write-Host "IP WSL2 detectado: $wslIP" -ForegroundColor Cyan

# 3. Criar PostgreSQL
Write-Host "3. Criando PostgreSQL..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name postgres-kbnt-stable --network kbnt-stable-net -p 0.0.0.0:5433:5432 -e POSTGRES_DB=virtualstock -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -v postgres-data-stable:/var/lib/postgresql/data --restart=always postgres:15"

Start-Sleep -Seconds 10

# 4. Criar aplicacao com configuracoes especificas para IP externo
Write-Host "4. Criando aplicacao configurada para IP externo..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name virtual-stock-stable --network kbnt-stable-net -p 0.0.0.0:8084:8084 -e SPRING_PROFILES_ACTIVE=docker -e SPRING_DATASOURCE_URL='jdbc:postgresql://postgres-kbnt-stable:5432/virtualstock' -e SPRING_DATASOURCE_USERNAME=postgres -e SPRING_DATASOURCE_PASSWORD=postgres -e SERVER_ADDRESS=0.0.0.0 -e SERVER_PORT=8084 --restart=always -v /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/microservices/virtual-stock-service/target/virtual-stock-service-2.0.0.jar:/app/app.jar eclipse-temurin:17-jre java -Dserver.address=0.0.0.0 -Dserver.port=8084 -jar /app/app.jar"

# 5. Aguardar inicializacao com progresso
Write-Host "5. Aguardando inicializacao da aplicacao..." -ForegroundColor Yellow
for ($i = 1; $i -le 60; $i++) {
    Write-Progress -Activity "Inicializando aplicacao" -Status "Aguardando... ($i/60 segundos)" -PercentComplete ($i * 100 / 60)
    Start-Sleep -Seconds 1
    
    # Verificar se aplicacao terminou inicializacao
    $logs = wsl -e bash -c "docker logs virtual-stock-stable 2>&1 | grep 'Started VirtualStockApplication'"
    if ($logs) {
        Write-Host "Aplicacao iniciada com sucesso!" -ForegroundColor Green
        break
    }
}

# 6. Verificar status
Write-Host "6. Verificando status dos containers..." -ForegroundColor Yellow
wsl -e bash -c "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# 7. Testar endpoints
Write-Host "7. Testando endpoints..." -ForegroundColor Yellow

$endpoints = @(
    "http://localhost:8084/actuator/health",
    "http://172.30.221.62:8084/actuator/health",
    "http://localhost:8084/ping",
    "http://172.30.221.62:8084/ping"
)

foreach ($endpoint in $endpoints) {
    Write-Host "Testando: $endpoint" -ForegroundColor Cyan
    try {
        $result = wsl -e bash -c "timeout 10 curl -s '$endpoint' 2>/dev/null"
        if ($result -and $result.Length -gt 10) {
            Write-Host "✅ FUNCIONANDO: $(($result | Out-String).Substring(0, [Math]::Min(80, $result.Length)))" -ForegroundColor Green
        } else {
            Write-Host "❌ NAO RESPONDEU" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ ERRO" -ForegroundColor Red
    }
}

Write-Host "`n=== CONFIGURACAO CONCLUIDA ===" -ForegroundColor Green
Write-Host "Endpoints para Postman:" -ForegroundColor Yellow
Write-Host "- Health: http://172.30.221.62:8084/actuator/health" -ForegroundColor Cyan
Write-Host "- API: http://172.30.221.62:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
Write-Host "- Ping: http://172.30.221.62:8084/ping" -ForegroundColor Cyan