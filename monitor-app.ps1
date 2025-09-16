# Script PowerShell para monitorar Virtual Stock Service
# Executa verificações e mantém a aplicação funcionando

Write-Host "=== Monitor Virtual Stock Service ===" -ForegroundColor Green
Write-Host "Iniciando monitoramento contínuo..." -ForegroundColor Yellow
Write-Host "Pressione Ctrl+C para parar" -ForegroundColor Gray
Write-Host ""

function Check-Container {
    param($ContainerName)
    
    try {
        $status = wsl -e bash -c "docker inspect --format='{{.State.Status}}' '$ContainerName' 2>/dev/null"
        
        if ($status -ne "running") {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ⚠️  Container $ContainerName não está rodando. Status: $status" -ForegroundColor Yellow
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 🔄 Reiniciando $ContainerName..." -ForegroundColor Cyan
            wsl -e bash -c "docker start '$ContainerName'"
            Start-Sleep -Seconds 5
        } else {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ✅ Container $ContainerName está funcionando" -ForegroundColor Green
        }
    } catch {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ❌ Erro ao verificar container $ContainerName" -ForegroundColor Red
    }
}

function Check-Health {
    try {
        $response = wsl -e bash -c "curl -s -o /dev/null -w '%{http_code}' http://localhost:8084/actuator/health 2>/dev/null"
        
        if ($response -eq "200") {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ✅ API está respondendo (HTTP $response)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ❌ API não está respondendo (HTTP $response)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ❌ Erro ao verificar API" -ForegroundColor Red
        return $false
    }
}

# Loop principal
while ($true) {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] === Verificação de Saúde ===" -ForegroundColor Cyan
    
    # Verificar containers
    Check-Container "postgres-kbnt-stable"
    Check-Container "virtual-stock-stable"
    
    # Verificar saúde da API
    if (-not (Check-Health)) {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 🔄 Tentando reiniciar aplicação..." -ForegroundColor Cyan
        wsl -e bash -c "docker restart virtual-stock-stable"
        Start-Sleep -Seconds 30
    }
    
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 💤 Aguardando próxima verificação..." -ForegroundColor Gray
    Write-Host ""
    Start-Sleep -Seconds 30
}
