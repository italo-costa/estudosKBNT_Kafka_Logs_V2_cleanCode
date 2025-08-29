# PowerShell Script para Setup do Ambiente Kafka + Kubernetes no Windows

# Configuração de cores para saída
$Host.UI.RawUI.ForegroundColor = "White"

function Write-Success { 
    Write-Host $args[0] -ForegroundColor Green 
}

function Write-Info { 
    Write-Host $args[0] -ForegroundColor Cyan 
}

function Write-Warning { 
    Write-Host $args[0] -ForegroundColor Yellow 
}

function Write-Error { 
    Write-Host $args[0] -ForegroundColor Red 
}

Write-Info "🚀 Configurando ambiente de estudos Kafka + Kubernetes"
Write-Info "================================================="

# Função para verificar se um comando existe
function Test-Command {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        Write-Success "✅ $Command está instalado"
        return $true
    } catch {
        Write-Error "❌ $Command não está instalado. Por favor, instale $Command antes de continuar."
        return $false
    }
}

# Verificar dependências
Write-Info "🔍 Verificando dependências..."
$dependencies = @("docker", "kubectl", "helm", "python")
$allDepsOk = $true

foreach ($dep in $dependencies) {
    if (-not (Test-Command $dep)) {
        $allDepsOk = $false
    }
}

if (-not $allDepsOk) {
    Write-Error "❌ Algumas dependências estão faltando. Instale-as e tente novamente."
    exit 1
}

# Verificar se o Docker está rodando
try {
    docker info 2>$null | Out-Null
    Write-Success "✅ Docker está rodando"
} catch {
    Write-Error "❌ Docker não está rodando. Por favor, inicie o Docker Desktop."
    exit 1
}

# Instalar dependências Python
Write-Info "📦 Instalando dependências Python..."
pip install -r requirements.txt

# Verificar/Criar namespace Kafka
Write-Info "🏗️  Configurando namespace Kafka no Kubernetes..."
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -

# Deploy do Zookeeper
Write-Info "🐘 Fazendo deploy do Zookeeper..."
kubectl apply -f kubernetes/zookeeper/zookeeper-deployment.yaml

# Aguardar Zookeeper estar pronto
Write-Info "⏳ Aguardando Zookeeper estar pronto..."
kubectl wait --for=condition=ready pod -l app=zookeeper -n kafka --timeout=300s

# Deploy do Kafka
Write-Info "📨 Fazendo deploy do Kafka..."
kubectl apply -f kubernetes/kafka/kafka-deployment.yaml

# Aguardar Kafka estar pronto
Write-Info "⏳ Aguardando Kafka estar pronto..."
kubectl wait --for=condition=ready pod -l app=kafka -n kafka --timeout=300s

# Criar tópicos básicos
Write-Info "📋 Criando tópicos básicos..."
kubectl exec -n kafka kafka-0 -- kafka-topics --create --topic application-logs --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists
kubectl exec -n kafka kafka-0 -- kafka-topics --create --topic error-logs --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists
kubectl exec -n kafka kafka-0 -- kafka-topics --create --topic metrics --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1 --if-not-exists

# Port-forward para acesso local
Write-Info "🌐 Configurando port-forward para Kafka..."
Start-Process -NoNewWindow kubectl -ArgumentList "port-forward", "-n", "kafka", "svc/kafka", "9092:9092"

Write-Success ""
Write-Success "✅ Setup concluído com sucesso!"
Write-Success "================================================="
Write-Info "🎯 O que você pode fazer agora:"
Write-Info ""
Write-Info "1. Testar o produtor de logs:"
Write-Info "   python producers/python/log-producer.py --count 10"
Write-Info ""
Write-Info "2. Testar o consumidor de logs (em outro terminal):"
Write-Info "   python consumers/python/log-consumer.py"
Write-Info ""
Write-Info "3. Ver tópicos criados:"
Write-Info "   kubectl exec -n kafka kafka-0 -- kafka-topics --list --bootstrap-server localhost:9092"
Write-Info ""
Write-Info "4. Monitorar pods:"
Write-Info "   kubectl get pods -n kafka"
Write-Info ""
Write-Info "5. Para usar Docker Compose (alternativa local):"
Write-Info "   cd docker && docker-compose up -d"
Write-Info ""
Write-Info "📚 Consulte a documentação em docs/ para mais exemplos!"
Write-Success "================================================="
