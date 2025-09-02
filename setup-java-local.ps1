# Local Java Development with Open Source Tools
# Perfect for VS Code development

Write-Host "☕ Setting up Local Java Open Source Environment" -ForegroundColor Cyan

# Install OpenJDK (open source Java)
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Eclipse Temurin OpenJDK..." -ForegroundColor Blue
    winget install EclipseAdoptium.Temurin.17.JDK
}

# Install Apache Maven (open source build tool)
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Apache Maven..." -ForegroundColor Blue  
    winget install Apache.Maven
}

# Install Git (if not present)
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..." -ForegroundColor Blue
    winget install Git.Git
}

Write-Host "Building projects with Maven..." -ForegroundColor Yellow
cd microservices
mvn clean compile -q

Write-Host ""
Write-Host "✅ Local Java Environment Ready!" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
Write-Host "🔧 Open Source Tools Installed:" -ForegroundColor Cyan
Write-Host "  • Eclipse Temurin OpenJDK 17" -ForegroundColor White
Write-Host "  • Apache Maven" -ForegroundColor White
Write-Host "  • Git SCM" -ForegroundColor White

Write-Host ""
Write-Host "📝 VS Code Development Workflow:" -ForegroundColor Yellow
Write-Host "  1. Open project: File -> Open Folder" -ForegroundColor White
Write-Host "  2. Install Java Extension Pack" -ForegroundColor White
Write-Host "  3. Ctrl+Shift+P -> 'Java: Build Workspace'" -ForegroundColor White
Write-Host "  4. F5 to debug any Java service" -ForegroundColor White
Write-Host "  5. Use integrated terminal for mvn commands" -ForegroundColor White

Write-Host ""
Write-Host "🏃‍♂️ Quick Start Commands:" -ForegroundColor Cyan
Write-Host "  mvn spring-boot:run -pl kbnt-log-service" -ForegroundColor White
Write-Host "  mvn test" -ForegroundColor White  
Write-Host "  mvn package" -ForegroundColor White
