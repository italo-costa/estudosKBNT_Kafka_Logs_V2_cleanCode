#!/usr/bin/env pwsh
# Script para iniciar aplicação Spring Boot com configurações otimizadas para Windows

param(
    [int]$Port = 8080,
    [switch]$Verbose,
    [switch]$Debug
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "           INICIANDO VIRTUAL STOCK SERVICE" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Configurar variáveis de ambiente
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot"
$env:PATH = "C:\maven\apache-maven-3.9.4\bin;$env:JAVA_HOME\bin;$env:PATH"

Write-Host "`n1. Verificando prerequisitos..." -ForegroundColor Yellow

# Verificar Java
try {
    $javaVersion = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1
    Write-Host "   Java: OK - $($javaVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "   Java: ERRO - Java nao encontrado" -ForegroundColor Red
    exit 1
}

# Verificar Maven
try {
    $mavenVersion = & "C:\maven\apache-maven-3.9.4\bin\mvn" --version 2>&1 | Select-Object -First 1
    Write-Host "   Maven: OK - $mavenVersion" -ForegroundColor Green
} catch {
    Write-Host "   Maven: ERRO - Maven nao encontrado" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Verificando porta $Port..." -ForegroundColor Yellow

# Verificar se a porta está em uso
$portCheck = netstat -ano | findstr ":$Port"
if ($portCheck) {
    Write-Host "   AVISO: Porta $Port em uso. Tentando liberar..." -ForegroundColor Yellow
    
    # Tentar identificar e finalizar processo
    $processes = netstat -ano | findstr ":$Port" | ForEach-Object { 
        if ($_ -match '\s+(\d+)$') { $matches[1] } 
    } | Select-Object -Unique
    
    foreach ($pid in $processes) {
        try {
            Write-Host "   Finalizando processo PID: $pid" -ForegroundColor Yellow
            taskkill /PID $pid /F 2>$null
            Start-Sleep 2
        } catch {
            Write-Host "   Nao foi possivel finalizar PID: $pid" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   Porta ${Port}: DISPONIVEL" -ForegroundColor Green
}

Write-Host "`n3. Compilando aplicacao..." -ForegroundColor Yellow

# Navegar para diretório da aplicação
Set-Location "C:\workspace\estudosKBNT_Kafka_Logs\simple-app"

# Compilar aplicação
Write-Host "   Executando: mvn clean package -DskipTests" -ForegroundColor White
$compileResult = & "C:\maven\apache-maven-3.9.4\bin\mvn" clean package -DskipTests

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ERRO na compilacao!" -ForegroundColor Red
    exit 1
}

Write-Host "   Compilacao: SUCESSO" -ForegroundColor Green

Write-Host "`n4. Configurando firewall Windows..." -ForegroundColor Yellow

# Tentar configurar regra do firewall (pode falhar se não tiver permissões de admin)
try {
    netsh advfirewall firewall show rule name="Java-Spring-Boot-${Port}" >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Tentando criar regra de firewall..." -ForegroundColor White
        netsh advfirewall firewall add rule name="Java-Spring-Boot-${Port}" dir=in action=allow protocol=TCP localport=$Port >$null 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Firewall: Regra criada" -ForegroundColor Green
        } else {
            Write-Host "   Firewall: Aviso - Execute como Administrador para configurar automaticamente" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Firewall: Regra ja existe" -ForegroundColor Green
    }
} catch {
    Write-Host "   Firewall: Configuracao manual necessaria" -ForegroundColor Yellow
}

Write-Host "`n5. Iniciando aplicacao Spring Boot..." -ForegroundColor Yellow

# Configurar parâmetros JVM otimizados
$jvmArgs = @(
    "-Dserver.address=0.0.0.0"
    "-Dserver.port=$Port"
    "-Djava.net.preferIPv4Stack=true"
    "-Dspring.profiles.active=dev"
    "-Dlogging.level.org.springframework.web=DEBUG"
)

if ($Debug) {
    $jvmArgs += "-Ddebug=true"
    $jvmArgs += "-Dlogging.level.root=DEBUG"
}

Write-Host "   Configuracoes:" -ForegroundColor White
Write-Host "     - Porta: ${Port}" -ForegroundColor White
Write-Host "     - Endereco: 0.0.0.0 (todas as interfaces)" -ForegroundColor White
Write-Host "     - Profile: dev" -ForegroundColor White
Write-Host "     - IPv4: Preferencial" -ForegroundColor White

Write-Host "`n   Iniciando servidor..." -ForegroundColor White
Write-Host "   Para testar: curl http://localhost:${Port}/actuator/health" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Iniciar aplicação
$jvmArgsString = $jvmArgs -join " "
$command = "& `"$env:JAVA_HOME\bin\java.exe`" $jvmArgsString -jar target\simple-stock-api-1.0.0.jar"

Write-Host "   Executando: java $jvmArgsString -jar target\simple-stock-api-1.0.0.jar" -ForegroundColor White
Write-Host "`n=================================================================" -ForegroundColor Cyan

# Executar comando
Invoke-Expression $command
