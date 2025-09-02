# PowerShell Script para build de todos os microserviços
param(
    [switch]$SkipTests = $false
)

Write-Host "🏗️  Building all microservices..." -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

# Função para build de um microserviço
function Build-Service {
    param($ServiceName)
    
    Write-Host "📦 Building $ServiceName..." -ForegroundColor Yellow
    
    if (Test-Path $ServiceName) {
        Set-Location $ServiceName
        
        if (Test-Path "pom.xml") {
            $mvnArgs = @("clean", "package")
            if ($SkipTests) {
                $mvnArgs += "-DskipTests"
            }
            
            $result = & mvn $mvnArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $ServiceName built successfully" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Failed to build $ServiceName" -ForegroundColor Red
                Write-Host $result -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "⚠️  No pom.xml found in $ServiceName, skipping..." -ForegroundColor Yellow
            return $false
        }
        
        Set-Location ..
    } else {
        Write-Host "⚠️  Directory $ServiceName not found, skipping..." -ForegroundColor Yellow
        return $false
    }
}

# Lista de microserviços
$services = @(
    "log-producer-service",
    "log-consumer-service", 
    "log-analytics-service",
    "api-gateway"
)

# Build de cada serviço
$results = @{}
foreach ($service in $services) {
    $results[$service] = Build-Service -ServiceName $service
}

Write-Host ""
Write-Host "🎯 Build Summary:" -ForegroundColor Cyan
Write-Host "=================="

# Verificar resultados
foreach ($service in $services) {
    $jarPath = "$service\target\*.jar"
    if (Test-Path $jarPath) {
        Write-Host "✅ $service - JAR created" -ForegroundColor Green
    } else {
        Write-Host "❌ $service - No JAR found" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🚀 To run services:" -ForegroundColor Cyan
Write-Host "==================="
Write-Host "Java: java -jar service-name\target\service-name-1.0.0-SNAPSHOT.jar"
Write-Host "Maven: cd service-name && mvn spring-boot:run"
Write-Host "Docker: docker-compose up -d"

Write-Host ""
Write-Host "💡 VS Code Integration:" -ForegroundColor Cyan
Write-Host "======================="
Write-Host "1. Open VS Code in this workspace"
Write-Host "2. Install Java Extension Pack"
Write-Host "3. Use Spring Boot Dashboard to run/debug services"
Write-Host "4. Use Ctrl+Shift+P -> 'Spring Boot: Run' to start services"

Write-Host ""
Write-Host "🏁 Build completed!" -ForegroundColor Green
