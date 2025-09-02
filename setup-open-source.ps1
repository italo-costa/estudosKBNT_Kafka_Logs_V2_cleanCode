Write-Host "Setting up Open Source Environment for VS Code" -ForegroundColor Cyan

# Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python..." -ForegroundColor Blue
    winget install Python.Python.3.11
}

# Check Java OpenJDK
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "Installing OpenJDK..." -ForegroundColor Blue
    winget install EclipseAdoptium.Temurin.17.JDK
}

# Check Maven
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Maven..." -ForegroundColor Blue
    winget install Apache.Maven
}

Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
python -m venv venv
.\venv\Scripts\Activate.ps1

Write-Host "Installing Python Kafka library..." -ForegroundColor Blue
pip install kafka-python

Write-Host ""
Write-Host "Open Source Environment Ready!" -ForegroundColor Green
Write-Host "Stack: OpenJDK + Maven + Python + Kafka (all open source)" -ForegroundColor White
Write-Host ""
Write-Host "VS Code Setup:" -ForegroundColor Cyan
Write-Host "1. Install Python extension" -ForegroundColor White
Write-Host "2. Install Java Extension Pack" -ForegroundColor White
Write-Host "3. Select Python interpreter: ./venv/Scripts/python.exe" -ForegroundColor White
Write-Host "4. Your log-consumer.py is ready to run!" -ForegroundColor White
Write-Host ""
Write-Host "Test command: python consumers/python/log-consumer.py" -ForegroundColor Cyan
