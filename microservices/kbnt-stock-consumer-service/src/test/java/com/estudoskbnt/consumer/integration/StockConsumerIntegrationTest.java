package com.estudoskbnt.consumer.integration;

import com.estudoskbnt.consumer.entity.ConsumptionLog;
import com.estudoskbnt.consumer.model.StockUpdateMessage;
import com.estudoskbnt.consumer.repository.ConsumptionLogRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.tomakehurst.wiremock.WireMockServer;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.*;

/**
 * End-to-End Integration Tests
 * 
 * Tests complete workflow: Kafka message consumption → External API processing → Database logging
 * Uses Testcontainers for PostgreSQL and WireMock for external API simulation.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@ActiveProfiles("test")
@DirtiesContext
@EmbeddedKafka(
    topics = {"stock-updates", "high-priority-stock-updates"},
    brokerProperties = {
        "listeners=PLAINTEXT://localhost:29092",
        "port=29092",
        "auto.create.topics.enable=true"
    }
)
@DisplayName("End-to-End Integration Tests")
class StockConsumerIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgreSQLContainer = new PostgreSQLContainer<>("postgres:15")
            .withDatabaseName("integration_test_db")
            .withUsername("test_user")
            .withPassword("test_password");
    
    private static WireMockServer wireMockServer;
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    @Autowired
    private ConsumptionLogRepository consumptionLogRepository;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgreSQLContainer::getJdbcUrl);
        registry.add("spring.datasource.username", postgreSQLContainer::getUsername);
        registry.add("spring.datasource.password", postgreSQLContainer::getPassword);
        registry.add("app.kafka.bootstrap-servers", () -> "localhost:29092");
        registry.add("app.external-api.stock-service.base-url", () -> "http://localhost:" + wireMockServer.port());
    }
    
    @BeforeAll
    static void setUp() {
        wireMockServer = new WireMockServer(0); // Random port
        wireMockServer.start();
    }
    
    @AfterAll
    static void tearDown() {
        if (wireMockServer != null) {
            wireMockServer.stop();
        }
    }
    
    @BeforeEach
    void setUpEach() {
        consumptionLogRepository.deleteAll();
        wireMockServer.resetAll();
    }
    
    @Test
    @DisplayName("Should process complete workflow: Kafka → API → Database")
    void shouldProcessCompleteWorkflow() throws Exception {
        // Arrange
        setupSuccessfulApiResponses();
        
        StockUpdateMessage message = createValidStockMessage();
        String messageJson = objectMapper.writeValueAsString(message);
        
        // Act - Send message to Kafka
        kafkaTemplate.send("stock-updates", "test-key", messageJson);
        
        // Assert - Wait for message processing and verify results
        await().atMost(30, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    List<ConsumptionLog> logs = consumptionLogRepository.findByCorrelationId(message.getCorrelationId())
                            .map(List::of)
                            .orElse(List.of());
                    
                    assertFalse(logs.isEmpty(), "Consumption log should be created");
                    
                    ConsumptionLog log = logs.get(0);
                    assertEquals(message.getCorrelationId(), log.getCorrelationId());
                    assertEquals(message.getProductId(), log.getProductId());
                    assertEquals("stock-updates", log.getTopic());
                    assertEquals(ConsumptionLog.ProcessingStatus.SUCCESS, log.getStatus());
                    assertNotNull(log.getProcessingCompletedAt());
                    assertNotNull(log.getTotalProcessingTimeMs());
                    assertEquals(200, log.getApiResponseCode());
                });
        
        // Verify API calls were made
        wireMockServer.verify(getRequestedFor(urlEqualTo("/api/products/validate/" + message.getProductId())));
        wireMockServer.verify(postRequestedFor(urlEqualTo("/api/stock/process")));
        wireMockServer.verify(postRequestedFor(urlEqualTo("/api/notifications/stock-processed")));
    }
    
    @Test
    @DisplayName("Should handle high priority messages in dedicated topic")
    void shouldHandleHighPriorityMessages() throws Exception {
        // Arrange
        setupSuccessfulApiResponses();
        
        StockUpdateMessage highPriorityMessage = createValidStockMessage();
        highPriorityMessage.setPriority("HIGH");
        highPriorityMessage.setCorrelationId("high-priority-test-123");
        
        String messageJson = objectMapper.writeValueAsString(highPriorityMessage);
        
        // Act
        kafkaTemplate.send("high-priority-stock-updates", "high-priority-key", messageJson);
        
        // Assert
        await().atMost(30, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    List<ConsumptionLog> logs = consumptionLogRepository.findByCorrelationId("high-priority-test-123")
                            .map(List::of)
                            .orElse(List.of());
                    
                    assertFalse(logs.isEmpty());
                    ConsumptionLog log = logs.get(0);
                    assertEquals("HIGH", log.getPriority());
                    assertEquals(ConsumptionLog.ProcessingStatus.SUCCESS, log.getStatus());
                });
    }
    
    @Test
    @DisplayName("Should handle API validation failure")
    void shouldHandleApiValidationFailure() throws Exception {
        // Arrange
        setupValidationFailureResponse();
        
        StockUpdateMessage message = createValidStockMessage();
        message.setCorrelationId("validation-failure-test-123");
        String messageJson = objectMapper.writeValueAsString(message);
        
        // Act
        kafkaTemplate.send("stock-updates", "validation-fail-key", messageJson);
        
        // Assert
        await().atMost(30, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    List<ConsumptionLog> logs = consumptionLogRepository.findByCorrelationId("validation-failure-test-123")
                            .map(List::of)
                            .orElse(List.of());
                    
                    assertFalse(logs.isEmpty());
                    ConsumptionLog log = logs.get(0);
                    assertEquals(ConsumptionLog.ProcessingStatus.FAILED, log.getStatus());
                    assertTrue(log.getErrorMessage().contains("Product validation failed"));
                });
        
        wireMockServer.verify(getRequestedFor(urlEqualTo("/api/products/validate/" + message.getProductId())));
        wireMockServer.verify(0, postRequestedFor(urlEqualTo("/api/stock/process")));
    }
    
    @Test
    @DisplayName("Should handle API processing failure with proper error logging")
    void shouldHandleApiProcessingFailure() throws Exception {
        // Arrange
        setupApiProcessingFailure();
        
        StockUpdateMessage message = createValidStockMessage();
        message.setCorrelationId("processing-failure-test-123");
        String messageJson = objectMapper.writeValueAsString(message);
        
        // Act
        kafkaTemplate.send("stock-updates", "processing-fail-key", messageJson);
        
        // Assert
        await().atMost(30, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    List<ConsumptionLog> logs = consumptionLogRepository.findByCorrelationId("processing-failure-test-123")
                            .map(List::of)
                            .orElse(List.of());
                    
                    assertFalse(logs.isEmpty());
                    ConsumptionLog log = logs.get(0);
                    assertEquals(ConsumptionLog.ProcessingStatus.FAILED, log.getStatus());
                    assertEquals(500, log.getApiResponseCode());
                    assertNotNull(log.getErrorMessage());
                });
        
        // Verify failure notification was sent
        wireMockServer.verify(postRequestedFor(urlEqualTo("/api/notifications/stock-processed"))
                .withRequestBody(containing("\"success\":false")));
    }
    
    @Test
    @DisplayName("Should handle multiple concurrent messages")
    void shouldHandleMultipleConcurrentMessages() throws Exception {
        // Arrange
        setupSuccessfulApiResponses();
        
        int messageCount = 5;
        
        // Act - Send multiple messages concurrently
        for (int i = 0; i < messageCount; i++) {
            StockUpdateMessage message = createValidStockMessage();
            message.setCorrelationId("concurrent-test-" + i);
            message.setProductId("PROD-" + String.format("%03d", i));
            
            String messageJson = objectMapper.writeValueAsString(message);
            kafkaTemplate.send("stock-updates", "concurrent-key-" + i, messageJson);
        }
        
        // Assert - Wait for all messages to be processed
        await().atMost(60, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    long successfulLogs = consumptionLogRepository.count();
                    assertEquals(messageCount, successfulLogs, "All messages should be processed");
                    
                    // Verify all are successful
                    List<ConsumptionLog> allLogs = consumptionLogRepository.findAll();
                    long successCount = allLogs.stream()
                            .mapToLong(log -> log.getStatus() == ConsumptionLog.ProcessingStatus.SUCCESS ? 1 : 0)
                            .sum();
                    assertEquals(messageCount, successCount, "All messages should be successfully processed");
                });
    }
    
    @Test
    @DisplayName("Should track processing time metrics accurately")
    void shouldTrackProcessingTimeMetrics() throws Exception {
        // Arrange
        setupSuccessfulApiResponsesWithDelay(500); // 500ms delay
        
        StockUpdateMessage message = createValidStockMessage();
        message.setCorrelationId("performance-test-123");
        String messageJson = objectMapper.writeValueAsString(message);
        
        // Act
        kafkaTemplate.send("stock-updates", "performance-key", messageJson);
        
        // Assert
        await().atMost(30, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    List<ConsumptionLog> logs = consumptionLogRepository.findByCorrelationId("performance-test-123")
                            .map(List::of)
                            .orElse(List.of());
                    
                    assertFalse(logs.isEmpty());
                    ConsumptionLog log = logs.get(0);
                    
                    assertNotNull(log.getProcessingStartedAt());
                    assertNotNull(log.getProcessingCompletedAt());
                    assertNotNull(log.getTotalProcessingTimeMs());
                    
                    // Processing time should be at least the API delay (500ms) 
                    // but allow for some variance due to processing overhead
                    assertTrue(log.getTotalProcessingTimeMs() >= 400, 
                            "Processing time should account for API delay");
                    assertTrue(log.getTotalProcessingTimeMs() < 10000, 
                            "Processing time should be reasonable");
                });
    }
    
    @Test
    @DisplayName("Should store comprehensive audit information")
    void shouldStoreComprehensiveAuditInformation() throws Exception {
        // Arrange
        setupSuccessfulApiResponses();
        
        StockUpdateMessage message = createValidStockMessage();
        message.setCorrelationId("audit-test-123");
        String messageJson = objectMapper.writeValueAsString(message);
        
        // Act
        kafkaTemplate.send("stock-updates", "audit-key", messageJson);
        
        // Assert
        await().atMost(30, TimeUnit.SECONDS)
                .untilAsserted(() -> {
                    List<ConsumptionLog> logs = consumptionLogRepository.findByCorrelationId("audit-test-123")
                            .map(List::of)
                            .orElse(List.of());
                    
                    assertFalse(logs.isEmpty());
                    ConsumptionLog log = logs.get(0);
                    
                    // Verify Kafka metadata
                    assertEquals("stock-updates", log.getTopic());
                    assertNotNull(log.getPartitionId());
                    assertNotNull(log.getOffset());
                    
                    // Verify message content
                    assertEquals(message.getProductId(), log.getProductId());
                    assertEquals(message.getQuantity(), log.getQuantity());
                    assertEquals(message.getPrice(), log.getPrice());
                    assertEquals(message.getOperation(), log.getOperation());
                    assertEquals(message.getHash(), log.getMessageHash());
                    
                    // Verify processing metadata
                    assertNotNull(log.getConsumedAt());
                    assertEquals(0, log.getRetryCount());
                    assertEquals("NORMAL", log.getPriority());
                    assertEquals(ConsumptionLog.ProcessingStatus.SUCCESS, log.getStatus());
                });
    }
    
    // Helper methods
    
    private StockUpdateMessage createValidStockMessage() {
        return StockUpdateMessage.builder()
                .correlationId("integration-test-123")
                .productId("PROD-TEST-001")
                .quantity(100)
                .price(new BigDecimal("25.99"))
                .operation("ADD")
                .category("Electronics")
                .supplier("TestSupplier")
                .location("WH-TEST")
                .publishedAt(LocalDateTime.now().minusMinutes(1))
                .hash("testhash1234567890123456789012345678901234567890123456789012")
                .priority("NORMAL")
                .deadline(LocalDateTime.now().plusHours(1))
                .build();
    }
    
    private void setupSuccessfulApiResponses() {
        // Product validation endpoint
        wireMockServer.stubFor(get(urlMatching("/api/products/validate/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"valid\":true,\"productExists\":true,\"message\":\"Product exists\"}")));
        
        // Stock processing endpoint
        wireMockServer.stubFor(post(urlEqualTo("/api/stock/process"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"status\":\"SUCCESS\",\"message\":\"Stock updated successfully\",\"data\":null}")));
        
        // Notification endpoint
        wireMockServer.stubFor(post(urlEqualTo("/api/notifications/stock-processed"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"status\":\"sent\"}")));
    }
    
    private void setupSuccessfulApiResponsesWithDelay(int delayMs) {
        // Product validation endpoint with delay
        wireMockServer.stubFor(get(urlMatching("/api/products/validate/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withFixedDelay(delayMs)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"valid\":true,\"productExists\":true}")));
        
        // Stock processing endpoint with delay
        wireMockServer.stubFor(post(urlEqualTo("/api/stock/process"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withFixedDelay(delayMs)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"status\":\"SUCCESS\",\"message\":\"Processed with delay\"}")));
        
        // Notification endpoint
        wireMockServer.stubFor(post(urlEqualTo("/api/notifications/stock-processed"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"status\":\"sent\"}")));
    }
    
    private void setupValidationFailureResponse() {
        // Product validation failure
        wireMockServer.stubFor(get(urlMatching("/api/products/validate/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"valid\":false,\"productExists\":false,\"message\":\"Product not found\"}")));
    }
    
    private void setupApiProcessingFailure() {
        // Product validation success
        wireMockServer.stubFor(get(urlMatching("/api/products/validate/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"valid\":true,\"productExists\":true}")));
        
        // Stock processing failure
        wireMockServer.stubFor(post(urlEqualTo("/api/stock/process"))
                .willReturn(aResponse()
                        .withStatus(500)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"status\":\"ERROR\",\"message\":\"Internal server error\"}")));
        
        // Notification endpoint for failures
        wireMockServer.stubFor(post(urlEqualTo("/api/notifications/stock-processed"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{\"status\":\"sent\"}")));
    }
}
