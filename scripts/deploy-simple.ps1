# =============================================================================
# KBNT KAFKA LOGS - DEPLOY ESCALÁVEL AUTOMATIZADO
# =============================================================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("docker", "kubernetes")]
    [string]$Mode = "docker",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("minimal", "standard", "high-performance")]
    [string]$Scale = "standard"
)

function Write-Banner {
    param([string]$Message)
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "   $Message" -ForegroundColor White
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host ">> $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Check-Docker {
    Write-Step "Verificando Docker..."
    try {
        docker --version | Out-Null
        Write-Success "Docker encontrado"
    } catch {
        Write-Error "Docker nao encontrado"
        exit 1
    }
}

function Deploy-Scalable {
    Write-Step "Iniciando deploy escalavel..."
    
    # Cleanup anterior
    Write-Step "Limpando containers anteriores..."
    docker container prune -f
    docker volume prune -f
    
    # Deploy com docker-compose escalável
    Write-Step "Fazendo deploy da aplicacao escalavel..."
    docker compose -f docker-compose.scalable.yml up -d --build
    
    # Aguardar inicialização
    Write-Step "Aguardando inicializacao dos servicos..."
    Start-Sleep 120
    
    Write-Success "Deploy concluido!"
}

function Show-Info {
    Write-Banner "KBNT KAFKA LOGS - DEPLOY ESCALÁVEL"
    
    Write-Host "CONFIGURACAO:" -ForegroundColor White
    Write-Host "  Modo: $Mode" -ForegroundColor Green
    Write-Host "  Escala: $Scale" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "ENDPOINTS:" -ForegroundColor White
    Write-Host "  Load Balancer: http://localhost:8090" -ForegroundColor Cyan
    Write-Host "  HAProxy Stats: http://localhost:8404/stats" -ForegroundColor Cyan
    Write-Host "  Prometheus: http://localhost:9090" -ForegroundColor Cyan
    Write-Host "  Grafana: http://localhost:3000" -ForegroundColor Cyan
}

# Script principal
try {
    Write-Banner "INICIANDO DEPLOY ESCALÁVEL"
    
    Check-Docker
    Deploy-Scalable
    Show-Info
    
    Write-Banner "DEPLOY CONCLUÍDO COM SUCESSO!"
    
} catch {
    Write-Error "Erro durante o deploy: $_"
    exit 1
}
