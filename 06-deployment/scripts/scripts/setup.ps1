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

Write-Info "🚀 Configurando ambiente de estudos AMQ Streams (Kafka) + Kubernetes"
Write-Info "============================================================="

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

# Instalar operador Strimzi (AMQ Streams community)
Write-Info "� Instalando operador Strimzi (AMQ Streams)..."
kubectl apply -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Aguardar operador estar pronto
Write-Info "⏳ Aguardando operador Strimzi estar pronto..."
kubectl wait pod -l=name=strimzi-cluster-operator --for=condition=Ready -n kafka --timeout=300s

# Deploy do cluster Kafka via Custom Resources
Write-Info "📨 Fazendo deploy do cluster Kafka (AMQ Streams)..."
kubectl apply -f kubernetes/kafka/kafka-cluster.yaml

# Aguardar cluster Kafka estar pronto
Write-Info "⏳ Aguardando cluster Kafka estar pronto..."
kubectl wait kafka/kafka-cluster --for=condition=Ready -n kafka --timeout=600s

# Criar tópicos via Custom Resources
Write-Info "📋 Criando tópicos via Custom Resources..."
kubectl apply -f kubernetes/kafka/kafka-topics.yaml

# Port-forward para acesso local
Write-Info "🌐 Configurando port-forward para AMQ Streams..."
Start-Process -NoNewWindow kubectl -ArgumentList "port-forward", "-n", "kafka", "svc/kafka-cluster-kafka-bootstrap", "9092:9092"

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
Write-Info "   kubectl get kafkatopics -n kafka"
Write-Info ""
Write-Info "   # Ou via linha de comando:"
Write-Info "   kubectl exec -n kafka kafka-cluster-kafka-0 -- /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list"
Write-Info ""
Write-Info "4. Monitorar cluster AMQ Streams:"
Write-Info "   kubectl get kafka -n kafka"
Write-Info "   kubectl get pods -n kafka"
Write-Info ""
Write-Info "5. Para usar Docker Compose (alternativa local):"
Write-Info "   cd docker && docker-compose up -d"
Write-Info ""
Write-Info "📚 Consulte a documentação em docs/ para mais exemplos!"
Write-Success "================================================="
