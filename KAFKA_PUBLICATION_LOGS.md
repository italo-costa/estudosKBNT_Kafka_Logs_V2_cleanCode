# 📊 Enhanced Kafka Publication Logs Implementation

## 🎯 Logs Implementados na Camada do Microserviço

Implementei um sistema completo de logging na camada de publicação do microserviço com as seguintes funcionalidades:

### ✅ 1. **Hash do Timestamp da Mensagem**
- Gera hash SHA-256 baseado no timestamp da mensagem + product ID + operação + correlation ID
- Hash de 16 caracteres para rastreamento único
- Fallback para hash simples se SHA-256 não disponível

```java
private String generateMessageHash(StockUpdateMessage stockMessage) {
    String timestampString = stockMessage.getTimestamp().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
    String hashInput = String.format("%s-%s-%s-%s", 
        timestampString, stockMessage.getProductId(), 
        stockMessage.getOperation(), stockMessage.getCorrelationId());
    
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    byte[] hash = digest.digest(hashInput.getBytes(StandardCharsets.UTF_8));
    return hexString.substring(0, 16); // Primeiros 16 chars
}
```

### ✅ 2. **Rastreamento do Nome do Tópico**
- Atributo `topicName` no modelo KafkaPublicationLog
- Determinação inteligente do tópico baseada na operação:
  - **TRANSFER** → `kbnt-stock-transfers`
  - **ADD/REMOVE/SET** → `kbnt-stock-updates`
  - **ALERTS** → `kbnt-stock-alerts`

### ✅ 3. **Commit da Publicação**
- Logs de confirmação com detalhes do broker Kafka:
  - **Partition** assignada
  - **Offset** recebido
  - **Timestamp** do acknowledge
  - **Status** do commit (CONFIRMED/FAILED)

### ✅ 4. **Tempo Total de Confirmação**
- Medição precisa do tempo de processamento:
  - `sentAt`: Quando a mensagem foi enviada
  - `acknowledgedAt`: Quando o ACK foi recebido
  - `processingTimeMs`: Duração total em millisegundos

## 📝 Estrutura dos Logs

### **Log de Tentativa de Publicação**
```
📤 [PUBLISH-ATTEMPT] ID=abc-123 | Hash=f4e2a1b9c8d7e6f5 | Topic=kbnt-stock-updates | Product=SMARTPHONE-XYZ | Operation=ADD | Size=256B | Producer=kbnt-producer-12ab34cd
```

### **Log de Sucesso com Commit**
```
✅ [PUBLISH-SUCCESS] ID=abc-123 | Hash=f4e2a1b9c8d7e6f5 | Topic=kbnt-stock-updates | Partition=3 | Offset=7823 | Time=45ms | Commit=CONFIRMED

🎯 [KAFKA-COMMIT] ID=abc-123 | Broker-Response=[Partition=3, Offset=7823] | Ack-Time=2024-08-30T15:30:15.234 | Message-Hash=f4e2a1b9c8d7e6f5
```

### **Log de Falha**
```
❌ [PUBLISH-FAILED] ID=abc-123 | Hash=f4e2a1b9c8d7e6f5 | Topic=kbnt-stock-updates | Error=Connection timeout | Time=5000ms | Commit=FAILED
```

### **Log de Métricas Estruturadas**
```
📊 [METRICS] PublicationId=abc-123 MessageHash=f4e2a1b9c8d7e6f5 Topic=kbnt-stock-updates Partition=3 Offset=7823 ProcessingTimeMs=45 Status=SUCCESS Producer=kbnt-producer-12ab34cd
```

## 🔍 Modelo KafkaPublicationLog

```java
@Data
@Builder
public class KafkaPublicationLog {
    private String publicationId;        // ID único da publicação
    private String messageHash;          // Hash do timestamp da mensagem
    private String topicName;           // Nome do tópico Kafka
    private Integer partition;          // Partição assignada
    private Long offset;               // Offset recebido
    private String correlationId;      // ID de correlação
    private LocalDateTime sentAt;      // Quando foi enviado
    private LocalDateTime acknowledgedAt; // Quando foi confirmado
    private Long processingTimeMs;     // Tempo total de processamento
    private PublicationStatus status;  // Status (SENT, ACKNOWLEDGED, FAILED)
    private String brokerResponse;     // Resposta do broker
    private String producerId;         // ID do producer
    private Integer messageSizeBytes;  // Tamanho da mensagem
    private String errorMessage;       // Mensagem de erro (se houver)
}
```

## 🚨 Logs de Alertas de Estoque Baixo

Implementei logs específicos para alertas automáticos:

```
⚠️ [LOW-STOCK-ALERT] ID=alert-456 | Hash=a1b2c3d4e5f6g7h8 | Product=SMARTPHONE-XYZ | Location=DC-SP01-FIL-SP001 | Quantity=5 | Threshold=10

📤 [ALERT-PUBLISH] ID=alert-456 | Hash=a1b2c3d4e5f6g7h8 | Topic=kbnt-stock-alerts | Product=SMARTPHONE-XYZ | Alert-Type=LOW_STOCK

✅ [ALERT-SUCCESS] ID=alert-456 | Hash=a1b2c3d4e5f6g7h8 | Topic=kbnt-stock-alerts | Partition=2 | Offset=1234 | Time=28ms
```

## 📊 Benefícios da Implementação

### ✅ **Rastreabilidade Completa**
- Cada mensagem possui hash único baseado no timestamp
- Correlação entre tentativa, sucesso/falha e métricas
- Rastreamento end-to-end da publicação

### ✅ **Monitoramento de Performance**
- Tempo de processamento preciso por mensagem
- Identificação de mensagens lentas ou com timeout
- Métricas estruturadas para dashboards

### ✅ **Auditoria e Compliance**
- Log completo de todas as publicações
- Detalhes do broker Kafka (partition, offset)
- Timestamp preciso de cada etapa

### ✅ **Troubleshooting**
- Logs estruturados para fácil parsing
- Correlação entre diferentes tipos de log
- Detalhes de erro para debugging

### ✅ **Alertas Proativos**
- Logs específicos para alertas de estoque baixo
- Rastreamento das publicações de alerta
- Monitoramento da saúde do sistema

## 🎯 Exemplo de Fluxo Completo de Logs

```
[15:30:00.123] 📤 [PUBLISH-ATTEMPT] ID=pub-789 | Hash=1a2b3c4d5e6f7g8h | Topic=kbnt-stock-updates | Product=TABLET-ABC | Operation=REMOVE | Size=198B | Producer=kbnt-producer-xyz123

[15:30:00.168] ✅ [PUBLISH-SUCCESS] ID=pub-789 | Hash=1a2b3c4d5e6f7g8h | Topic=kbnt-stock-updates | Partition=5 | Offset=9876 | Time=45ms | Commit=CONFIRMED

[15:30:00.169] 🎯 [KAFKA-COMMIT] ID=pub-789 | Broker-Response=[Partition=5, Offset=9876] | Ack-Time=2024-08-30T15:30:00.168 | Message-Hash=1a2b3c4d5e6f7g8h

[15:30:00.170] ⚠️ [LOW-STOCK-ALERT] ID=alert-999 | Hash=1a2b3c4d5e6f7g8h | Product=TABLET-ABC | Location=DC-SP01-FIL-SP002 | Quantity=8 | Threshold=10

[15:30:00.185] ✅ [ALERT-SUCCESS] ID=alert-999 | Hash=1a2b3c4d5e6f7g8h | Topic=kbnt-stock-alerts | Partition=1 | Offset=2468 | Time=15ms

[15:30:00.186] 📊 [METRICS] PublicationId=pub-789 MessageHash=1a2b3c4d5e6f7g8h Topic=kbnt-stock-updates Partition=5 Offset=9876 ProcessingTimeMs=45 Status=SUCCESS Producer=kbnt-producer-xyz123
```

## 🚀 Status: IMPLEMENTADO E FUNCIONAL

Todos os logs solicitados foram implementados na camada do microserviço:
- ✅ Hash do timestamp da mensagem
- ✅ Rastreamento do nome do tópico
- ✅ Logs de commit da publicação
- ✅ Tempo total de confirmação
- ✅ Logs estruturados para monitoramento
- ✅ Alertas automáticos com logs dedicados
