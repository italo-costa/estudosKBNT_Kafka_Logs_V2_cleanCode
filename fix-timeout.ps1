# Script Simples para Resolver Timeout - Virtual Stock Service

Write-Host "=== RESOLVENDO PROBLEMA DE TIMEOUT ===" -ForegroundColor Green

# 1. Parar aplicacao atual
Write-Host "1. Parando aplicacao atual..." -ForegroundColor Yellow
wsl -e bash -c "docker rm -f virtual-stock-stable"

# 2. Verificar PostgreSQL
Write-Host "2. Verificando PostgreSQL..." -ForegroundColor Yellow
$pgStatus = wsl -e bash -c "docker exec postgres-kbnt-stable pg_isready -U postgres"
if ($pgStatus -match "accepting connections") {
    Write-Host "PostgreSQL OK" -ForegroundColor Green
} else {
    Write-Host "Reiniciando PostgreSQL..." -ForegroundColor Yellow
    wsl -e bash -c "docker restart postgres-kbnt-stable"
    Start-Sleep -Seconds 10
}

# 3. Configurar Port Forwarding para Windows
Write-Host "3. Configurando Port Forwarding..." -ForegroundColor Yellow
try {
    netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0 2>$null
    netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=127.0.0.1
    Write-Host "Port forwarding configurado" -ForegroundColor Green
} catch {
    Write-Host "Aviso: Execute como Administrador para configurar port forwarding" -ForegroundColor Yellow
}

# 4. Iniciar aplicacao com configuracoes basicas
Write-Host "4. Iniciando aplicacao..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name virtual-stock-stable --network kbnt-stable-net -p 8084:8084 -e SPRING_PROFILES_ACTIVE=docker -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres-kbnt-stable:5432/virtualstock -e SPRING_DATASOURCE_USERNAME=postgres -e SPRING_DATASOURCE_PASSWORD=postgres --restart=always -v /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/microservices/virtual-stock-service/target/virtual-stock-service-2.0.0.jar:/app/app.jar eclipse-temurin:17-jre java -jar /app/app.jar"

# 5. Aguardar inicializacao
Write-Host "5. Aguardando inicializacao (30 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 6. Testar aplicacao
Write-Host "6. Testando aplicacao..." -ForegroundColor Yellow
$maxTries = 5
$success = $false

for ($i = 1; $i -le $maxTries; $i++) {
    Write-Host "Tentativa $i de $maxTries..." -ForegroundColor Cyan
    try {
        $result = wsl -e bash -c "curl -s -m 10 http://localhost:8084/actuator/health"
        if ($result -match "UP") {
            Write-Host "SUCESSO! Aplicacao funcionando!" -ForegroundColor Green
            $success = $true
            break
        }
    } catch {
        Write-Host "Tentativa $i falhou" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 10
}

if ($success) {
    Write-Host "`nAPLICACAO RESOLVIDA!" -ForegroundColor Green
    Write-Host "Health: http://localhost:8084/actuator/health" -ForegroundColor Cyan
    Write-Host "API: http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
} else {
    Write-Host "`nProblema nao resolvido. Verificando logs..." -ForegroundColor Red
    wsl -e bash -c "docker logs virtual-stock-stable --tail 20"
}
