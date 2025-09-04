# Docker Environment Setup for VS Code
# Automated installation and configuration

Write-Host "🚀 Setting up Docker environment for VS Code..." -ForegroundColor Cyan

# Install Docker Desktop via winget (VS Code integrated)
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Docker Desktop..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop
    
    Write-Host "⚠️ Docker Desktop installed. Please:" -ForegroundColor Yellow
    Write-Host "  1. Restart VS Code" -ForegroundColor White
    Write-Host "  2. Start Docker Desktop from Start Menu" -ForegroundColor White
    Write-Host "  3. Wait for Docker to initialize (green indicator)" -ForegroundColor White
    Write-Host "  4. Re-run this script" -ForegroundColor White
    exit 0
}

# Verify Docker is running
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Desktop is not running. Please start it first." -ForegroundColor Red
    exit 1
}

# Start the complete environment
Write-Host "🔧 Starting KBNT environment..." -ForegroundColor Yellow

# Navigate to project directory
$projectRoot = "c:\workspace\estudosKBNT_Kafka_Logs"
Set-Location $projectRoot

# Start Docker Compose with VS Code integration
Write-Host "🐳 Starting Docker services..." -ForegroundColor Blue
docker-compose -f docker/docker-compose.yml up -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep 30

# Check service health
$services = @{
    "Kafka UI" = "http://localhost:8080"
    "PostgreSQL" = "localhost:5432"
    "Redis" = "localhost:6379"
    "Kafka" = "localhost:9092"
}

foreach ($service in $services.GetEnumerator()) {
    try {
        if ($service.Value -like "http*") {
            $response = Invoke-WebRequest $service.Value -TimeoutSec 5
            Write-Host "✅ $($service.Key) is ready: $($service.Value)" -ForegroundColor Green
        } else {
            $connection = Test-NetConnection -ComputerName $service.Value.Split(':')[0] -Port $service.Value.Split(':')[1] -InformationLevel Quiet
            if ($connection) {
                Write-Host "✅ $($service.Key) is ready: $($service.Value)" -ForegroundColor Green
            } else {
                Write-Host "⚠️ $($service.Key) starting: $($service.Value)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "⚠️ $($service.Key) initializing: $($service.Value)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Environment ready for VS Code development!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps in VS Code:" -ForegroundColor Cyan
Write-Host "  1. Install recommended extensions (prompt should appear)" -ForegroundColor White
Write-Host "  2. Open Command Palette (Ctrl+Shift+P)" -ForegroundColor White
Write-Host "  3. Run: 'Java: Reload Projects'" -ForegroundColor White
Write-Host "  4. Run: 'Java: Build Workspace'" -ForegroundColor White
Write-Host "  5. Use F5 to debug microservices" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Access points:" -ForegroundColor Cyan
Write-Host "  • Kafka UI: http://localhost:8080" -ForegroundColor White
Write-Host "  • Virtual Stock API: http://localhost:8081" -ForegroundColor White
Write-Host "  • PostgreSQL: localhost:5432" -ForegroundColor White
