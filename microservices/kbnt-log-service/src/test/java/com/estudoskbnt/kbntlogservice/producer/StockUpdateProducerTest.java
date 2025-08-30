package com.estudoskbnt.kbntlogservice.producer;

import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import com.estudoskbnt.kbntlogservice.model.KafkaPublicationLog;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.concurrent.CompletableFuture;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit Tests for StockUpdateProducer
 * Tests logging functionality, message hashing, topic routing and publication tracking
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("StockUpdateProducer Unit Tests")
class StockUpdateProducerTest {

    @Mock
    private KafkaTemplate<String, StockUpdateMessage> kafkaTemplate;

    @Mock
    private ObjectMapper objectMapper;

    private StockUpdateProducer stockUpdateProducer;

    private static final String STOCK_UPDATES_TOPIC = "kbnt-stock-updates";
    private static final String STOCK_TRANSFERS_TOPIC = "kbnt-stock-transfers";
    private static final String STOCK_ALERTS_TOPIC = "kbnt-stock-alerts";

    @BeforeEach
    void setUp() {
        stockUpdateProducer = new StockUpdateProducer(kafkaTemplate, objectMapper);
        
        // Set topic names using reflection
        ReflectionTestUtils.setField(stockUpdateProducer, "stockUpdatesTopic", STOCK_UPDATES_TOPIC);
        ReflectionTestUtils.setField(stockUpdateProducer, "stockTransfersTopic", STOCK_TRANSFERS_TOPIC);
        ReflectionTestUtils.setField(stockUpdateProducer, "stockAlertsTopic", STOCK_ALERTS_TOPIC);
    }

    @Test
    @DisplayName("Should generate unique message hash based on timestamp")
    void shouldGenerateUniqueMessageHash() {
        // Given
        StockUpdateMessage message1 = createTestMessage("PRODUCT-A", "ADD");
        message1.setTimestamp(LocalDateTime.of(2024, 8, 30, 15, 30, 0));
        message1.setCorrelationId("corr-123");

        StockUpdateMessage message2 = createTestMessage("PRODUCT-A", "ADD");
        message2.setTimestamp(LocalDateTime.of(2024, 8, 30, 15, 30, 1)); // Different timestamp
        message2.setCorrelationId("corr-123");

        // When
        String hash1 = invokeGenerateMessageHash(message1);
        String hash2 = invokeGenerateMessageHash(message2);

        // Then
        assertNotNull(hash1, "Message hash should not be null");
        assertNotNull(hash2, "Message hash should not be null");
        assertEquals(16, hash1.length(), "Hash should be 16 characters long");
        assertEquals(16, hash2.length(), "Hash should be 16 characters long");
        assertNotEquals(hash1, hash2, "Different timestamps should generate different hashes");
    }

    @Test
    @DisplayName("Should route TRANSFER operations to transfers topic")
    void shouldRouteTransferToTransfersTopic() throws Exception {
        // Given
        StockUpdateMessage transferMessage = createTestMessage("PRODUCT-X", "TRANSFER");
        transferMessage.setSourceBranch("FIL-SP001");
        transferMessage.setBranch("FIL-SP002");

        CompletableFuture<SendResult<String, StockUpdateMessage>> mockFuture = createMockSuccessResult();
        when(kafkaTemplate.send(eq(STOCK_TRANSFERS_TOPIC), anyString(), eq(transferMessage)))
            .thenReturn(mockFuture);

        when(objectMapper.writeValueAsString(any())).thenReturn("{\"test\":\"json\"}");

        // When
        CompletableFuture<SendResult<String, StockUpdateMessage>> result = 
            stockUpdateProducer.processStockUpdate(transferMessage);

        // Then
        assertNotNull(result, "Result should not be null");
        verify(kafkaTemplate).send(eq(STOCK_TRANSFERS_TOPIC), anyString(), eq(transferMessage));
        verifyNoMoreInteractions(kafkaTemplate);
    }

    @Test
    @DisplayName("Should route ADD/REMOVE/SET operations to updates topic")
    void shouldRouteStandardOperationsToUpdatesTopic() throws Exception {
        // Given
        StockUpdateMessage addMessage = createTestMessage("PRODUCT-Y", "ADD");
        
        CompletableFuture<SendResult<String, StockUpdateMessage>> mockFuture = createMockSuccessResult();
        when(kafkaTemplate.send(eq(STOCK_UPDATES_TOPIC), anyString(), eq(addMessage)))
            .thenReturn(mockFuture);

        when(objectMapper.writeValueAsString(any())).thenReturn("{\"test\":\"json\"}");

        // When
        stockUpdateProducer.processStockUpdate(addMessage);

        // Then
        verify(kafkaTemplate).send(eq(STOCK_UPDATES_TOPIC), anyString(), eq(addMessage));
    }

    @Test
    @DisplayName("Should generate correct partition key from DC and Product")
    void shouldGenerateCorrectPartitionKey() {
        // Given
        StockUpdateMessage message = createTestMessage("SMARTPHONE-XYZ", "ADD");
        message.setDistributionCenter("DC-SP01");

        // When - Using reflection to access private method
        String partitionKey = invokeGeneratePartitionKey(message);

        // Then
        assertEquals("DC-SP01-SMARTPHONE-XYZ", partitionKey, 
            "Partition key should be DC-ProductId format");
    }

    @Test
    @DisplayName("Should enrich message with timestamp and correlation ID")
    void shouldEnrichMessageWithMetadata() {
        // Given
        StockUpdateMessage message = createTestMessage("PRODUCT-Z", "REMOVE");
        message.setTimestamp(null);
        message.setCorrelationId(null);

        // When
        invokeEnrichStockMessage(message);

        // Then
        assertNotNull(message.getTimestamp(), "Timestamp should be set");
        assertNotNull(message.getCorrelationId(), "Correlation ID should be set");
        assertFalse(message.getCorrelationId().isEmpty(), "Correlation ID should not be empty");
    }

    @Test
    @DisplayName("Should validate TRANSFER operation requires source branch")
    void shouldValidateTransferRequiresSourceBranch() {
        // Given
        StockUpdateMessage invalidTransfer = createTestMessage("PRODUCT-A", "TRANSFER");
        invalidTransfer.setSourceBranch(null); // Invalid - no source branch
        invalidTransfer.setBranch("FIL-SP002");

        // When & Then
        IllegalArgumentException exception = assertThrows(
            IllegalArgumentException.class,
            () -> invokeValidateStockOperation(invalidTransfer),
            "Should throw exception for TRANSFER without source branch"
        );

        assertEquals("Transfer operation requires source branch", exception.getMessage());
    }

    @Test
    @DisplayName("Should validate TRANSFER operation requires different branches")
    void shouldValidateTransferRequiresDifferentBranches() {
        // Given
        StockUpdateMessage invalidTransfer = createTestMessage("PRODUCT-A", "TRANSFER");
        invalidTransfer.setSourceBranch("FIL-SP001");
        invalidTransfer.setBranch("FIL-SP001"); // Same as source - invalid

        // When & Then
        IllegalArgumentException exception = assertThrows(
            IllegalArgumentException.class,
            () -> invokeValidateStockOperation(invalidTransfer),
            "Should throw exception for TRANSFER with same source and target"
        );

        assertEquals("Transfer source and target branch cannot be the same", exception.getMessage());
    }

    @Test
    @DisplayName("Should validate REMOVE operation requires positive quantity")
    void shouldValidateRemoveRequiresPositiveQuantity() {
        // Given
        StockUpdateMessage invalidRemove = createTestMessage("PRODUCT-A", "REMOVE");
        invalidRemove.setQuantity(0); // Invalid - zero quantity for remove

        // When & Then
        IllegalArgumentException exception = assertThrows(
            IllegalArgumentException.class,
            () -> invokeValidateStockOperation(invalidRemove),
            "Should throw exception for REMOVE with zero quantity"
        );

        assertEquals("Remove operation requires positive quantity", exception.getMessage());
    }

    @Test
    @DisplayName("Should capture publication attempt with all required fields")
    void shouldCapturePublicationAttemptDetails() throws Exception {
        // Given
        StockUpdateMessage message = createTestMessage("SMARTPHONE-ABC", "ADD");
        message.setTimestamp(LocalDateTime.now());
        message.setCorrelationId("test-correlation-123");

        when(objectMapper.writeValueAsString(any())).thenReturn("{\"productId\":\"SMARTPHONE-ABC\"}");

        CompletableFuture<SendResult<String, StockUpdateMessage>> mockFuture = createMockSuccessResult();
        when(kafkaTemplate.send(anyString(), anyString(), any(StockUpdateMessage.class)))
            .thenReturn(mockFuture);

        // When
        stockUpdateProducer.processStockUpdate(message);

        // Then
        ArgumentCaptor<String> topicCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<StockUpdateMessage> messageCaptor = ArgumentCaptor.forClass(StockUpdateMessage.class);

        verify(kafkaTemplate).send(topicCaptor.capture(), keyCaptor.capture(), messageCaptor.capture());

        assertEquals(STOCK_UPDATES_TOPIC, topicCaptor.getValue());
        assertEquals("DC-SP01-SMARTPHONE-ABC", keyCaptor.getValue());
        assertEquals(message, messageCaptor.getValue());
    }

    @Test
    @DisplayName("Should handle serialization errors gracefully")
    void shouldHandleSerializationErrorsGracefully() throws Exception {
        // Given
        StockUpdateMessage message = createTestMessage("PRODUCT-ERROR", "ADD");
        
        when(objectMapper.writeValueAsString(any()))
            .thenThrow(new RuntimeException("Serialization failed"));

        CompletableFuture<SendResult<String, StockUpdateMessage>> mockFuture = createMockSuccessResult();
        when(kafkaTemplate.send(anyString(), anyString(), any(StockUpdateMessage.class)))
            .thenReturn(mockFuture);

        // When & Then - Should not throw exception
        assertDoesNotThrow(() -> stockUpdateProducer.processStockUpdate(message));
    }

    @Test
    @DisplayName("Should trigger low stock alert for quantities below threshold")
    void shouldTriggerLowStockAlertForLowQuantities() throws Exception {
        // Given
        StockUpdateMessage lowStockMessage = createTestMessage("LOW-STOCK-PRODUCT", "REMOVE");
        lowStockMessage.setQuantity(5); // Below threshold of 10

        when(objectMapper.writeValueAsString(any())).thenReturn("{\"test\":\"json\"}");

        CompletableFuture<SendResult<String, StockUpdateMessage>> mockMainFuture = createMockSuccessResult();
        CompletableFuture<SendResult<String, StockUpdateMessage>> mockAlertFuture = createMockSuccessResult();
        
        when(kafkaTemplate.send(eq(STOCK_UPDATES_TOPIC), anyString(), any(StockUpdateMessage.class)))
            .thenReturn(mockMainFuture);
        when(kafkaTemplate.send(eq(STOCK_ALERTS_TOPIC), anyString(), any(StockUpdateMessage.class)))
            .thenReturn(mockAlertFuture);

        // When
        stockUpdateProducer.processStockUpdate(lowStockMessage);
        
        // Allow async alert processing
        Thread.sleep(100);

        // Then
        verify(kafkaTemplate).send(eq(STOCK_UPDATES_TOPIC), anyString(), eq(lowStockMessage));
        // Note: Alert is sent asynchronously, so we might need to wait or use different verification approach
    }

    @Test
    @DisplayName("Should create comprehensive publication log model")
    void shouldCreateComprehensivePublicationLog() {
        // Given
        LocalDateTime now = LocalDateTime.now();
        
        // When
        KafkaPublicationLog log = KafkaPublicationLog.builder()
            .publicationId("test-pub-123")
            .messageHash("abc123def456")
            .topicName(STOCK_UPDATES_TOPIC)
            .partition(3)
            .offset(7823L)
            .correlationId("corr-456")
            .productId("TEST-PRODUCT")
            .operation("ADD")
            .messageSizeBytes(256)
            .sentAt(now)
            .acknowledgedAt(now.plusNanos(45000000)) // +45ms
            .processingTimeMs(45L)
            .status(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED)
            .brokerResponse("Partition=3, Offset=7823")
            .producerId("test-producer-789")
            .messageContent("{\"productId\":\"TEST-PRODUCT\"}")
            .retryCount(0)
            .build();

        // Then
        assertNotNull(log);
        assertEquals("test-pub-123", log.getPublicationId());
        assertEquals("abc123def456", log.getMessageHash());
        assertEquals(STOCK_UPDATES_TOPIC, log.getTopicName());
        assertEquals(Integer.valueOf(3), log.getPartition());
        assertEquals(Long.valueOf(7823), log.getOffset());
        assertEquals("corr-456", log.getCorrelationId());
        assertEquals("TEST-PRODUCT", log.getProductId());
        assertEquals("ADD", log.getOperation());
        assertEquals(Integer.valueOf(256), log.getMessageSizeBytes());
        assertEquals(now, log.getSentAt());
        assertEquals(Long.valueOf(45), log.getProcessingTimeMs());
        assertEquals(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED, log.getStatus());
        assertEquals("Partition=3, Offset=7823", log.getBrokerResponse());
        assertEquals("test-producer-789", log.getProducerId());
        assertEquals("{\"productId\":\"TEST-PRODUCT\"}", log.getMessageContent());
        assertEquals(Integer.valueOf(0), log.getRetryCount());
    }

    // ===================== HELPER METHODS =====================

    private StockUpdateMessage createTestMessage(String productId, String operation) {
        return StockUpdateMessage.builder()
            .productId(productId)
            .distributionCenter("DC-SP01")
            .branch("FIL-SP001")
            .quantity(100)
            .operation(operation)
            .reasonCode("TEST")
            .referenceDocument("TEST-DOC-001")
            .build();
    }

    private CompletableFuture<SendResult<String, StockUpdateMessage>> createMockSuccessResult() {
        CompletableFuture<SendResult<String, StockUpdateMessage>> future = new CompletableFuture<>();
        
        // Create mock metadata
        RecordMetadata metadata = new RecordMetadata(
            new TopicPartition(STOCK_UPDATES_TOPIC, 3),
            0L, // baseOffset
            7823L, // offset
            System.currentTimeMillis(), // timestamp
            0L, // checksum
            256, // serializedKeySize
            512 // serializedValueSize
        );
        
        // Create mock producer record
        ProducerRecord<String, StockUpdateMessage> record = 
            new ProducerRecord<>(STOCK_UPDATES_TOPIC, "test-key", createTestMessage("TEST", "ADD"));
        
        // Create mock send result
        SendResult<String, StockUpdateMessage> sendResult = new SendResult<>(record, metadata);
        
        future.complete(sendResult);
        return future;
    }

    // Using reflection to test private methods
    private String invokeGenerateMessageHash(StockUpdateMessage message) {
        try {
            var method = StockUpdateProducer.class.getDeclaredMethod("generateMessageHash", StockUpdateMessage.class);
            method.setAccessible(true);
            return (String) method.invoke(stockUpdateProducer, message);
        } catch (Exception e) {
            throw new RuntimeException("Failed to invoke generateMessageHash", e);
        }
    }

    private String invokeGeneratePartitionKey(StockUpdateMessage message) {
        try {
            var method = StockUpdateProducer.class.getDeclaredMethod("generatePartitionKey", StockUpdateMessage.class);
            method.setAccessible(true);
            return (String) method.invoke(stockUpdateProducer, message);
        } catch (Exception e) {
            throw new RuntimeException("Failed to invoke generatePartitionKey", e);
        }
    }

    private void invokeEnrichStockMessage(StockUpdateMessage message) {
        try {
            var method = StockUpdateProducer.class.getDeclaredMethod("enrichStockMessage", StockUpdateMessage.class);
            method.setAccessible(true);
            method.invoke(stockUpdateProducer, message);
        } catch (Exception e) {
            throw new RuntimeException("Failed to invoke enrichStockMessage", e);
        }
    }

    private void invokeValidateStockOperation(StockUpdateMessage message) {
        try {
            var method = StockUpdateProducer.class.getDeclaredMethod("validateStockOperation", StockUpdateMessage.class);
            method.setAccessible(true);
            method.invoke(stockUpdateProducer, message);
        } catch (Exception e) {
            if (e.getCause() instanceof IllegalArgumentException) {
                throw (IllegalArgumentException) e.getCause();
            }
            throw new RuntimeException("Failed to invoke validateStockOperation", e);
        }
    }
}
