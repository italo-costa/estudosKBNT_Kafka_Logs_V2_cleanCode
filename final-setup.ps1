# Script Final - Aplicacao Completa para IP 172.30.221.62:8084

Write-Host "=== CONFIGURACAO FINAL PARA POSTMAN ===" -ForegroundColor Green

# Parar tudo e recriar do zero
Write-Host "1. Limpando ambiente..." -ForegroundColor Yellow
wsl -e bash -c "docker rm -f virtual-stock-stable postgres-kbnt-stable 2>/dev/null || true"

# Recriar PostgreSQL com acesso total
Write-Host "2. Criando PostgreSQL..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name postgres-kbnt-stable -p 0.0.0.0:5433:5432 -e POSTGRES_DB=virtualstock -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -v postgres-data-stable:/var/lib/postgresql/data --restart=always postgres:15"

Start-Sleep -Seconds 15

# Criar aplicacao com configuracao maxima de acessibilidade
Write-Host "3. Criando aplicacao com acesso total..." -ForegroundColor Yellow
wsl -e bash -c "docker run -d --name virtual-stock-stable -p 0.0.0.0:8084:8084 -e SPRING_PROFILES_ACTIVE=docker -e SPRING_DATASOURCE_URL='jdbc:postgresql://172.30.221.62:5433/virtualstock' -e SPRING_DATASOURCE_USERNAME=postgres -e SPRING_DATASOURCE_PASSWORD=postgres -e SERVER_ADDRESS=0.0.0.0 --restart=always -v /mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode/microservices/virtual-stock-service/target/virtual-stock-service-2.0.0.jar:/app/app.jar eclipse-temurin:17-jre java -Dserver.address=0.0.0.0 -Dserver.port=8084 -jar /app/app.jar"

# Aguardar com feedback
Write-Host "4. Aguardando inicializacao (ate 90 segundos)..." -ForegroundColor Yellow
$success = $false
for ($i = 1; $i -le 90; $i++) {
    Write-Progress -Activity "Aguardando aplicacao" -Status "Tentativa $i/90" -PercentComplete ($i * 100 / 90)
    
    try {
        $result = wsl -e bash -c "timeout 3 curl -s http://127.0.0.1:8084/actuator/health 2>/dev/null"
        if ($result -match "UP") {
            Write-Host "✅ Aplicacao funcionando localmente!" -ForegroundColor Green
            $success = $true
            break
        }
    } catch { }
    
    Start-Sleep -Seconds 1
}

if ($success) {
    # Testar IP externo
    Write-Host "5. Testando acesso externo..." -ForegroundColor Yellow
    
    # Tentar diferentes formas de acessar
    $testUrls = @(
        "http://127.0.0.1:8084/actuator/health",
        "http://localhost:8084/actuator/health", 
        "http://172.30.221.62:8084/actuator/health"
    )
    
    foreach ($url in $testUrls) {
        Write-Host "Testando: $url" -ForegroundColor Cyan
        try {
            $result = wsl -e bash -c "timeout 5 curl -s '$url' 2>/dev/null"
            if ($result -match "UP") {
                Write-Host "✅ FUNCIONANDO!" -ForegroundColor Green
            } else {
                Write-Host "❌ Nao responde" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Erro" -ForegroundColor Red
        }
    }
    
    Write-Host "`n=== APLICACAO CONFIGURADA ===" -ForegroundColor Green
    Write-Host "Use estes endpoints no Postman:" -ForegroundColor Yellow
    Write-Host "✅ Health: http://172.30.221.62:8084/actuator/health" -ForegroundColor Cyan
    Write-Host "✅ API: http://172.30.221.62:8084/api/v1/virtual-stock/stocks" -ForegroundColor Cyan
    Write-Host "✅ Ping: http://172.30.221.62:8084/ping" -ForegroundColor Cyan
    Write-Host "✅ Home: http://172.30.221.62:8084/" -ForegroundColor Cyan
    
} else {
    Write-Host "❌ Aplicacao nao iniciou corretamente" -ForegroundColor Red
    Write-Host "Verificando logs..." -ForegroundColor Yellow
    wsl -e bash -c "docker logs virtual-stock-stable --tail 20"
}