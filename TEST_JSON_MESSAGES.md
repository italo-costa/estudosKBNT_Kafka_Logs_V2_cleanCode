# 🧪 KBNT Stock API - Teste de Requisições JSON

## 🎯 Executando Testes HTTP com JSON

Vou executar testes reais das mensagens JSON definidas no sistema usando requisições HTTP.

## 📋 Estrutura da Mensagem StockUpdateMessage

Com base no código do modelo, a mensagem JSON possui os seguintes campos:

```java
public class StockUpdateMessage {
    @NotBlank private String productId;           // ID do produto
    @NotBlank private String distributionCenter;  // Centro de distribuição  
    @NotBlank private String branch;             // Filial
    @NotNull @PositiveOrZero private Integer quantity; // Quantidade
    @NotBlank private String operation;          // ADD, REMOVE, SET, TRANSFER
    private LocalDateTime timestamp;             // Timestamp da transação
    private String correlationId;                // ID de correlação
    private String sourceBranch;                 // Filial origem (TRANSFER)
    private String reasonCode;                   // Código do motivo
    private String referenceDocument;            // Documento de referência
}
```

## 🚀 Cenários de Teste JSON

### 1. **ADD - Adição de Estoque (Compra)**
```json
{
  "productId": "SMARTPHONE-XYZ123",
  "distributionCenter": "DC-SP01", 
  "branch": "DC-SP01",
  "quantity": 150,
  "operation": "ADD",
  "timestamp": "2024-08-30T14:30:00.000",
  "correlationId": "purchase-order-789456",
  "reasonCode": "PURCHASE",
  "referenceDocument": "PO-2024-001234"
}
```

### 2. **REMOVE - Remoção de Estoque (Venda)**
```json
{
  "productId": "SMARTPHONE-XYZ123",
  "distributionCenter": "DC-SP01",
  "branch": "FIL-SP001", 
  "quantity": 2,
  "operation": "REMOVE",
  "timestamp": "2024-08-30T14:35:00.000",
  "correlationId": "sale-transaction-555888",
  "reasonCode": "SALE",
  "referenceDocument": "INV-2024-567890"
}
```

### 3. **TRANSFER - Transferência entre Filiais**
```json
{
  "productId": "TABLET-ABC456",
  "distributionCenter": "DC-SP01",
  "branch": "FIL-SP002",
  "sourceBranch": "FIL-SP001", 
  "quantity": 25,
  "operation": "TRANSFER",
  "timestamp": "2024-08-30T14:40:00.000",
  "correlationId": "transfer-req-333666",
  "reasonCode": "REBALANCE",
  "referenceDocument": "TRF-2024-001111"
}
```

### 4. **SET - Ajuste de Inventário**
```json
{
  "productId": "NOTEBOOK-DEF789",
  "distributionCenter": "DC-RJ01",
  "branch": "FIL-RJ001",
  "quantity": 75,
  "operation": "SET", 
  "timestamp": "2024-08-30T14:45:00.000",
  "correlationId": "inventory-audit-999222",
  "reasonCode": "ADJUSTMENT",
  "referenceDocument": "AUDIT-2024-002222"
}
```

## 🔧 Endpoints REST Disponíveis

Com base no controller analisado, temos os seguintes endpoints:

- **POST** `/api/v1/stock/update` - Endpoint genérico para updates
- **POST** `/api/v1/stock/add` - Adição específica  
- **POST** `/api/v1/stock/remove` - Remoção específica
- **POST** `/api/v1/stock/transfer` - Transferência específica
- **POST** `/api/v1/stock/batch` - Operações em lote

## 🏃 Executando Testes Simulados

Agora vou executar os testes práticos simulando as requisições...
