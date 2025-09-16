#!/bin/bash
# ============================================================================
# SCRIPT DE CORREÇÃO AUTOMÁTICA DE CONFLITOS DE PORTAS
# Aplica correções padronizadas em todos os docker-compose
# ============================================================================

echo "🔧 CORREÇÃO AUTOMÁTICA DE PORTAS - KBNT System"
echo "=============================================="

WORKSPACE_ROOT="/mnt/c/workspace/estudosKBNT_Kafka_Logs_V2_cleanCode"
cd "$WORKSPACE_ROOT"

echo ""
echo "📁 Criando backup dos arquivos originais..."
BACKUP_DIR="./backups/port-fixes-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup dos docker-compose files
find . -name "docker-compose*.yml" -exec cp {} "$BACKUP_DIR/" \;
echo "✅ Backup criado em: $BACKUP_DIR"

echo ""
echo "🔄 Aplicando correções de portas..."

# 1. Corrigir Virtual Stock Service para porta consistente 8084
echo "   → Padronizando Virtual Stock Service para porta 8084..."
find . -name "docker-compose*.yml" -exec sed -i 's/"8084:8080"/"8084:8084"/g' {} \;
find . -name "docker-compose*.yml" -exec sed -i 's/:8080\/actuator/:8084\/actuator/g' {} \;

# 2. Corrigir Zookeeper para usar porta interna consistente
echo "   → Padronizando Zookeeper para porta interna 2181..."
find . -name "docker-compose*.yml" -exec sed -i 's/ZOOKEEPER_CLIENT_PORT: 218[2-3]/ZOOKEEPER_CLIENT_PORT: 2181/g' {} \;

# 3. Separar Kafka UI da porta 8080 (conflito com API Gateway)
echo "   → Separando Kafka UI para porta 8090..."
find . -name "docker-compose*.yml" -exec sed -i 's/"8080:8080".*# Kafka UI/"8090:8080"  # Kafka UI/g' {} \;

# 4. Corrigir URLs internas dos serviços
echo "   → Atualizando URLs internas dos serviços..."
find . -name "docker-compose*.yml" -exec sed -i 's/virtual-stock-service.*:8080/virtual-stock-service:8084/g' {} \;

# 5. Corrigir arquivos de configuração de aplicação
echo "   → Atualizando arquivos application.yml..."
find ./microservices -name "application*.yml" -exec sed -i 's/port: 8080/port: 8084/g' {} \;

# 6. Corrigir PostgreSQL para usar portas alternativas em ambientes de teste
echo "   → Configurando PostgreSQL com portas alternativas..."
sed -i 's/"5432:5432"/"15432:5432"/g' docker-compose.free-tier.yml
sed -i 's/localhost:5432/localhost:15432/g' docker-compose.free-tier.yml

echo ""
echo "✅ CORREÇÕES APLICADAS!"
echo "======================"
echo ""
echo "📋 Mudanças realizadas:"
echo "   ✓ Virtual Stock Service: porta consistente 8084"
echo "   ✓ Zookeeper: porta interna padronizada 2181"
echo "   ✓ Kafka UI: movido para porta 8090"
echo "   ✓ URLs internas atualizadas"
echo "   ✓ PostgreSQL: portas alternativas em free-tier"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "=================="
echo "1. Execute './validate-ports.sh' para verificar"
echo "2. Teste com: docker-compose -f docker-compose-stable-final.yml up -d"
echo "3. Valide endpoints em: http://localhost:8084"
echo ""
echo "💾 Backup disponível em: $BACKUP_DIR"
echo "🔄 Para reverter: cp $BACKUP_DIR/* ."