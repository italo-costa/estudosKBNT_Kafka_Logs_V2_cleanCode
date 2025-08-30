package com.estudoskbnt.consumer.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Consumption Log Entity
 * 
 * Stores audit information about consumed Kafka messages and their processing results.
 * This provides full traceability of the consumer workflow.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Entity
@Table(name = "consumption_logs", indexes = {
    @Index(name = "idx_correlation_id", columnList = "correlation_id"),
    @Index(name = "idx_consumed_at", columnList = "consumed_at"),
    @Index(name = "idx_status", columnList = "status"),
    @Index(name = "idx_topic_partition", columnList = "topic, partition_id")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsumptionLog {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    /**
     * Correlation ID from the original message
     */
    @Column(name = "correlation_id", nullable = false, length = 100)
    private String correlationId;
    
    /**
     * Kafka topic name
     */
    @Column(name = "topic", nullable = false, length = 200)
    private String topic;
    
    /**
     * Kafka partition ID
     */
    @Column(name = "partition_id", nullable = false)
    private Integer partitionId;
    
    /**
     * Kafka offset
     */
    @Column(name = "offset_value", nullable = false)
    private Long offset;
    
    /**
     * Product ID from the message
     */
    @Column(name = "product_id", nullable = false, length = 50)
    private String productId;
    
    /**
     * Stock quantity from the message
     */
    @Column(name = "quantity")
    private Integer quantity;
    
    /**
     * Product price from the message
     */
    @Column(name = "price", precision = 10, scale = 2)
    private BigDecimal price;
    
    /**
     * Operation type from the message
     */
    @Column(name = "operation", length = 20)
    private String operation;
    
    /**
     * Message hash for verification
     */
    @Column(name = "message_hash", length = 64)
    private String messageHash;
    
    /**
     * When the message was consumed
     */
    @Column(name = "consumed_at", nullable = false)
    private LocalDateTime consumedAt;
    
    /**
     * When the message processing started
     */
    @Column(name = "processing_started_at")
    private LocalDateTime processingStartedAt;
    
    /**
     * When the message processing completed
     */
    @Column(name = "processing_completed_at")
    private LocalDateTime processingCompletedAt;
    
    /**
     * Processing status
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ProcessingStatus status;
    
    /**
     * External API call duration in milliseconds
     */
    @Column(name = "api_call_duration_ms")
    private Long apiCallDurationMs;
    
    /**
     * External API response code
     */
    @Column(name = "api_response_code")
    private Integer apiResponseCode;
    
    /**
     * External API response message
     */
    @Column(name = "api_response_message", length = 500)
    private String apiResponseMessage;
    
    /**
     * Error message if processing failed
     */
    @Column(name = "error_message", length = 1000)
    private String errorMessage;
    
    /**
     * Error stack trace if processing failed
     */
    @Column(name = "error_stack_trace", length = 5000)
    private String errorStackTrace;
    
    /**
     * Number of retry attempts made
     */
    @Column(name = "retry_count", nullable = false)
    @Builder.Default
    private Integer retryCount = 0;
    
    /**
     * Total processing time in milliseconds
     */
    @Column(name = "total_processing_time_ms")
    private Long totalProcessingTimeMs;
    
    /**
     * Message priority level
     */
    @Column(name = "priority", length = 20)
    private String priority;
    
    /**
     * Additional processing metadata in JSON format
     */
    @Column(name = "metadata", length = 2000)
    private String metadata;
    
    /**
     * Calculate total processing time if both timestamps are available
     */
    public Long calculateProcessingTime() {
        if (processingStartedAt != null && processingCompletedAt != null) {
            return java.time.Duration.between(processingStartedAt, processingCompletedAt).toMillis();
        }
        return null;
    }
    
    /**
     * Check if processing was successful
     */
    public boolean isSuccessful() {
        return status == ProcessingStatus.SUCCESS;
    }
    
    /**
     * Check if processing failed
     */
    public boolean isFailed() {
        return status == ProcessingStatus.FAILED || status == ProcessingStatus.RETRY_EXHAUSTED;
    }
    
    /**
     * Processing status enumeration
     */
    public enum ProcessingStatus {
        RECEIVED,        // Message received from Kafka
        PROCESSING,      // Currently being processed
        SUCCESS,         // Successfully processed
        FAILED,          // Processing failed
        RETRY_SCHEDULED, // Retry scheduled
        RETRY_EXHAUSTED, // All retries exhausted
        DISCARDED        // Message discarded (e.g., expired)
    }
}
