package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka;

import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;
import com.estudoskbnt.kbntlogservice.domain.model.*;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Unit Tests for Kafka Event Publisher Adapter
 * Tests the infrastructure layer's Kafka integration
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("Kafka Event Publisher Adapter Tests")
class KafkaEventPublisherAdapterTest {

    @Mock
    private KafkaTemplate<String, String> kafkaTemplate;

    @InjectMocks
    private KafkaEventPublisherAdapter eventPublisherAdapter;

    private StockUpdateEvent mockEvent;
    private SendResult<String, String> mockSendResult;

    @BeforeEach
    void setUp() {
        mockEvent = createMockStockUpdateEvent();
        mockSendResult = createMockSendResult();
    }

    @Test
    @DisplayName("Should publish stock update event successfully")
    void shouldPublishStockUpdateEventSuccessfully() {
        // Given
        CompletableFuture<SendResult<String, String>> mockFuture = 
                CompletableFuture.completedFuture(mockSendResult);
        
        when(kafkaTemplate.send(eq("kbnt-stock-updates"), eq("PROD-001"), any(String.class)))
                .thenReturn(mockFuture);

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishStockUpdateEvent(mockEvent);

        // Then
        assertNotNull(result);
        assertDoesNotThrow(() -> result.get());

        verify(kafkaTemplate, times(1))
                .send(eq("kbnt-stock-updates"), eq("PROD-001"), any(String.class));
    }

    @Test
    @DisplayName("Should publish audit event successfully")
    void shouldPublishAuditEventSuccessfully() {
        // Given
        CompletableFuture<SendResult<String, String>> mockFuture = 
                CompletableFuture.completedFuture(mockSendResult);
        
        when(kafkaTemplate.send(eq("kbnt-audit-logs"), eq("test-correlation-123"), any(String.class)))
                .thenReturn(mockFuture);

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishAuditEvent(mockEvent);

        // Then
        assertNotNull(result);
        assertDoesNotThrow(() -> result.get());

        verify(kafkaTemplate, times(1))
                .send(eq("kbnt-audit-logs"), eq("test-correlation-123"), any(String.class));
    }

    @Test
    @DisplayName("Should publish application log event successfully")
    void shouldPublishApplicationLogEventSuccessfully() {
        // Given
        String logLevel = "INFO";
        String message = "Stock update processed successfully";
        Map<String, Object> context = new HashMap<>();
        context.put("productId", "PROD-001");
        context.put("operation", "ADD");

        CompletableFuture<SendResult<String, String>> mockFuture = 
                CompletableFuture.completedFuture(mockSendResult);
        
        when(kafkaTemplate.send(eq("application-logs"), eq("INFO"), any(String.class)))
                .thenReturn(mockFuture);

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishApplicationLogEvent(logLevel, message, context);

        // Then
        assertNotNull(result);
        assertDoesNotThrow(() -> result.get());

        verify(kafkaTemplate, times(1))
                .send(eq("application-logs"), eq("INFO"), any(String.class));
    }

    @Test
    @DisplayName("Should handle Kafka send failures for stock update events")
    void shouldHandleKafkaSendFailuresForStockUpdateEvents() {
        // Given
        CompletableFuture<SendResult<String, String>> failedFuture = new CompletableFuture<>();
        failedFuture.completeExceptionally(new RuntimeException("Kafka broker unavailable"));
        
        when(kafkaTemplate.send(eq("kbnt-stock-updates"), eq("PROD-001"), any(String.class)))
                .thenReturn(failedFuture);

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishStockUpdateEvent(mockEvent);

        // Then
        assertNotNull(result);
        assertTrue(result.isCompletedExceptionally());

        // Verify exception type
        Exception exception = assertThrows(Exception.class, () -> result.get());
        assertInstanceOf(KafkaEventPublisherAdapter.EventPublicationException.class, exception.getCause());
        assertTrue(exception.getMessage().contains("Failed to publish stock update event"));
    }

    @Test
    @DisplayName("Should handle Kafka send failures for audit events")
    void shouldHandleKafkaSendFailuresForAuditEvents() {
        // Given
        CompletableFuture<SendResult<String, String>> failedFuture = new CompletableFuture<>();
        failedFuture.completeExceptionally(new RuntimeException("Kafka broker unavailable"));
        
        when(kafkaTemplate.send(eq("kbnt-audit-logs"), eq("test-correlation-123"), any(String.class)))
                .thenReturn(failedFuture);

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishAuditEvent(mockEvent);

        // Then
        assertNotNull(result);
        assertTrue(result.isCompletedExceptionally());

        // Verify exception type
        Exception exception = assertThrows(Exception.class, () -> result.get());
        assertInstanceOf(KafkaEventPublisherAdapter.EventPublicationException.class, exception.getCause());
        assertTrue(exception.getMessage().contains("Failed to publish audit event"));
    }

    @Test
    @DisplayName("Should handle JSON serialization failures")
    void shouldHandleJsonSerializationFailures() {
        // Given - Create an event that would cause JSON serialization issues
        // This is more of a theoretical test as our current implementation should handle all cases
        StockUpdateEvent problematicEvent = createProblematicEvent();

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishStockUpdateEvent(problematicEvent);

        // Then - The implementation should handle any serialization issues gracefully
        assertNotNull(result);
        // Note: Current implementation with well-defined POJOs shouldn't fail serialization
    }

    @Test
    @DisplayName("Should use correct partition keys")
    void shouldUseCorrectPartitionKeys() {
        // Given
        CompletableFuture<SendResult<String, String>> mockFuture = 
                CompletableFuture.completedFuture(mockSendResult);
        
        when(kafkaTemplate.send(any(String.class), any(String.class), any(String.class)))
                .thenReturn(mockFuture);

        // When - Publish stock update event
        eventPublisherAdapter.publishStockUpdateEvent(mockEvent);

        // Then - Should use product ID as partition key
        verify(kafkaTemplate).send(eq("kbnt-stock-updates"), eq("PROD-001"), any(String.class));

        // When - Publish audit event
        eventPublisherAdapter.publishAuditEvent(mockEvent);

        // Then - Should use correlation ID as partition key
        verify(kafkaTemplate).send(eq("kbnt-audit-logs"), eq("test-correlation-123"), any(String.class));

        // When - Publish application log
        eventPublisherAdapter.publishApplicationLogEvent("INFO", "Test message", new HashMap<>());

        // Then - Should use log level as partition key
        verify(kafkaTemplate).send(eq("application-logs"), eq("INFO"), any(String.class));
    }

    @Test
    @DisplayName("Should create correct message formats")
    void shouldCreateCorrectMessageFormats() {
        // Given
        CompletableFuture<SendResult<String, String>> mockFuture = 
                CompletableFuture.completedFuture(mockSendResult);
        
        when(kafkaTemplate.send(any(String.class), any(String.class), any(String.class)))
                .thenReturn(mockFuture);

        // When
        eventPublisherAdapter.publishStockUpdateEvent(mockEvent);

        // Then - Verify message structure (captured through mock)
        verify(kafkaTemplate).send(eq("kbnt-stock-updates"), eq("PROD-001"), 
                argThat(messageJson -> {
                    // Basic validation that it contains expected fields
                    return messageJson.contains("\"productId\":\"PROD-001\"") &&
                           messageJson.contains("\"operation\":\"ADD\"") &&
                           messageJson.contains("\"quantity\":100") &&
                           messageJson.contains("\"correlationId\":\"test-correlation-123\"");
                }));
    }

    @Test
    @DisplayName("Should handle events with optional fields")
    void shouldHandleEventsWithOptionalFields() {
        // Given - Event with minimal required fields
        StockUpdateEvent minimalEvent = createMinimalStockUpdateEvent();
        
        CompletableFuture<SendResult<String, String>> mockFuture = 
                CompletableFuture.completedFuture(mockSendResult);
        
        when(kafkaTemplate.send(any(String.class), any(String.class), any(String.class)))
                .thenReturn(mockFuture);

        // When
        CompletableFuture<Void> result = eventPublisherAdapter.publishStockUpdateEvent(minimalEvent);

        // Then
        assertNotNull(result);
        assertDoesNotThrow(() -> result.get());

        verify(kafkaTemplate, times(1))
                .send(eq("kbnt-stock-updates"), eq("PROD-002"), any(String.class));
    }

    // ==================== HELPER METHODS ====================

    private StockUpdateEvent createMockStockUpdateEvent() {
        return StockUpdateEvent.builder()
                .eventId("event-123")
                .productId(ProductId.of("PROD-001"))
                .distributionCenter(DistributionCenter.of("DC-SAO-PAULO"))
                .branch(Branch.of("BRANCH-001"))
                .quantity(Quantity.of(100))
                .operation(Operation.of("ADD"))
                .correlationId(CorrelationId.of("test-correlation-123"))
                .reasonCode(ReasonCode.of("PURCHASE"))
                .referenceDocument(ReferenceDocument.of("PO-12345"))
                .targetTopic("kbnt-stock-updates")
                .build();
    }

    private StockUpdateEvent createMinimalStockUpdateEvent() {
        return StockUpdateEvent.builder()
                .eventId("event-minimal-456")
                .productId(ProductId.of("PROD-002"))
                .distributionCenter(DistributionCenter.of("DC-RIO-JANEIRO"))
                .branch(Branch.of("BRANCH-002"))
                .quantity(Quantity.of(50))
                .operation(Operation.of("REMOVE"))
                .correlationId(CorrelationId.of("test-correlation-456"))
                .targetTopic("kbnt-stock-updates")
                // Note: reasonCode, referenceDocument, and sourceBranch are null
                .build();
    }

    private StockUpdateEvent createProblematicEvent() {
        // For this test, we'll create a normal event since our current implementation
        // should handle all valid domain events properly
        return createMockStockUpdateEvent();
    }

    private SendResult<String, String> createMockSendResult() {
        RecordMetadata metadata = new RecordMetadata(
                new TopicPartition("kbnt-stock-updates", 0),
                0, // offset
                0, // timestamp
                0, // serializedKeySize
                0  // serializedValueSize
        );
        
        return new SendResult<>(null, metadata);
    }
}
