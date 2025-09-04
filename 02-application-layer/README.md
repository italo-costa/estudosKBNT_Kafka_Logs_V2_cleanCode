# 🏛️ Application Layer - KBNT Kafka Logs
## Camada de Aplicação / Orquestração de Casos de Uso

---

## 🎯 **Responsabilidade**
Esta camada orquestra os casos de uso de negócio, coordena workflows entre componentes e gerencia a lógica de aplicação sem conter regras de domínio.

---

## 📁 **Estrutura de Componentes**

### **🎯 Use Cases**
- **Localização**: `./use-cases/`
- **Responsabilidade**: Implementação de casos de uso específicos
- **Padrão**: Command/Query pattern
- **Exemplos**:
  - `StockManagementUseCase`
  - `LogProcessingUseCase`
  - `AnalyticsUseCase`
  - `ReservationUseCase`

### **⚙️ Application Services**
- **Localização**: `./application-services/`
- **Responsabilidade**: Coordenação entre use cases e infraestrutura
- **Padrão**: Service pattern
- **Exemplos**:
  - `StockApplicationService`
  - `LogApplicationService`
  - `EventPublishingService`
  - `NotificationService`

### **🔄 Workflow Orchestrators**
- **Localização**: `./workflow-orchestrators/`
- **Responsabilidade**: Orquestração de processos complexos
- **Padrão**: Saga pattern, Process Manager
- **Exemplos**:
  - `StockReservationSaga`
  - `OrderProcessingWorkflow`
  - `EventProcessingOrchestrator`

### **📨 Command Handlers**
- **Localização**: `./command-handlers/`
- **Responsabilidade**: Processamento de comandos CQRS
- **Padrão**: CQRS Command Handler
- **Exemplos**:
  - `CreateStockCommandHandler`
  - `UpdateStockCommandHandler`
  - `ReserveStockCommandHandler`

---

## 🔄 **Fluxo de Execução**

### **Request Processing Flow**
```
📱 Presentation Layer
    ↓ Request DTO
🎯 Use Case (Entry Point)
    ↓ Business validation
⚙️ Application Service
    ↓ Workflow coordination
🔄 Workflow Orchestrator
    ↓ Domain interaction
💼 Domain Layer
```

### **Event Processing Flow**
```
📨 External Event
    ↓ Event deserialization
📨 Command Handler
    ↓ Command validation
🎯 Use Case Execution
    ↓ Business processing
⚙️ Application Service
    ↓ Side effects
🔄 Event Publishing
```

---

## 💼 **Use Cases Implementados**

### **📦 Stock Management Use Cases**
```java
// Exemplo de estrutura
public interface StockManagementUseCase {
    // Query operations
    List<Stock> getAllStocks();
    Optional<Stock> getStockById(StockId id);
    List<Stock> getStocksByDistributionCenter(DistributionCenter dc);
    
    // Command operations  
    StockCreationResult createStock(CreateStockCommand command);
    StockUpdateResult updateStock(UpdateStockCommand command);
    StockReservationResult reserveStock(ReserveStockCommand command);
    
    // Business queries
    boolean isLowStock(StockId id);
    List<Stock> getLowStockItems();
    StockAvailability checkAvailability(ProductId productId, Quantity quantity);
}
```

### **📊 Analytics Use Cases**
```java
public interface AnalyticsUseCase {
    PerformanceMetrics getSystemPerformance(TimeRange range);
    List<StockMovement> getStockMovements(DistributionCenter dc, TimeRange range);
    AlertSummary getActiveAlerts();
    ReportData generateStockReport(ReportCriteria criteria);
}
```

### **📝 Log Processing Use Cases**
```java
public interface LogProcessingUseCase {
    LogProcessingResult processStockEvent(StockEvent event);
    List<LogEntry> searchLogs(LogSearchCriteria criteria);
    LogAggregation aggregateLogsByTimeRange(TimeRange range);
    AlertResult evaluateLogForAlerts(LogEntry entry);
}
```

---

## ⚙️ **Application Services Patterns**

### **📦 Stock Application Service**
```java
@Service
@Transactional
public class StockApplicationService {
    
    private final StockRepository stockRepository;
    private final EventPublisher eventPublisher;
    private final CacheManager cacheManager;
    
    public StockCreationResult createStock(CreateStockCommand command) {
        // 1. Validation
        validateCommand(command);
        
        // 2. Domain object creation
        Stock stock = Stock.create(command.getProductId(), 
                                 command.getQuantity(), 
                                 command.getDistributionCenter());
        
        // 3. Persistence
        Stock savedStock = stockRepository.save(stock);
        
        // 4. Event publishing
        StockCreatedEvent event = new StockCreatedEvent(savedStock);
        eventPublisher.publish(event);
        
        // 5. Cache update
        cacheManager.put(savedStock.getId(), savedStock);
        
        return StockCreationResult.success(savedStock);
    }
}
```

---

## 🔄 **Workflow Orchestration Patterns**

### **📦 Stock Reservation Saga**
```java
@Component
public class StockReservationSaga {
    
    @SagaOrchestrationStart
    public void handle(ReserveStockCommand command) {
        // Step 1: Check availability
        choreography.send(new CheckAvailabilityCommand(command.getStockId(), 
                                                       command.getQuantity()));
    }
    
    @SagaOrchestrationStep
    public void handle(AvailabilityCheckedEvent event) {
        if (event.isAvailable()) {
            // Step 2: Reserve stock
            choreography.send(new CreateReservationCommand(event.getStockId(), 
                                                          event.getQuantity()));
        } else {
            // Compensation: Reject reservation
            choreography.send(new RejectReservationCommand(event.getRequestId()));
        }
    }
    
    @SagaOrchestrationStep
    public void handle(ReservationCreatedEvent event) {
        // Step 3: Update availability
        choreography.send(new UpdateAvailabilityCommand(event.getStockId(), 
                                                       event.getReservedQuantity()));
    }
}
```

---

## 📨 **CQRS Command Handling**

### **Command Handler Pattern**
```java
@Component
public class UpdateStockCommandHandler {
    
    private final StockRepository repository;
    private final EventBus eventBus;
    
    @CommandHandler
    public StockUpdateResult handle(UpdateStockCommand command) {
        // 1. Load aggregate
        Stock stock = repository.findById(command.getStockId())
            .orElseThrow(() -> new StockNotFoundException(command.getStockId()));
        
        // 2. Execute business logic
        StockUpdateResult result = stock.updateQuantity(command.getNewQuantity(), 
                                                        command.getReason());
        
        // 3. Save changes
        if (result.isSuccess()) {
            repository.save(stock);
            
            // 4. Publish domain events
            stock.getUncommittedEvents().forEach(eventBus::publish);
            stock.markEventsAsCommitted();
        }
        
        return result;
    }
}
```

---

## ⚡ **Performance Characteristics**

### **Use Case Execution Times (Enterprise Strategy)**
- **Simple Queries**: 0.5ms - 2ms
- **Complex Business Operations**: 1ms - 5ms
- **Workflow Orchestration**: 2ms - 8ms
- **Event Processing**: 0.1ms - 1ms

### **Throughput Metrics**
- **Use Case Executions**: 27,364/sec
- **Command Processing**: 15,000/sec
- **Event Processing**: 99,004/sec
- **Workflow Coordination**: 5,000/sec

---

## 🧪 **Testing Strategies**

### **Use Case Testing**
```java
@ExtendWith(MockitoExtension.class)
class StockManagementUseCaseTest {
    
    @Mock private StockRepository stockRepository;
    @Mock private EventPublisher eventPublisher;
    
    @InjectMocks
    private StockManagementUseCaseImpl useCase;
    
    @Test
    void shouldCreateStockSuccessfully() {
        // Given
        CreateStockCommand command = new CreateStockCommand(
            ProductId.of("PROD-001"),
            Quantity.of(100),
            DistributionCenter.of("DC-SP01")
        );
        
        // When
        StockCreationResult result = useCase.createStock(command);
        
        // Then
        assertThat(result.isSuccess()).isTrue();
        verify(stockRepository).save(any(Stock.class));
        verify(eventPublisher).publish(any(StockCreatedEvent.class));
    }
}
```

### **Integration Testing**
```java
@SpringBootTest
@TestMethodOrder(OrderAnnotation.class)
class StockWorkflowIntegrationTest {
    
    @Autowired private StockApplicationService stockService;
    @Autowired private TestEventCollector eventCollector;
    
    @Test
    @Order(1)
    void shouldCompleteStockReservationWorkflow() {
        // Given
        StockId stockId = createTestStock();
        ReserveStockCommand command = new ReserveStockCommand(stockId, Quantity.of(10));
        
        // When
        StockReservationResult result = stockService.reserveStock(command);
        
        // Then
        assertThat(result.isSuccess()).isTrue();
        assertThat(eventCollector.getEvents()).hasSize(3);
        assertThat(eventCollector.getLastEvent()).isInstanceOf(StockReservedEvent.class);
    }
}
```

---

## 🔧 **Configuration & Dependencies**

### **Spring Configuration**
```yaml
# application.yml
app:
  application-layer:
    use-cases:
      timeout-ms: 5000
      retry-attempts: 3
    
    workflows:
      saga-timeout-minutes: 15
      compensation-timeout-minutes: 5
    
    commands:
      async-processing: true
      batch-size: 100
      
    events:
      publishing-strategy: async
      retry-policy: exponential-backoff
```

### **Dependency Injection**
```java
@Configuration
@EnableAsync
@EnableTransactionManagement
public class ApplicationLayerConfiguration {
    
    @Bean
    public EventBus eventBus() {
        return new AsyncEventBus(Executors.newFixedThreadPool(10));
    }
    
    @Bean
    public SagaManager sagaManager() {
        return new SagaManagerImpl(eventBus(), sagaRepository());
    }
    
    @Bean
    @ConditionalOnProperty("app.application-layer.commands.async-processing")
    public CommandBus asyncCommandBus() {
        return new AsyncCommandBus(commandHandlers());
    }
}
```

---

## 📊 **Monitoring & Metrics**

### **Use Case Metrics**
- Execution time distribution
- Success/failure rates
- Throughput per use case
- Resource utilization

### **Workflow Metrics**
- Saga completion rates
- Compensation execution frequency
- Step execution times
- Error recovery statistics

### **Command Metrics**
- Command processing latency
- Queue sizes
- Dead letter queue statistics
- Handler performance

---

## 🎯 **Integration Points**

### **Upstream Dependencies**
- **Presentation Layer**: Receives DTOs and commands
- **External Events**: Processes events from message brokers

### **Downstream Dependencies**
- **Domain Layer**: Invokes business logic
- **Infrastructure Layer**: Persists data and publishes events

---

## 📚 **Best Practices**

### **Use Case Design**
- Single responsibility per use case
- Clear input/output contracts
- Minimal external dependencies
- Comprehensive error handling

### **Application Service Patterns**
- Transaction boundary management
- Event publishing strategies
- Cache management
- Performance optimization

### **Workflow Orchestration**
- Saga pattern for distributed transactions
- Compensation actions for rollback
- Idempotent operations
- Timeout and retry policies
