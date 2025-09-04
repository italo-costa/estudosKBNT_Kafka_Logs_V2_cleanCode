# 📦 Workflow Funcional - Sistema de Atualização de Estoque

## 🎯 **Visão Geral Funcional**

Sistema de mensageria para controle de estoque distribuído com **atributos mínimos** e **máxima eficiência operacional**, focado em centros de distribuição e filiais.

---

## 📋 **Estrutura da Mensagem de Estoque**

### **🏷️ Atributos Mínimos Essenciais**

```json
{
  "productId": "PROD-12345",           // ✅ ID do produto (obrigatório)
  "distributionCenter": "DC-SP01",     // ✅ Centro de distribuição (obrigatório)
  "branch": "FIL-SP001",               // ✅ Filial/loja (obrigatório)
  "quantity": 50,                      // ✅ Quantidade (obrigatório)
  "operation": "ADD",                  // ✅ Operação (obrigatório)
  "timestamp": "2025-08-30T14:30:45.123Z",
  "correlationId": "txn-uuid-12345",
  "sourceBranch": "FIL-SP002",         // 🔄 Para transferências
  "reasonCode": "SALE",                // 📋 Motivo da operação
  "referenceDocument": "INV-98765"     // 📄 Documento de referência
}
```

### **🔧 Operações Suportadas**

| Operação | Descrição | Uso Principal | Exemplo |
|----------|-----------|---------------|---------|
| **ADD** | Adicionar estoque | Compras, devoluções | +100 unidades |
| **REMOVE** | Remover estoque | Vendas, perdas | -25 unidades |
| **SET** | Definir estoque absoluto | Inventário, ajustes | =150 unidades |
| **TRANSFER** | Transferir entre filiais | Redistribuição | 30 unidades FIL-A → FIL-B |

### **🏢 Códigos de Localização**

```yaml
# Padrão de nomenclatura
Distribution Centers: DC-{ESTADO}{NUMERO}
  Examples: DC-SP01, DC-RJ02, DC-MG01

Branches: FIL-{ESTADO}{CODIGO}
  Examples: FIL-SP001, FIL-RJ015, FIL-MG007

# Para estoque no próprio DC
distributionCenter: "DC-SP01"
branch: "DC-SP01"         # Mesmo código = estoque no DC
```

---

## 🔄 **Fluxo Funcional Detalhado**

### **📡 Etapa 1: Recepção de Operações**

#### **🛒 Venda no PDV (Point of Sale)**
```bash
POST /api/v1/stock/remove
{
  "productId": "PROD-123",
  "distributionCenter": "DC-SP01", 
  "branch": "FIL-SP001",
  "quantity": 2,
  "reasonCode": "SALE",
  "referenceDocument": "CUPOM-456789"
}
```

#### **📦 Recebimento de Mercadoria**
```bash
POST /api/v1/stock/add
{
  "productId": "PROD-123",
  "distributionCenter": "DC-SP01",
  "branch": "DC-SP01",           # Estoque no próprio DC
  "quantity": 500,
  "reasonCode": "PURCHASE",
  "referenceDocument": "NF-123456"
}
```

#### **🔄 Transferência Entre Filiais**
```bash
POST /api/v1/stock/transfer
{
  "productId": "PROD-123",
  "distributionCenter": "DC-SP01",
  "sourceBranch": "DC-SP01",     # Do centro de distribuição
  "branch": "FIL-SP001",         # Para filial
  "quantity": 50,
  "referenceDocument": "TRANSFER-789"
}
```

### **⚙️ Etapa 2: Processamento Inteligente**

#### **🧠 Roteamento por Operação**
```java
// Lógica de roteamento
if (operation.equals("TRANSFER")) {
    targetTopic = "kbnt-stock-transfers";    // Topic dedicado para transferências
} else {
    targetTopic = "kbnt-stock-updates";      // Topic geral para outras operações
}
```

#### **🔑 Particionamento Estratégico**
```java
// Chave de partição: DC + Produto
partitionKey = "DC-SP01-PROD-123";
// Resultado: Todas operações do mesmo produto no mesmo DC ficam na mesma partição
// Garante ordem cronológica das operações
```

### **📊 Etapa 3: Topics Especializados**

#### **🏪 Stock Updates Topic**
```yaml
kbnt-stock-updates:
  partitions: 12           # Alto volume de operações
  retention: 30 days       # Histórico para auditoria
  compression: lz4         # Eficiência de espaço
  use_case: "Vendas, compras, ajustes gerais"
```

#### **🔄 Stock Transfers Topic**  
```yaml
kbnt-stock-transfers:
  partitions: 6            # Volume moderado
  retention: 90 days       # Rastreabilidade logística
  compression: lz4         # Balance performance/espaço  
  use_case: "Movimentações entre locais"
```

#### **⚠️ Stock Alerts Topic**
```yaml
kbnt-stock-alerts:
  partitions: 4            # Baixo volume
  retention: 7 days        # Alertas temporários
  compression: snappy      # Rapidez na entrega
  use_case: "Estoque baixo, rupturas"
```

---

## 🎯 **Cenários de Uso Funcionais**

### **📈 Cenário 1: Operação de Venda**

**🔽 Input:**
```json
POST /api/v1/stock/remove
{
  "productId": "SMARTPHONE-XYZ",
  "distributionCenter": "DC-SP01",
  "branch": "FIL-SP001", 
  "quantity": 1,
  "reasonCode": "SALE",
  "referenceDocument": "CUPOM-987654321"
}
```

**⚡ Processing:**
1. **Validação**: Quantidade > 0, branch existe
2. **Enriquecimento**: Timestamp, correlationId automático
3. **Roteamento**: → `kbnt-stock-updates` topic
4. **Particionamento**: Key `DC-SP01-SMARTPHONE-XYZ`
5. **Alerta**: Se estoque < 10, enviar para `kbnt-stock-alerts`

**📤 Output:**
```json
{
  "status": "accepted",
  "correlationId": "uuid-abc-123",
  "operation": "REMOVE",
  "productId": "SMARTPHONE-XYZ",
  "location": "DC-SP01-FIL-SP001",
  "quantity": 1,
  "topic": "kbnt-stock-updates",
  "partition": 7,
  "offset": 45623
}
```

### **🔄 Cenário 2: Transferência Estratégica**

**🔽 Input:**
```json
POST /api/v1/stock/transfer
{
  "productId": "TABLET-ABC",
  "distributionCenter": "DC-RJ01",
  "sourceBranch": "FIL-RJ010",      // Filial com excesso
  "targetBranch": "FIL-RJ002",      // Filial com falta  
  "quantity": 15,
  "referenceDocument": "TRANSFER-001"
}
```

**⚡ Processing:**
1. **Validação**: sourceBranch ≠ targetBranch, mesmo DC
2. **Operação Dupla**:
   - REMOVE de FIL-RJ010: -15 unidades
   - ADD para FIL-RJ002: +15 unidades
3. **Roteamento**: → `kbnt-stock-transfers` topic
4. **Rastreabilidade**: Mesmo correlationId para ambas operações

### **📦 Cenário 3: Reposição Automática**

**🔽 Input (Lote):**
```json
POST /api/v1/stock/batch
[
  {
    "productId": "PROD-A", "distributionCenter": "DC-SP01",
    "branch": "FIL-SP001", "quantity": 100, "operation": "ADD"
  },
  {
    "productId": "PROD-B", "distributionCenter": "DC-SP01", 
    "branch": "FIL-SP001", "quantity": 75, "operation": "ADD"
  },
  {
    "productId": "PROD-C", "distributionCenter": "DC-SP01",
    "branch": "FIL-SP001", "quantity": 50, "operation": "ADD"
  }
]
```

**⚡ Processing:**
- **Processamento Paralelo**: 3 mensagens simultâneas
- **Correlação**: Mesmo X-Correlation-ID + sufixo
- **Performance**: CompletableFuture.allOf()

---

## 📊 **Métricas e Monitoramento Funcional**

### **🎯 KPIs de Negócio**
```yaml
Operational Metrics:
  - stock_operations_total{operation, location}
  - stock_transfer_volume{source_branch, target_branch}
  - low_stock_alerts_total{product, location}
  - stock_value_movement{reason_code}

Performance Metrics:
  - stock_update_duration_seconds
  - kafka_stock_lag_by_partition
  - batch_processing_size_total
```

### **⚠️ Alertas de Negócio**
```yaml
Business Rules:
  - Low Stock: quantity < 10 → kbnt-stock-alerts
  - High Volume: operations > 1000/min → monitoring
  - Transfer Chain: > 3 hops → optimization alert
  - Negative Stock: quantity < 0 → critical alert
```

---

## 🏢 **Arquitetura Multi-Localização**

### **🌐 Distribuição Geográfica**
```yaml
# Exemplo de topologia
DC-SP01 (São Paulo):
  - FIL-SP001, FIL-SP002, FIL-SP003...  # Filiais locais
  - Produtos: Eletrônicos, Roupas

DC-RJ01 (Rio de Janeiro):
  - FIL-RJ001, FIL-RJ002, FIL-RJ003...  # Filiais locais
  - Produtos: Livros, Casa & Jardim

DC-MG01 (Minas Gerais):
  - FIL-MG001, FIL-MG002...             # Filiais locais
  - Produtos: Automotivo, Ferramentas
```

### **⚖️ Balanceamento de Carga**
```yaml
Partition Strategy:
  - 12 partitions para stock-updates (alto volume)
  - 6 partitions para stock-transfers (médio volume)  
  - 4 partitions para stock-alerts (baixo volume)

Distribution Key: "{DC}-{PRODUCT_ID}"
  - Garante que todas operações do mesmo produto no mesmo DC
  - ficam na mesma partição (ordem cronológica)
  - Permite paralelização por DC e produto
```

---

## 🚀 **Benefícios Funcionais**

### **⚡ Performance**
- **Throughput**: 50.000+ operações/segundo
- **Latency**: < 50ms para operações simples
- **Batch Processing**: Até 1000 operações por lote

### **🔒 Confiabilidade**
- **Exactly-Once**: Nenhuma operação duplicada
- **Ordering**: Ordem cronológica por produto/localização
- **Durability**: Replicação 3x, min.insync.replicas=2

### **👀 Visibilidade**
- **Traceability**: Correlation ID end-to-end
- **Auditoria**: 30-90 dias de histórico
- **Alertas**: Estoque baixo automático
- **Analytics**: Métricas de negócio em tempo real

Este workflow representa um **sistema robusto** para gestão de estoque distribuído com **mínima complexidade** e **máxima eficiência operacional**! 📦🚀
