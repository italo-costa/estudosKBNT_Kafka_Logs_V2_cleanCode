package com.estudoskbnt.consumer.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Consumption Log Entity
 * Stores audit information about consumed Kafka messages and their processing results.
 * This provides full traceability of the consumer workflow.
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
public class ConsumptionLog {
    private String messageHash;
    private String operation;
    private LocalDateTime consumedAt;
    public ConsumptionLog() {}
    public ConsumptionLog(Long id, String correlationId, String topic, Integer partitionId, Long offset, String productId, Integer quantity, java.math.BigDecimal price) {
        this.id = id;
        this.correlationId = correlationId;
        this.topic = topic;
        this.partitionId = partitionId;
        this.offset = offset;
        this.productId = productId;
        this.quantity = quantity;
        this.price = price;
    }
    public String getMessageHash() { return messageHash; }
    public void setMessageHash(String messageHash) { this.messageHash = messageHash; }
    public String getOperation() { return operation; }
    public void setOperation(String operation) { this.operation = operation; }
    public LocalDateTime getConsumedAt() { return consumedAt; }
    public void setConsumedAt(LocalDateTime consumedAt) { this.consumedAt = consumedAt; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
    public String getErrorMessage() { return this.errorMessage; }
    public void setErrorStackTrace(String errorStackTrace) { this.errorStackTrace = errorStackTrace; }
    public String getErrorStackTrace() { return this.errorStackTrace; }
    public void setProcessingStartedAt(LocalDateTime processingStartedAt) { this.processingStartedAt = processingStartedAt; }
    public LocalDateTime getProcessingStartedAt() { return this.processingStartedAt; }
    public void setProcessingCompletedAt(LocalDateTime processingCompletedAt) { this.processingCompletedAt = processingCompletedAt; }
    public LocalDateTime getProcessingCompletedAt() { return this.processingCompletedAt; }
    public void setTotalProcessingTimeMs(Long totalProcessingTimeMs) { this.totalProcessingTimeMs = totalProcessingTimeMs; }
    public Long getTotalProcessingTimeMs() { return this.totalProcessingTimeMs; }
    public void setApiResponseCode(Integer apiResponseCode) { this.apiResponseCode = apiResponseCode; }
    public Integer getApiResponseCode() { return this.apiResponseCode; }
    public void setApiResponseMessage(String apiResponseMessage) { this.apiResponseMessage = apiResponseMessage; }
    public String getApiResponseMessage() { return this.apiResponseMessage; }
    public void setPriority(String priority) { this.priority = priority; }
    public String getPriority() { return this.priority; }
    public static Builder builder() { return new Builder(); }
    public static class Builder {
        private Long id;
        private String correlationId;
        private String topic;
        private Integer partitionId;
        private Long offset;
        private String productId;
        private Integer quantity;
        private BigDecimal price;
        private String operation;
        private LocalDateTime consumedAt;
        private String messageHash;
        private ProcessingStatus status;
        private String errorMessage;
        private String priority;
        private String errorStackTrace;
        private String metadata;
        private Integer retryCount = 0;
        private LocalDateTime processingStartedAt;
        private LocalDateTime processingCompletedAt;
        private Long totalProcessingTimeMs;
        private Integer apiResponseCode;
        private String apiResponseMessage;
        public Builder id(Long id) { this.id = id; return this; }
        public Builder correlationId(String correlationId) { this.correlationId = correlationId; return this; }
        public Builder topic(String topic) { this.topic = topic; return this; }
        public Builder partitionId(Integer partitionId) { this.partitionId = partitionId; return this; }
        public Builder offset(Long offset) { this.offset = offset; return this; }
        public Builder productId(String productId) { this.productId = productId; return this; }
        public Builder quantity(Integer quantity) { this.quantity = quantity; return this; }
        public Builder price(BigDecimal price) { this.price = price; return this; }
        public Builder operation(String operation) { this.operation = operation; return this; }
        public Builder consumedAt(LocalDateTime consumedAt) { this.consumedAt = consumedAt; return this; }
        public Builder messageHash(String messageHash) { this.messageHash = messageHash; return this; }
        public Builder status(ProcessingStatus status) { this.status = status; return this; }
        public Builder errorMessage(String errorMessage) { this.errorMessage = errorMessage; return this; }
        public Builder priority(String priority) { this.priority = priority; return this; }
        public Builder errorStackTrace(String errorStackTrace) { this.errorStackTrace = errorStackTrace; return this; }
        public Builder metadata(String metadata) { this.metadata = metadata; return this; }
        public Builder retryCount(Integer retryCount) { this.retryCount = retryCount; return this; }
        public Builder processingStartedAt(LocalDateTime processingStartedAt) { this.processingStartedAt = processingStartedAt; return this; }
        public Builder processingCompletedAt(LocalDateTime processingCompletedAt) { this.processingCompletedAt = processingCompletedAt; return this; }
        public Builder totalProcessingTimeMs(Long totalProcessingTimeMs) { this.totalProcessingTimeMs = totalProcessingTimeMs; return this; }
        public Builder apiResponseCode(Integer apiResponseCode) { this.apiResponseCode = apiResponseCode; return this; }
        public Builder apiResponseMessage(String apiResponseMessage) { this.apiResponseMessage = apiResponseMessage; return this; }
        public ConsumptionLog build() {
            ConsumptionLog log = new ConsumptionLog(id, correlationId, topic, partitionId, offset, productId, quantity, price);
            log.operation = this.operation;
            log.consumedAt = this.consumedAt;
            log.messageHash = this.messageHash;
            log.status = this.status;
            log.errorMessage = this.errorMessage;
            log.priority = this.priority;
            log.errorStackTrace = this.errorStackTrace;
            log.metadata = this.metadata;
            log.retryCount = this.retryCount;
            log.processingStartedAt = this.processingStartedAt;
            log.processingCompletedAt = this.processingCompletedAt;
            log.totalProcessingTimeMs = this.totalProcessingTimeMs;
            log.apiResponseCode = this.apiResponseCode;
            log.apiResponseMessage = this.apiResponseMessage;
            return log;
        }
    }
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCorrelationId() { return correlationId; }
    public void setCorrelationId(String correlationId) { this.correlationId = correlationId; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public Integer getPartitionId() { return partitionId; }
    public void setPartitionId(Integer partitionId) { this.partitionId = partitionId; }
    public Long getOffset() { return offset; }
    public void setOffset(Long offset) { this.offset = offset; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    // ...existing code...
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String correlationId;
    private String topic;
    private Integer partitionId;
    private Long offset;
    private String productId;
    private Integer quantity;
    private java.math.BigDecimal price;
    private LocalDateTime processingStartedAt;
    private LocalDateTime processingCompletedAt;
    private ProcessingStatus status;
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
    private Integer retryCount = 0;
    public Integer getRetryCount() { return retryCount; }
    public void setRetryCount(Integer retryCount) { this.retryCount = retryCount; }
    public void setStatus(ProcessingStatus status) { this.status = status; }
    public ProcessingStatus getStatus() { return this.status; }
    
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
