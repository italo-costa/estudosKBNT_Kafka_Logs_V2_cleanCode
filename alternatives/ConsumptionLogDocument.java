package com.estudoskbnt.consumer.document;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * Elasticsearch Document for Consumption Logs
 * 
 * Stores audit information about consumed Kafka messages and their processing results
 * optimized for Elasticsearch storage and search capabilities.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsumptionLogDocument {
    
    /**
     * Elasticsearch timestamp field (required for time-based indices)
     */
    @JsonProperty("@timestamp")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
    private LocalDateTime timestamp;
    
    /**
     * Correlation ID from the original message
     */
    @JsonProperty("correlation_id")
    private String correlationId;
    
    /**
     * Message hash for verification and duplicate detection
     */
    @JsonProperty("message_hash")
    private String messageHash;
    
    /**
     * Kafka topic name
     */
    private String topic;
    
    /**
     * Kafka partition ID
     */
    private Integer partition;
    
    /**
     * Kafka offset
     */
    private Long offset;
    
    /**
     * Product ID from the message
     */
    @JsonProperty("product_id")
    private String productId;
    
    /**
     * Stock quantity from the message
     */
    private Integer quantity;
    
    /**
     * Product price from the message
     */
    private BigDecimal price;
    
    /**
     * Operation type from the message
     */
    private String operation;
    
    /**
     * Processing status
     */
    private String status;
    
    /**
     * When the message processing started
     */
    @JsonProperty("processing_started_at")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
    private LocalDateTime processingStartedAt;
    
    /**
     * When the message processing completed
     */
    @JsonProperty("processing_completed_at") 
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
    private LocalDateTime processingCompletedAt;
    
    /**
     * Total processing time in milliseconds
     */
    @JsonProperty("processing_time_ms")
    private Long processingTimeMs;
    
    /**
     * External API response information
     */
    @JsonProperty("api_response")
    private ApiResponseDocument apiResponse;
    
    /**
     * External API call details
     */
    @JsonProperty("external_api")
    private ExternalApiDocument externalApi;
    
    /**
     * Error information if processing failed
     */
    @JsonProperty("error_message")
    private String errorMessage;
    
    /**
     * Error stack trace if processing failed
     */
    @JsonProperty("error_stack_trace")
    private String errorStackTrace;
    
    /**
     * Number of retry attempts made
     */
    @JsonProperty("retry_count")
    @Builder.Default
    private Integer retryCount = 0;
    
    /**
     * Message priority level
     */
    private String priority;
    
    /**
     * Additional processing metadata
     */
    private Map<String, Object> metadata;
    
    /**
     * Consumer instance information
     */
    @JsonProperty("consumer_instance")
    private String consumerInstance;
    
    /**
     * Environment information
     */
    private String environment;
    
    /**
     * Application version
     */
    private String version;
    
    /**
     * Calculate processing time if both timestamps are available
     */
    public void calculateAndSetProcessingTime() {
        if (processingStartedAt != null && processingCompletedAt != null) {
            this.processingTimeMs = java.time.Duration.between(processingStartedAt, processingCompletedAt).toMillis();
        }
    }
    
    /**
     * Check if processing was successful
     */
    public boolean isSuccessful() {
        return "SUCCESS".equals(status);
    }
    
    /**
     * Check if processing failed
     */
    public boolean isFailed() {
        return "FAILED".equals(status) || "RETRY_EXHAUSTED".equals(status);
    }
    
    /**
     * API Response Document for nested object
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ApiResponseDocument {
        
        /**
         * HTTP response code
         */
        private Integer code;
        
        /**
         * Response message
         */
        private String message;
        
        /**
         * API call duration in milliseconds
         */
        @JsonProperty("duration_ms")
        private Long durationMs;
        
        /**
         * Response payload size in bytes
         */
        @JsonProperty("response_size_bytes")
        private Long responseSizeBytes;
        
        /**
         * Success indicator
         */
        private Boolean success;
    }
    
    /**
     * External API Document for nested object
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExternalApiDocument {
        
        /**
         * API endpoint URL
         */
        private String endpoint;
        
        /**
         * HTTP method used
         */
        private String method;
        
        /**
         * API response time in milliseconds
         */
        @JsonProperty("response_time_ms")
        private Long responseTimeMs;
        
        /**
         * Request payload size in bytes
         */
        @JsonProperty("request_size_bytes")
        private Long requestSizeBytes;
        
        /**
         * Number of retry attempts for this API call
         */
        @JsonProperty("api_retry_count")
        private Integer apiRetryCount;
        
        /**
         * API provider information
         */
        private String provider;
        
        /**
         * API version
         */
        @JsonProperty("api_version")
        private String apiVersion;
    }
    
    /**
     * Processing status constants
     */
    public static class Status {
        public static final String RECEIVED = "RECEIVED";
        public static final String PROCESSING = "PROCESSING";
        public static final String SUCCESS = "SUCCESS";
        public static final String FAILED = "FAILED";
        public static final String RETRY_SCHEDULED = "RETRY_SCHEDULED";
        public static final String RETRY_EXHAUSTED = "RETRY_EXHAUSTED";
        public static final String DISCARDED = "DISCARDED";
    }
    
    /**
     * Operation type constants
     */
    public static class Operation {
        public static final String INCREASE = "INCREASE";
        public static final String DECREASE = "DECREASE";
        public static final String SET = "SET";
        public static final String SYNC = "SYNC";
    }
    
    /**
     * Priority level constants
     */
    public static class Priority {
        public static final String LOW = "LOW";
        public static final String NORMAL = "NORMAL";
        public static final String HIGH = "HIGH";
        public static final String CRITICAL = "CRITICAL";
    }
}
