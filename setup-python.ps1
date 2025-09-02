# Python Environment Setup for VS Code
# Open Source Python Development

Write-Host "🐍 Setting up Python Environment for VS Code" -ForegroundColor Cyan

# Install Python (if not present)
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python 3.11..." -ForegroundColor Blue
    winget install Python.Python.3.11
}

# Create virtual environment for the project
Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
python -m venv venv

# Activate virtual environment  
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
.\venv\Scripts\Activate.ps1

# Install required packages for Kafka consumer
Write-Host "Installing Python dependencies..." -ForegroundColor Blue
pip install kafka-python

# Create requirements.txt for VS Code
Write-Host "Creating requirements.txt..." -ForegroundColor Yellow
@"
kafka-python==2.0.2
"@ | Out-File -FilePath "requirements.txt" -Encoding UTF8

Write-Host ""
Write-Host "✅ Python Environment Ready!" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host "🔧 Python Setup:" -ForegroundColor Cyan
Write-Host "  • Python 3.11 (open source)" -ForegroundColor White
Write-Host "  • Virtual environment created" -ForegroundColor White
Write-Host "  • kafka-python library installed" -ForegroundColor White

Write-Host ""
Write-Host "📝 VS Code Python Workflow:" -ForegroundColor Yellow
Write-Host "  1. Install Python extension (ms-python.python)" -ForegroundColor White
Write-Host "  2. Ctrl+Shift+P -> 'Python: Select Interpreter'" -ForegroundColor White  
Write-Host "  3. Choose: .\venv\Scripts\python.exe" -ForegroundColor White
Write-Host "  4. Open consumers/python/log-consumer.py" -ForegroundColor White
Write-Host "  5. Press F5 to run/debug" -ForegroundColor White

Write-Host ""
Write-Host "🏃‍♂️ Test Your Log Consumer:" -ForegroundColor Cyan
Write-Host "  python consumers/python/log-consumer.py" -ForegroundColor White
Write-Host "  python consumers/python/log-consumer.py --topic test-logs" -ForegroundColor White
