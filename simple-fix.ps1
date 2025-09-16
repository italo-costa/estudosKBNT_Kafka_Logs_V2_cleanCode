# Solucao Definitiva Simples para Postman

Write-Host "=== RECRIANDO APLICACAO PARA POSTMAN ===" -ForegroundColor Green

# Parar containers
wsl -e bash -c "docker rm -f virtual-stock-stable postgres-kbnt-stable"

# PostgreSQL simples
Write-Host "Criando PostgreSQL..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name postgres-kbnt-stable -p 5432:5432 -e POSTGRES_DB=virtualstock -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres --restart=always postgres:15"

Start-Sleep -Seconds 15

# Aplicacao simples
Write-Host "Criando aplicacao..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name virtual-stock-stable -p 8084:8084 -e SPRING_PROFILES_ACTIVE=docker -e SPRING_DATASOURCE_URL='jdbc:postgresql://host.docker.internal:5432/virtualstock' -e SPRING_DATASOURCE_USERNAME=postgres -e SPRING_DATASOURCE_PASSWORD=postgres --add-host=host.docker.internal:host-gateway --restart=always -v /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/microservices/virtual-stock-service/target/virtual-stock-service-2.0.0.jar:/app/app.jar eclipse-temurin:17-jre java -jar /app/app.jar"

# Aguardar
Write-Host "Aguardando 45 segundos..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

# Testar WSL2
Write-Host "Testando WSL2..." -ForegroundColor Yellow
$test = wsl -e bash -c "curl -s -m 5 http://localhost:8084/actuator/health"
if ($test -match "UP") {
    Write-Host "✅ WSL2 OK" -ForegroundColor Green
} else {
    Write-Host "❌ WSL2 FALHOU" -ForegroundColor Red
}

# Port forwarding
Write-Host "Configurando Windows..." -ForegroundColor Yellow
$wslIP = wsl -e bash -c "hostname -I | awk '{print `$1}'"
netsh interface portproxy delete v4tov4 listenport=8084 2>$null
netsh interface portproxy add v4tov4 listenport=8084 listenaddress=0.0.0.0 connectport=8084 connectaddress=$wslIP

Write-Host "`nUSE NO POSTMAN:" -ForegroundColor Green
Write-Host "http://localhost:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan