# Setup Open Source Environment for VS Code
# Using only open source tools

Write-Host "🚀 Setting up Open Source Development Environment" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check if we have any container runtime
$hasDocker = Get-Command docker -ErrorAction SilentlyContinue
$hasPodman = Get-Command podman -ErrorAction SilentlyContinue

if (-not $hasDocker -and -not $hasPodman) {
    Write-Host "📦 Installing open source container tools..." -ForegroundColor Yellow
    
    # Option 1: Podman (100% open source alternative to Docker)
    Write-Host "Installing Podman (open source Docker alternative)..." -ForegroundColor Blue
    winget install RedHat.Podman
    
    # Option 2: Rancher Desktop (open source Docker Desktop alternative)  
    Write-Host "Installing Rancher Desktop (open source)..." -ForegroundColor Blue
    winget install suse.RancherDesktop
    
    Write-Host "✅ Open source container tools installed!" -ForegroundColor Green
    Write-Host "Please restart VS Code and run this script again." -ForegroundColor Yellow
    exit 0
}

# Check Python (for the log consumer you have open)
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "🐍 Installing Python..." -ForegroundColor Blue
    winget install Python.Python.3.11
}

# Check Java (OpenJDK - open source)
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "☕ Installing OpenJDK (open source Java)..." -ForegroundColor Blue
    winget install EclipseAdoptium.Temurin.17.JDK
}

# Check Maven (open source)
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Apache Maven (open source)..." -ForegroundColor Blue
    winget install Apache.Maven
}

Write-Host ""
Write-Host "🔧 Starting Open Source Services..." -ForegroundColor Green

# Use podman-compose or docker-compose (both open source)
if ($hasPodman) {
    Write-Host "Using Podman (open source)..." -ForegroundColor Blue
    podman-compose -f docker/docker-compose.yml up -d
} else {
    Write-Host "Using Docker CE..." -ForegroundColor Blue
    docker-compose -f docker/docker-compose.yml up -d
}

Write-Host "⏳ Waiting for open source services to start..." -ForegroundColor Yellow
Start-Sleep 20

Write-Host ""
Write-Host "✅ Open Source Environment Ready!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "🔧 Stack Components (All Open Source):" -ForegroundColor Cyan
Write-Host "  • Apache Kafka (Message Broker)" -ForegroundColor White
Write-Host "  • PostgreSQL (Database)" -ForegroundColor White  
Write-Host "  • Redis (Cache)" -ForegroundColor White
Write-Host "  • OpenJDK (Java Runtime)" -ForegroundColor White
Write-Host "  • Apache Maven (Build Tool)" -ForegroundColor White
Write-Host "  • Python 3 (Scripting)" -ForegroundColor White
Write-Host "  • VS Code (Editor)" -ForegroundColor White

Write-Host ""
Write-Host "🌐 Service URLs:" -ForegroundColor Cyan
Write-Host "  • Kafka UI: http://localhost:8080" -ForegroundColor White
Write-Host "  • PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host "  • Redis: localhost:6379" -ForegroundColor White
Write-Host "  • Kafka: localhost:9092" -ForegroundColor White

Write-Host ""
Write-Host "📝 Next Steps in VS Code:" -ForegroundColor Yellow
Write-Host "  1. Install Python extension (ms-python.python)" -ForegroundColor White
Write-Host "  2. Install Java Extension Pack (vscjava.vscode-java-pack)" -ForegroundColor White
Write-Host "  3. Press F5 to run/debug your log-consumer.py" -ForegroundColor White
Write-Host "  4. Use Ctrl+Shift+P -> 'Python: Run Python File in Terminal'" -ForegroundColor White

Write-Host ""
Write-Host "💡 Tip: Your log-consumer.py is ready to run!" -ForegroundColor Green
Write-Host "Run: python consumers/python/log-consumer.py --topic application-logs" -ForegroundColor Cyan
