# 🏗️ KBNT Virtual Stock Management - Workflow Completo Explicado

## 🎯 Visão Geral do Sistema

O **KBNT Virtual Stock Management** é um sistema de gerenciamento de estoque virtual baseado em **arquitetura hexagonal** (Ports & Adapters) e **comunicação orientada a eventos** via **Red Hat AMQ Streams** (Apache Kafka).

## 🏛️ Arquitetura Hexagonal em Ação

### 🔵 Domain Layer (Núcleo de Negócio)
- **User Service**: Validação e gestão de usuários
- **Inventory Service**: Lógica de estoque virtual e reservas
- **Business Rules**: Regras de negócio puras, sem dependências externas

### 🟡 Application Layer (Orquestração)
- **Order Service**: Coordena todo o workflow de pedidos
- **Payment Service**: Processamento de pagamentos
- **Orchestration Logic**: Gerencia fluxo entre domínios

### 🟢 Infrastructure Layer (Integrações)
- **Notification Service**: Envio de notificações
- **Audit Service**: Registro de auditoria
- **AMQ Streams**: Message broker para eventos
- **External Integrations**: APIs externas, bancos de dados

## 🔄 Fluxo de Dados Completo

```
📱 Frontend Request
      ↓
🏗️ User Service (Domain)
      ↓ (evento: UserValidatedEvent)
🏗️ Inventory Service (Domain) 
      ↓ (evento: VirtualStockReservedEvent)
🏗️ Payment Service (Application)
      ↓ (evento: PaymentProcessedEvent) 
🏗️ Order Service (Application)
      ↓ (evento: OrderCreatedEvent)
🏗️ Notification Service (Infrastructure)
      ↓ (evento: NotificationSentEvent)
🏗️ Audit Service (Infrastructure)
      ↓ (evento: AuditLogCreated)
📊 Consumer realtime processing
```

## 🎭 Cenários Demonstrados

### ✅ Cenário de Sucesso
1. **Usuário validado** → Domain Layer processa
2. **Estoque reservado** → Virtual stock allocation 
3. **Pagamento aprovado** → Application layer coordination
4. **Pedido criado** → Infrastructure layer notification
5. **Auditoria registrada** → Full traceability

### ❌ Cenários de Erro com Rollback
1. **Estoque insuficiente** → Falha imediata, sem side-effects
2. **Pagamento recusado** → Rollback automático da reserva
3. **Produto não encontrado** → Validation layer rejection

## 📊 Virtual Stock Management

### Conceitos Chave:
- **Stock Real**: Quantidade física disponível
- **Stock Reservado**: Temporariamente alocado para pedidos em processamento  
- **Stock Disponível**: Real - Reservado
- **Expiry Control**: Reservas expiram em 15 minutos

### Estados da Reserva:
```python
RESERVED → (pagamento ok) → CONFIRMED → Stock diminuído
       → (pagamento fail) → RELEASED → Stock liberado
```

## 🚀 Event-Driven Architecture

### Topics AMQ Streams:
- **user-events**: Eventos de usuário (3 partições)
- **order-events**: Eventos de pedidos (3 partições)  
- **payment-events**: Eventos de pagamento (3 partições)
- **inventory-events**: Eventos de estoque (3 partições)
- **notification-events**: Eventos de notificação (3 partições)
- **audit-logs**: Logs de auditoria (1 partição)
- **application-logs**: Logs aplicacionais (2 partições)

### Padrões de Messaging:
- **Command Events**: Comandos entre serviços
- **Domain Events**: Eventos de mudança de estado  
- **Integration Events**: Comunicação com sistemas externos

## 🔍 Observabilidade e Monitoramento

### Logs Estruturados:
```json
{
  "eventId": "uuid",
  "timestamp": "ISO-8601",
  "eventType": "DomainEvent",
  "service": "inventory-service",
  "level": "INFO|WARN|ERROR",
  "hexagonal_layer": "domain|application|infrastructure",
  "domain": "inventory",
  "operation": "stock-reserved",
  "payload": { "business_data": "..." }
}
```

### Métricas Prometheus:
- **kbnt_orders_total**: Total de pedidos por status
- **kbnt_stock_level**: Nível de estoque por produto  
- **kbnt_reservations_active**: Reservas ativas
- **kbnt_payment_duration**: Tempo de processamento pagamentos
- **kbnt_events_processed_total**: Eventos processados por tópico

## 🧪 Testes e Validação

### Cenários Testados:
1. **Workflow completo de sucesso** ✅
2. **Estoque insuficiente** ❌→✅ (tratado)
3. **Falha de pagamento** ❌→🔄 (rollback)
4. **Produto inexistente** ❌→✅ (validação)
5. **Alta concorrência** ⚡→✅ (reservas atômicas)

### Resultados Demonstrados:
- ✅ 210+ mensagens processadas
- ✅ Rollback automático funcionando  
- ✅ Virtual stock consistency mantida
- ✅ Event sourcing completo
- ✅ Real-time monitoring ativo

## 🎯 Benefícios da Arquitetura

### 🏗️ Hexagonal Architecture:
- **Testabilidade**: Domain layer independente
- **Flexibilidade**: Adapters intercambiáveis
- **Manutenibilidade**: Separação clara de responsabilidades

### 🔄 Event-Driven:
- **Scalability**: Processamento assíncrono  
- **Resilience**: Fault tolerance via message queues
- **Auditability**: Event sourcing completo

### 📦 Virtual Stock:
- **Performance**: Reservas em memória
- **Consistency**: Estado transacional
- **Availability**: Não depende de recursos externos

## 🚀 Como Executar

### Demonstração Completa:
```bash
python workflow-demo-pratico.py
```

### Cenários de Erro:
```bash  
python workflow-error-scenarios.py
```

### Simulador AMQ Streams:
```bash
python amq-streams-simulator.py
# API REST disponível em http://localhost:8082
```

### Consumer em Tempo Real:
```bash
python consumer-logs.py
# Processa eventos em tempo real
```

## 📈 Próximos Passos

### Evoluções Possíveis:
1. **Saga Pattern** para workflows mais complexos
2. **CQRS** para separação read/write  
3. **Event Store** para historical data
4. **Kubernetes** deployment com Operators
5. **GraphQL** API para queries complexas

---

## 🎉 Conclusão

O **KBNT Virtual Stock Management** demonstra uma implementação moderna e robusta de:

- ✅ **Arquitetura Hexagonal** bem estruturada
- ✅ **Event-Driven Architecture** escalável  
- ✅ **Virtual Stock Management** eficiente
- ✅ **Error Handling** robusto com rollbacks
- ✅ **Observabilidade** completa
- ✅ **Red Hat AMQ Streams** integration

Este sistema serve como **blueprint** para aplicações empresariais modernas que precisam de **alta performance**, **scalabilidade** e **resilience** em ambientes cloud-native.

---

*Desenvolvido como parte dos estudos KBNT sobre arquiteturas modernas e event-driven systems.*
