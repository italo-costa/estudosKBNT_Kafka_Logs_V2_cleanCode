# 🧪 Testing Layer (Camada de Testes)

A camada de testes fornece uma estratégia abrangente de validação para todo o sistema KBNT Kafka Logs, incluindo testes unitários, integração, performance e end-to-end. Esta camada garante a qualidade, confiabilidade e performance da aplicação.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Estrutura](#-estrutura)
- [Tipos de Testes](#-tipos-de-testes)
- [Testes Unitários](#-testes-unitários)
- [Testes de Integração](#-testes-de-integração)
- [Testes de Performance](#-testes-de-performance)
- [Testes End-to-End](#-testes-end-to-end)
- [Test Data Management](#-test-data-management)
- [Relatórios e Métricas](#-relatórios-e-métricas)
- [Automação](#-automação)
- [Ferramentas](#-ferramentas)

## 🎯 Visão Geral

A estratégia de testes do KBNT Kafka Logs implementa a pirâmide de testes, garantindo cobertura adequada em todos os níveis. Os testes são executados automaticamente em pipelines CI/CD e fornecem feedback rápido sobre a qualidade do código.

### Características Principais:
- **Test-Driven Development**: TDD para novas funcionalidades
- **Continuous Testing**: Execução automática em CI/CD
- **Performance Testing**: Validação de requisitos não-funcionais
- **Mutation Testing**: Validação da qualidade dos testes
- **Contract Testing**: Validação de APIs e contratos
- **Chaos Engineering**: Testes de resiliência

## 🏗️ Estrutura

```
07-testing/
├── unit/                          # Testes unitários
│   ├── domain/
│   │   ├── entities/
│   │   ├── value-objects/
│   │   └── services/
│   ├── application/
│   │   ├── use-cases/
│   │   └── services/
│   └── infrastructure/
│       ├── repositories/
│       └── adapters/
├── integration/                   # Testes de integração
│   ├── database/
│   ├── kafka/
│   ├── redis/
│   └── external-apis/
├── performance/                   # Testes de performance
│   ├── load/
│   ├── stress/
│   ├── endurance/
│   └── spike/
├── e2e/                          # Testes end-to-end
│   ├── scenarios/
│   ├── workflows/
│   └── user-journeys/
├── contract/                     # Testes de contrato
│   ├── pact/
│   └── openapi/
├── security/                     # Testes de segurança
│   ├── vulnerability/
│   └── penetration/
├── chaos/                        # Chaos engineering
│   ├── fault-injection/
│   └── failure-scenarios/
├── reports/                      # Relatórios e resultados
│   ├── coverage/
│   ├── performance/
│   └── quality/
├── fixtures/                     # Dados de teste
│   ├── json/
│   ├── sql/
│   └── kafka-messages/
├── mocks/                        # Mocks e stubs
│   ├── external-services/
│   └── infrastructure/
└── README.md                     # Este arquivo
```

## 🔬 Tipos de Testes

### Pirâmide de Testes:

```
         /\
        /  \
       / E2E \      <- Poucos, Lentos, Alto Valor
      /______\
     /        \
    /Integration\ <- Médios, Moderados, Médio Valor
   /____________\
  /              \
 /      Unit      \ <- Muitos, Rápidos, Alto ROI
/__________________\
```

### Distribuição Recomendada:
- **70%** - Testes Unitários
- **20%** - Testes de Integração  
- **10%** - Testes E2E

## 🧪 Testes Unitários

### Estrutura e Exemplos:

```java
// Teste de Entidade de Domínio
@ExtendWith(MockitoExtension.class)
class StockTest {
    
    @Test
    @DisplayName("Should update quantity when valid quantity provided")
    void shouldUpdateQuantityWhenValidQuantityProvided() {
        // Given
        ProductId productId = ProductId.of("PROD001");
        Stock stock = new Stock(
            productId, 
            Quantity.of(100), 
            Branch.of("BR001"), 
            DistributionCenter.of("DC001")
        );
        Quantity newQuantity = Quantity.of(150);
        ReasonCode reason = ReasonCode.REPLENISHMENT;
        
        // When
        stock.updateQuantity(newQuantity, reason);
        
        // Then
        assertThat(stock.getAvailableQuantity()).isEqualTo(newQuantity);
        assertThat(stock.getDomainEvents()).hasSize(1);
        assertThat(stock.getDomainEvents().get(0))
            .isInstanceOf(StockQuantityUpdatedEvent.class);
        
        StockQuantityUpdatedEvent event = (StockQuantityUpdatedEvent) stock.getDomainEvents().get(0);
        assertThat(event.getProductId()).isEqualTo(productId);
        assertThat(event.getNewQuantity()).isEqualTo(newQuantity);
        assertThat(event.getReason()).isEqualTo(reason);
    }
    
    @Test
    @DisplayName("Should throw exception when updating with negative quantity")
    void shouldThrowExceptionWhenUpdatingWithNegativeQuantity() {
        // Given
        ProductId productId = ProductId.of("PROD001");
        Stock stock = new Stock(
            productId, 
            Quantity.of(100), 
            Branch.of("BR001"), 
            DistributionCenter.of("DC001")
        );
        Quantity negativeQuantity = Quantity.of(-10);
        
        // When & Then
        assertThatThrownBy(() -> stock.updateQuantity(negativeQuantity, ReasonCode.ADJUSTMENT))
            .isInstanceOf(InvalidStockQuantityException.class)
            .hasMessage("Stock quantity cannot be negative for product: PROD001");
    }
    
    @ParameterizedTest
    @ValueSource(ints = {0, 50, 99, 100})
    @DisplayName("Should allow reservation when sufficient quantity available")
    void shouldAllowReservationWhenSufficientQuantityAvailable(int reserveAmount) {
        // Given
        Stock stock = new Stock(
            ProductId.of("PROD001"), 
            Quantity.of(100), 
            Branch.of("BR001"), 
            DistributionCenter.of("DC001")
        );
        Quantity quantityToReserve = Quantity.of(reserveAmount);
        CorrelationId correlationId = CorrelationId.generate();
        
        // When
        ReservationResult result = stock.reserveQuantity(quantityToReserve, correlationId);
        
        // Then
        assertThat(result.isSuccessful()).isTrue();
        assertThat(stock.getAvailableQuantity()).isEqualTo(Quantity.of(100 - reserveAmount));
        assertThat(stock.getReservedQuantity()).isEqualTo(quantityToReserve);
    }
}

// Teste de Value Object
class ProductIdTest {
    
    @Test
    @DisplayName("Should create valid ProductId with alphanumeric string")
    void shouldCreateValidProductIdWithAlphanumericString() {
        // Given
        String validId = "PROD123ABC";
        
        // When
        ProductId productId = ProductId.of(validId);
        
        // Then
        assertThat(productId.getValue()).isEqualTo(validId);
    }
    
    @ParameterizedTest
    @ValueSource(strings = {"", "A", "12345", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"})
    @DisplayName("Should reject invalid ProductId formats")
    void shouldRejectInvalidProductIdFormats(String invalidId) {
        // When & Then
        assertThatThrownBy(() -> ProductId.of(invalidId))
            .isInstanceOf(InvalidProductIdException.class)
            .hasMessageContaining("ProductId must be 6-20 alphanumeric characters");
    }
    
    @Test
    @DisplayName("Should ensure ProductId equality is value-based")
    void shouldEnsureProductIdEqualityIsValueBased() {
        // Given
        ProductId productId1 = ProductId.of("PROD001");
        ProductId productId2 = ProductId.of("PROD001");
        ProductId productId3 = ProductId.of("PROD002");
        
        // Then
        assertThat(productId1).isEqualTo(productId2);
        assertThat(productId1).isNotEqualTo(productId3);
        assertThat(productId1.hashCode()).isEqualTo(productId2.hashCode());
    }
}

// Teste de Application Service
@ExtendWith(MockitoExtension.class)
class StockManagementApplicationServiceTest {
    
    @Mock
    private StockRepositoryPort stockRepository;
    
    @Mock
    private StockEventPublisherPort eventPublisher;
    
    @Mock
    private StockValidationService validationService;
    
    @InjectMocks
    private StockManagementApplicationService service;
    
    @Test
    @DisplayName("Should successfully update stock when valid command provided")
    void shouldSuccessfullyUpdateStockWhenValidCommandProvided() {
        // Given
        UpdateStockQuantityCommand command = UpdateStockQuantityCommand.builder()
            .productId(ProductId.of("PROD001"))
            .branch(Branch.of("BR001"))
            .newQuantity(Quantity.of(200))
            .reason(ReasonCode.REPLENISHMENT)
            .correlationId(CorrelationId.generate())
            .timestamp(Instant.now())
            .build();
        
        Stock existingStock = new Stock(
            command.getProductId(),
            Quantity.of(100),
            command.getBranch(),
            DistributionCenter.of("DC001")
        );
        
        when(stockRepository.findByProductIdAndBranch(command.getProductId(), command.getBranch()))
            .thenReturn(Optional.of(existingStock));
        when(validationService.validateStockUpdate(any(Stock.class), any(UpdateStockQuantityCommand.class)))
            .thenReturn(ValidationResult.valid());
        when(stockRepository.save(any(Stock.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));
        when(eventPublisher.publishStockUpdatedEvent(any(StockUpdatedEvent.class)))
            .thenReturn(CompletableFuture.completedFuture(EventPublicationResult.successful()));
        
        // When
        StockUpdateResult result = service.updateStockQuantity(command);
        
        // Then
        assertThat(result.isSuccessful()).isTrue();
        assertThat(result.getProductId()).isEqualTo(command.getProductId());
        
        verify(stockRepository).findByProductIdAndBranch(command.getProductId(), command.getBranch());
        verify(validationService).validateStockUpdate(any(Stock.class), eq(command));
        verify(stockRepository).save(argThat(stock -> 
            stock.getAvailableQuantity().equals(command.getNewQuantity())
        ));
        verify(eventPublisher).publishStockUpdatedEvent(any(StockUpdatedEvent.class));
    }
}
```

### Configuração de Testes Unitários:

```xml
<!-- pom.xml dependencies for unit testing -->
<dependencies>
    <!-- JUnit 5 -->
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- Mockito -->
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- AssertJ -->
    <dependency>
        <groupId>org.assertj</groupId>
        <artifactId>assertj-core</artifactId>
        <scope>test</scope>
    </dependency>
    
    <!-- Testcontainers -->
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

## 🔗 Testes de Integração

### Base Test Configuration:

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@TestPropertySource(properties = {
    "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
    "spring.datasource.url=jdbc:tc:postgresql:15:///test_db",
    "spring.redis.host=${spring.embedded.redis.host}",
    "spring.redis.port=${spring.embedded.redis.port}"
})
@EmbeddedKafka(partitions = 3, topics = {"stock-events", "log-events"})
public abstract class IntegrationTestBase {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("test_db")
            .withUsername("test")
            .withPassword("test");
    
    @Container
    static GenericContainer<?> redis = new GenericContainer<>("redis:7-alpine")
            .withExposedPorts(6379);
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.redis.host", redis::getHost);
        registry.add("spring.redis.port", redis::getFirstMappedPort);
    }
}

// Teste de Integração Kafka
@Sql("/test-data/stock-data.sql")
class KafkaStockEventIntegrationTest extends IntegrationTestBase {
    
    @Autowired
    private StockManagementApplicationService stockService;
    
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
    
    @Autowired
    private TestKafkaConsumer testConsumer;
    
    @Test
    @Timeout(10)
    void shouldPublishStockEventWhenStockUpdated() throws InterruptedException {
        // Given
        UpdateStockQuantityCommand command = UpdateStockQuantityCommand.builder()
            .productId(ProductId.of("PROD001"))
            .branch(Branch.of("BR001"))
            .newQuantity(Quantity.of(500))
            .reason(ReasonCode.REPLENISHMENT)
            .correlationId(CorrelationId.generate())
            .timestamp(Instant.now())
            .build();
        
        // When
        StockUpdateResult result = stockService.updateStockQuantity(command);
        
        // Then
        assertThat(result.isSuccessful()).isTrue();
        
        // Verify Kafka message was published
        boolean messageReceived = testConsumer.waitForMessage("stock-events", 5, TimeUnit.SECONDS);
        assertThat(messageReceived).isTrue();
        
        KafkaStockUpdateMessage receivedMessage = testConsumer.getLastMessage("stock-events");
        assertThat(receivedMessage.getProductId()).isEqualTo("PROD001");
        assertThat(receivedMessage.getNewQuantity()).isEqualTo(BigDecimal.valueOf(500));
    }
}

// Teste de Integração Database
class JpaStockRepositoryIntegrationTest extends IntegrationTestBase {
    
    @Autowired
    private JpaStockRepositoryAdapter repository;
    
    @Autowired
    private TestEntityManager entityManager;
    
    @Test
    @Transactional
    @Rollback
    void shouldPersistAndRetrieveStock() {
        // Given
        Stock stock = new Stock(
            ProductId.of("PROD999"),
            Quantity.of(100),
            Branch.of("BR999"),
            DistributionCenter.of("DC999")
        );
        
        // When
        Stock savedStock = repository.save(stock);
        entityManager.flush();
        entityManager.clear();
        
        Optional<Stock> retrievedStock = repository.findByProductIdAndBranch(
            ProductId.of("PROD999"), 
            Branch.of("BR999")
        );
        
        // Then
        assertThat(retrievedStock).isPresent();
        assertThat(retrievedStock.get().getProductId()).isEqualTo(stock.getProductId());
        assertThat(retrievedStock.get().getAvailableQuantity()).isEqualTo(stock.getAvailableQuantity());
    }
}
```

## ⚡ Testes de Performance

### Estrutura de Performance Testing:

```python
# performance-test-complete.py
import asyncio
import aiohttp
import time
import statistics
from dataclasses import dataclass
from typing import List, Dict
import json

@dataclass
class PerformanceMetrics:
    total_requests: int
    successful_requests: int
    failed_requests: int
    avg_response_time: float
    p95_response_time: float
    p99_response_time: float
    requests_per_second: float
    error_rate: float

class KBNTPerformanceTest:
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.response_times = []
        self.errors = []
        
    async def send_stock_update_request(self, session: aiohttp.ClientSession, 
                                      product_id: str, quantity: int) -> Dict:
        """Envia uma requisição de atualização de estoque"""
        start_time = time.time()
        
        payload = {
            "productId": product_id,
            "branch": "BR001",
            "newQuantity": quantity,
            "reason": "REPLENISHMENT",
            "correlationId": f"test-{int(time.time() * 1000000)}"
        }
        
        try:
            async with session.put(
                f"{self.base_url}/api/v1/stock/update",
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                end_time = time.time()
                response_time = (end_time - start_time) * 1000  # ms
                
                return {
                    "success": response.status == 200,
                    "status_code": response.status,
                    "response_time": response_time,
                    "error": None
                }
        except Exception as e:
            end_time = time.time()
            response_time = (end_time - start_time) * 1000
            
            return {
                "success": False,
                "status_code": None,
                "response_time": response_time,
                "error": str(e)
            }
    
    async def run_load_test(self, concurrent_users: int = 100, 
                          duration_seconds: int = 60,
                          ramp_up_seconds: int = 10) -> PerformanceMetrics:
        """Executa teste de carga"""
        print(f"🚀 Starting load test: {concurrent_users} concurrent users for {duration_seconds}s")
        
        # Ramp-up phase
        start_time = time.time()
        end_time = start_time + duration_seconds
        
        connector = aiohttp.TCPConnector(limit=concurrent_users * 2)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            tasks = []
            request_count = 0
            
            # Criar tarefas para usuários concorrentes
            while time.time() < end_time:
                if len(tasks) < concurrent_users:
                    product_id = f"PROD{(request_count % 1000):03d}"
                    quantity = 100 + (request_count % 900)
                    
                    task = asyncio.create_task(
                        self.send_stock_update_request(session, product_id, quantity)
                    )
                    tasks.append(task)
                    request_count += 1
                    
                    # Rate limiting durante ramp-up
                    if time.time() - start_time < ramp_up_seconds:
                        await asyncio.sleep(0.1)
                
                # Remover tarefas completadas
                completed_tasks = [task for task in tasks if task.done()]
                for task in completed_tasks:
                    result = await task
                    self.response_times.append(result["response_time"])
                    if not result["success"]:
                        self.errors.append(result)
                    tasks.remove(task)
                
                await asyncio.sleep(0.001)  # Pequena pausa para não sobrecarregar
            
            # Aguardar tarefas restantes
            for task in tasks:
                result = await task
                self.response_times.append(result["response_time"])
                if not result["success"]:
                    self.errors.append(result)
        
        return self.calculate_metrics(duration_seconds)
    
    def calculate_metrics(self, duration: float) -> PerformanceMetrics:
        """Calcula métricas de performance"""
        total_requests = len(self.response_times)
        failed_requests = len(self.errors)
        successful_requests = total_requests - failed_requests
        
        if not self.response_times:
            return PerformanceMetrics(0, 0, 0, 0, 0, 0, 0, 100.0)
        
        avg_response_time = statistics.mean(self.response_times)
        p95_response_time = statistics.quantiles(self.response_times, n=20)[18]  # 95th percentile
        p99_response_time = statistics.quantiles(self.response_times, n=100)[98]  # 99th percentile
        requests_per_second = total_requests / duration
        error_rate = (failed_requests / total_requests) * 100 if total_requests > 0 else 0
        
        return PerformanceMetrics(
            total_requests=total_requests,
            successful_requests=successful_requests,
            failed_requests=failed_requests,
            avg_response_time=avg_response_time,
            p95_response_time=p95_response_time,
            p99_response_time=p99_response_time,
            requests_per_second=requests_per_second,
            error_rate=error_rate
        )
    
    async def run_stress_test(self) -> Dict[str, PerformanceMetrics]:
        """Executa teste de stress com cargas crescentes"""
        stress_levels = [50, 100, 200, 500, 1000]
        results = {}
        
        for level in stress_levels:
            print(f"🔥 Running stress test with {level} concurrent users")
            self.response_times.clear()
            self.errors.clear()
            
            metrics = await self.run_load_test(
                concurrent_users=level,
                duration_seconds=30,
                ramp_up_seconds=5
            )
            
            results[f"{level}_users"] = metrics
            
            # Pause entre testes
            await asyncio.sleep(5)
        
        return results

async def main():
    """Função principal de teste"""
    test = KBNTPerformanceTest()
    
    print("🎯 KBNT Kafka Logs - Performance Testing Suite")
    print("=" * 60)
    
    # Teste de carga padrão
    print("\n📊 Running standard load test...")
    load_metrics = await test.run_load_test(
        concurrent_users=100,
        duration_seconds=60
    )
    
    print(f"✅ Load Test Results:")
    print(f"   Total Requests: {load_metrics.total_requests}")
    print(f"   Successful: {load_metrics.successful_requests}")
    print(f"   Failed: {load_metrics.failed_requests}")
    print(f"   RPS: {load_metrics.requests_per_second:.2f}")
    print(f"   Avg Response Time: {load_metrics.avg_response_time:.2f}ms")
    print(f"   P95 Response Time: {load_metrics.p95_response_time:.2f}ms")
    print(f"   P99 Response Time: {load_metrics.p99_response_time:.2f}ms")
    print(f"   Error Rate: {load_metrics.error_rate:.2f}%")
    
    # Teste de stress
    print("\n🔥 Running stress test...")
    stress_results = await test.run_stress_test()
    
    print(f"\n📈 Stress Test Results:")
    for level, metrics in stress_results.items():
        print(f"   {level}: {metrics.requests_per_second:.0f} RPS, "
              f"{metrics.p95_response_time:.0f}ms P95, "
              f"{metrics.error_rate:.1f}% errors")
    
    # Salvar resultados
    timestamp = int(time.time())
    report = {
        "timestamp": timestamp,
        "load_test": load_metrics.__dict__,
        "stress_test": {k: v.__dict__ for k, v in stress_results.items()}
    }
    
    with open(f"reports/performance_report_{timestamp}.json", "w") as f:
        json.dump(report, f, indent=2)
    
    print(f"\n📄 Report saved: performance_report_{timestamp}.json")

if __name__ == "__main__":
    asyncio.run(main())
```

## 📊 Relatórios e Métricas

### Coverage Report Configuration:

```xml
<!-- Jacoco Plugin Configuration -->
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.8</version>
    <configuration>
        <rules>
            <rule>
                <element>CLASS</element>
                <limits>
                    <limit>
                        <counter>LINE</counter>
                        <value>COVEREDRATIO</value>
                        <minimum>0.80</minimum>
                    </limit>
                    <limit>
                        <counter>BRANCH</counter>
                        <value>COVEREDRATIO</value>
                        <minimum>0.70</minimum>
                    </limit>
                </limits>
            </rule>
        </rules>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
        <execution>
            <id>check</id>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### Quality Gates:

- **Unit Test Coverage**: ≥ 80%
- **Integration Test Coverage**: ≥ 60%
- **Performance Regression**: < 10%
- **Security Vulnerabilities**: 0 Critical/High
- **Code Quality**: SonarQube Quality Gate = Passed

---

**Autor**: KBNT Development Team  
**Versão**: 2.1.0  
**Última Atualização**: Janeiro 2025
