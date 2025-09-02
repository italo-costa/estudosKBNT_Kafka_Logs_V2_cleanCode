package com.estudoskbnt.kbntlogservice.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit Tests for KafkaPublicationLog Model
 * Tests logging model functionality, builders, and data integrity
 */
@DisplayName("KafkaPublicationLog Model Tests")
class KafkaPublicationLogTest {

    @Test
    @DisplayName("Should create publication log with all fields using builder")
    void shouldCreatePublicationLogWithAllFields() {
        // Given
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime ackTime = now.plusNanos(45000000); // +45ms
        
        // When
        KafkaPublicationLog log = KafkaPublicationLog.builder()
            .publicationId("pub-123")
            .messageHash("abc123def456")
            .topicName("kbnt-stock-updates")
            .partition(3)
            .offset(7823L)
            .correlationId("corr-456")
            .productId("SMARTPHONE-XYZ")
            .operation("ADD")
            .messageSizeBytes(256)
            .sentAt(now)
            .acknowledgedAt(ackTime)
            .processingTimeMs(45L)
            .status(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED)
            .errorMessage(null)
            .brokerResponse("Partition=3, Offset=7823")
            .producerId("producer-789")
            .messageContent("{\"productId\":\"SMARTPHONE-XYZ\"}")
            .retryCount(0)
            .build();

        // Then
        assertNotNull(log, "Publication log should not be null");
        assertEquals("pub-123", log.getPublicationId());
        assertEquals("abc123def456", log.getMessageHash());
        assertEquals("kbnt-stock-updates", log.getTopicName());
        assertEquals(Integer.valueOf(3), log.getPartition());
        assertEquals(Long.valueOf(7823), log.getOffset());
        assertEquals("corr-456", log.getCorrelationId());
        assertEquals("SMARTPHONE-XYZ", log.getProductId());
        assertEquals("ADD", log.getOperation());
        assertEquals(Integer.valueOf(256), log.getMessageSizeBytes());
        assertEquals(now, log.getSentAt());
        assertEquals(ackTime, log.getAcknowledgedAt());
        assertEquals(Long.valueOf(45), log.getProcessingTimeMs());
        assertEquals(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED, log.getStatus());
        assertNull(log.getErrorMessage());
        assertEquals("Partition=3, Offset=7823", log.getBrokerResponse());
        assertEquals("producer-789", log.getProducerId());
        assertEquals("{\"productId\":\"SMARTPHONE-XYZ\"}", log.getMessageContent());
        assertEquals(Integer.valueOf(0), log.getRetryCount());
    }

    @Test
    @DisplayName("Should create minimal publication log")
    void shouldCreateMinimalPublicationLog() {
        // When
        KafkaPublicationLog log = KafkaPublicationLog.builder()
            .publicationId("minimal-pub")
            .messageHash("hash123")
            .topicName("test-topic")
            .status(KafkaPublicationLog.PublicationStatus.SENT)
            .build();

        // Then
        assertNotNull(log);
        assertEquals("minimal-pub", log.getPublicationId());
        assertEquals("hash123", log.getMessageHash());
        assertEquals("test-topic", log.getTopicName());
        assertEquals(KafkaPublicationLog.PublicationStatus.SENT, log.getStatus());
        
        // Optional fields should be null
        assertNull(log.getPartition());
        assertNull(log.getOffset());
        assertNull(log.getCorrelationId());
        assertNull(log.getProcessingTimeMs());
    }

    @Test
    @DisplayName("Should create failed publication log with error details")
    void shouldCreateFailedPublicationLogWithErrorDetails() {
        // Given
        LocalDateTime failureTime = LocalDateTime.now();
        String errorMessage = "Connection timeout to broker";
        
        // When
        KafkaPublicationLog failedLog = KafkaPublicationLog.builder()
            .publicationId("failed-pub-456")
            .messageHash("failed123hash")
            .topicName("kbnt-stock-updates")
            .correlationId("failed-corr-123")
            .productId("FAILED-PRODUCT")
            .operation("ADD")
            .sentAt(failureTime)
            .acknowledgedAt(failureTime.plusSeconds(5)) // Failed after 5 seconds
            .processingTimeMs(5000L)
            .status(KafkaPublicationLog.PublicationStatus.FAILED)
            .errorMessage(errorMessage)
            .retryCount(3)
            .build();

        // Then
        assertEquals(KafkaPublicationLog.PublicationStatus.FAILED, failedLog.getStatus());
        assertEquals(errorMessage, failedLog.getErrorMessage());
        assertEquals(Long.valueOf(5000), failedLog.getProcessingTimeMs());
        assertEquals(Integer.valueOf(3), failedLog.getRetryCount());
        assertNull(failedLog.getPartition()); // No partition for failed publication
        assertNull(failedLog.getOffset()); // No offset for failed publication
    }

    @Test
    @DisplayName("Should support all publication status types")
    void shouldSupportAllPublicationStatusTypes() {
        // Test all enum values
        KafkaPublicationLog.PublicationStatus[] statuses = KafkaPublicationLog.PublicationStatus.values();
        
        assertEquals(4, statuses.length, "Should have exactly 4 status types");
        
        // Test each status
        assertTrue(containsStatus(statuses, KafkaPublicationLog.PublicationStatus.SENT));
        assertTrue(containsStatus(statuses, KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED));
        assertTrue(containsStatus(statuses, KafkaPublicationLog.PublicationStatus.FAILED));
        assertTrue(containsStatus(statuses, KafkaPublicationLog.PublicationStatus.RETRYING));
    }

    @Test
    @DisplayName("Should create retrying publication log")
    void shouldCreateRetryingPublicationLog() {
        // When
        KafkaPublicationLog retryingLog = KafkaPublicationLog.builder()
            .publicationId("retry-pub-789")
            .messageHash("retry123hash")
            .topicName("kbnt-stock-transfers")
            .status(KafkaPublicationLog.PublicationStatus.RETRYING)
            .retryCount(1)
            .errorMessage("Temporary broker unavailable")
            .build();

        // Then
        assertEquals(KafkaPublicationLog.PublicationStatus.RETRYING, retryingLog.getStatus());
        assertEquals(Integer.valueOf(1), retryingLog.getRetryCount());
        assertEquals("Temporary broker unavailable", retryingLog.getErrorMessage());
    }

    @Test
    @DisplayName("Should handle large message content")
    void shouldHandleLargeMessageContent() {
        // Given
        StringBuilder largeContent = new StringBuilder();
        for (int i = 0; i < 1000; i++) {
            largeContent.append("This is a large message content for testing purposes. ");
        }
        String largeMessageContent = largeContent.toString();

        // When
        KafkaPublicationLog log = KafkaPublicationLog.builder()
            .publicationId("large-msg-pub")
            .messageHash("large123hash")
            .topicName("kbnt-stock-updates")
            .messageContent(largeMessageContent)
            .messageSizeBytes(largeMessageContent.getBytes().length)
            .status(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED)
            .build();

        // Then
        assertEquals(largeMessageContent, log.getMessageContent());
        assertTrue(log.getMessageSizeBytes() > 10000, "Message size should be greater than 10KB");
    }

    @Test
    @DisplayName("Should support processing time calculations")
    void shouldSupportProcessingTimeCalculations() {
        // Given
        LocalDateTime sentTime = LocalDateTime.of(2024, 8, 30, 15, 30, 0);
        LocalDateTime ackTime = sentTime.plusNanos(125000000); // +125ms
        
        // When
        KafkaPublicationLog log = KafkaPublicationLog.builder()
            .publicationId("timing-test")
            .messageHash("timing123")
            .topicName("test-topic")
            .sentAt(sentTime)
            .acknowledgedAt(ackTime)
            .processingTimeMs(125L)
            .status(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED)
            .build();

        // Then
        assertEquals(sentTime, log.getSentAt());
        assertEquals(ackTime, log.getAcknowledgedAt());
        assertEquals(Long.valueOf(125), log.getProcessingTimeMs());
        
        // Verify timing makes sense
        assertTrue(log.getAcknowledgedAt().isAfter(log.getSentAt()), 
            "Acknowledged time should be after sent time");
    }

    @Test
    @DisplayName("Should support broker response details")
    void shouldSupportBrokerResponseDetails() {
        // Given
        String detailedBrokerResponse = "Partition=5, Offset=12345, Leader=broker-1, ISR=[broker-1,broker-2,broker-3]";

        // When
        KafkaPublicationLog log = KafkaPublicationLog.builder()
            .publicationId("broker-details-test")
            .messageHash("broker123")
            .topicName("kbnt-stock-alerts")
            .partition(5)
            .offset(12345L)
            .brokerResponse(detailedBrokerResponse)
            .status(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED)
            .build();

        // Then
        assertEquals(detailedBrokerResponse, log.getBrokerResponse());
        assertEquals(Integer.valueOf(5), log.getPartition());
        assertEquals(Long.valueOf(12345), log.getOffset());
    }

    @Test
    @DisplayName("Should use no-args constructor")
    void shouldUseNoArgsConstructor() {
        // When
        KafkaPublicationLog log = new KafkaPublicationLog();

        // Then
        assertNotNull(log);
        assertNull(log.getPublicationId());
        assertNull(log.getMessageHash());
        assertNull(log.getTopicName());
        assertNull(log.getStatus());
    }

    @Test
    @DisplayName("Should use all-args constructor")
    void shouldUseAllArgsConstructor() {
        // Given
        LocalDateTime now = LocalDateTime.now();
        
        // When
        KafkaPublicationLog log = new KafkaPublicationLog(
            "all-args-pub",
            "allargs123",
            "test-topic",
            3,
            7777L,
            "all-args-corr",
            "ALL-ARGS-PRODUCT",
            "SET",
            512,
            now,
            now.plusNanos(75000000),
            75L,
            KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED,
            null,
            "Partition=3, Offset=7777",
            "all-args-producer",
            "{\"test\":\"all-args\"}",
            0
        );

        // Then
        assertEquals("all-args-pub", log.getPublicationId());
        assertEquals("allargs123", log.getMessageHash());
        assertEquals("test-topic", log.getTopicName());
        assertEquals(Integer.valueOf(3), log.getPartition());
        assertEquals(Long.valueOf(7777), log.getOffset());
        assertEquals("all-args-corr", log.getCorrelationId());
        assertEquals("ALL-ARGS-PRODUCT", log.getProductId());
        assertEquals("SET", log.getOperation());
        assertEquals(Integer.valueOf(512), log.getMessageSizeBytes());
        assertEquals(now, log.getSentAt());
        assertEquals(Long.valueOf(75), log.getProcessingTimeMs());
        assertEquals(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED, log.getStatus());
        assertEquals("Partition=3, Offset=7777", log.getBrokerResponse());
        assertEquals("all-args-producer", log.getProducerId());
        assertEquals("{\"test\":\"all-args\"}", log.getMessageContent());
        assertEquals(Integer.valueOf(0), log.getRetryCount());
    }

    // ===================== HELPER METHODS =====================

    private boolean containsStatus(KafkaPublicationLog.PublicationStatus[] statuses, 
                                 KafkaPublicationLog.PublicationStatus target) {
        for (KafkaPublicationLog.PublicationStatus status : statuses) {
            if (status == target) {
                return true;
            }
        }
        return false;
    }
}
