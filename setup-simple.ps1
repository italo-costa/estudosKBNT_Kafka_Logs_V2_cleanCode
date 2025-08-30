Write-Host "Setting up VS Code environment..." -ForegroundColor Cyan

# Check if Docker is available
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker not found. Installing..." -ForegroundColor Yellow
    winget install Docker.DockerDesktop
    Write-Host "Please restart VS Code and start Docker Desktop, then run this script again." -ForegroundColor Yellow
    exit 0
}

# Test Docker
try {
    docker version | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Please start Docker Desktop first" -ForegroundColor Red
    exit 1
}

# Start environment
Write-Host "Starting Docker services..." -ForegroundColor Blue
docker-compose -f docker/docker-compose.yml up -d

Write-Host "Waiting for services..." -ForegroundColor Yellow
Start-Sleep 30

Write-Host "Environment ready!" -ForegroundColor Green
Write-Host "Kafka UI: http://localhost:8080" -ForegroundColor White
Write-Host "Next: Press F5 in VS Code to debug services" -ForegroundColor Cyan
