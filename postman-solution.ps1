# Configuracao Final para Postman - Solucao Completa

Write-Host "=== SOLUCAO DEFINITIVA POSTMAN WINDOWS ===" -ForegroundColor Green

# 1. Limpar ambiente
Write-Host "1. Limpando ambiente..." -ForegroundColor Yellow
wsl -e bash -c "docker rm -f virtual-stock-stable postgres-kbnt-stable 2>/dev/null || true"

# 2. Criar PostgreSQL
Write-Host "2. Criando PostgreSQL..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name postgres-kbnt-stable -p 0.0.0.0:5432:5432 -e POSTGRES_DB=virtualstock -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -v postgres-data-stable:/var/lib/postgresql/data --restart=always postgres:15"

Start-Sleep -Seconds 15

# 3. Criar aplicacao com configuracao simples
Write-Host "3. Criando aplicacao..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name virtual-stock-stable -p 0.0.0.0:8084:8084 -e SPRING_PROFILES_ACTIVE=docker -e SPRING_DATASOURCE_URL='jdbc:postgresql://localhost:5432/virtualstock' -e SPRING_DATASOURCE_USERNAME=postgres -e SPRING_DATASOURCE_PASSWORD=postgres --restart=always --network host -v /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/microservices/virtual-stock-service/target/virtual-stock-service-2.0.0.jar:/app/app.jar eclipse-temurin:17-jre java -jar /app/app.jar"

# 4. Aguardar inicializacao
Write-Host "4. Aguardando inicializacao..." -ForegroundColor Yellow
$timeout = 120
$success = $false

for ($i = 1; $i -le $timeout; $i++) {
    Write-Progress -Activity "Inicializando aplicacao" -Status "Aguardando... ($i/$timeout segundos)" -PercentComplete ($i * 100 / $timeout)
    
    $logs = wsl -e bash -c "docker logs virtual-stock-stable 2>&1 | grep 'Started VirtualStockApplication'"
    
    if ($logs) {
        Write-Host "Aplicacao iniciada!" -ForegroundColor Green
        $success = $true
        break
    }
    
    Start-Sleep -Seconds 1
}

if (-not $success) {
    Write-Host "Aplicacao nao iniciou no tempo esperado" -ForegroundColor Red
    wsl -e bash -c "docker logs virtual-stock-stable --tail 10"
    exit 1
}

# 5. Configurar port forwarding
Write-Host "5. Configurando port forwarding..." -ForegroundColor Yellow
$wslIP = wsl -e bash -c "hostname -I | awk '{print `$1}'"
Write-Host "IP WSL2: $wslIP" -ForegroundColor Cyan

netsh interface portproxy delete v4tov4 listenport=8084 listenaddress=0.0.0.0 2>$null
netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP

# 6. Configurar firewall
netsh advfirewall firewall delete rule name="WSL2 Port 8084" 2>$null
netsh advfirewall firewall add rule name="WSL2 Port 8084" dir=in action=allow protocol=TCP localport=8084

# 7. Testar aplicacao
Write-Host "6. Testando aplicacao..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Teste WSL2
$wslTest = wsl -e bash -c "timeout 5 curl -s http://localhost:8084/actuator/health 2>/dev/null"
if ($wslTest -match "UP") {
    Write-Host "✅ WSL2 Test: OK" -ForegroundColor Green
} else {
    Write-Host "❌ WSL2 Test: FALHOU" -ForegroundColor Red
}

# Teste Windows
try {
    $windowsTest = Invoke-WebRequest -Uri "http://localhost:8084/actuator/health" -TimeoutSec 10 -UseBasicParsing
    if ($windowsTest.StatusCode -eq 200) {
        Write-Host "✅ Windows Test: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Windows Test: Status $($windowsTest.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Windows Test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== ENDPOINTS PARA POSTMAN ===" -ForegroundColor Green
Write-Host "Base URL: http://localhost:8084" -ForegroundColor Cyan
Write-Host "1. Health: GET http://localhost:8084/actuator/health" -ForegroundColor White
Write-Host "2. Stocks: GET http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor White
Write-Host "3. Create: POST http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor White
Write-Host "4. Ping: GET http://localhost:8084/ping" -ForegroundColor White

Write-Host "`nSe ainda nao funcionar no Postman:" -ForegroundColor Yellow
Write-Host "- Execute este script como Administrador" -ForegroundColor White
Write-Host "- Reinicie o Postman" -ForegroundColor White
Write-Host "- Use localhost:8084 (nao use o IP)" -ForegroundColor White