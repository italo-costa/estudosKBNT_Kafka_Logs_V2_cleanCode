package com.estudoskbnt.consumer.service;

import com.estudoskbnt.consumer.entity.ConsumptionLog;
import com.estudoskbnt.consumer.model.StockUpdateMessage;
import com.estudoskbnt.consumer.repository.ConsumptionLogRepository;
import com.estudoskbnt.consumer.service.ExternalApiService.ApiResponse;
import com.estudoskbnt.consumer.config.EnhancedLoggingConfig;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.MDC;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.annotation.RetryableTopic;
import org.springframework.kafka.retrytopic.TopicSuffixingStrategy;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.retry.annotation.Backoff;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Mono;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.concurrent.CompletableFuture;

/**
 * Kafka Consumer Service
 * 
 * Main service for consuming stock update messages from Red Hat AMQ Streams.
 * Handles message processing, external API calls, and consumption logging.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaConsumerService {
    // Declare consumptionLog variable
    private ConsumptionLog consumptionLog;
    // Logger instance
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(KafkaConsumerService.class);
    // Utility to generate a unique message ID from Kafka record
    private String generateMessageId(org.apache.kafka.clients.consumer.ConsumerRecord<String, String> record) {
        return record.topic() + "-" + record.partition() + "-" + record.offset();
    }
    // ...existing code...
    
    private final ExternalApiService externalApiService;
    private final ConsumptionLogRepository consumptionLogRepository;
    private final ObjectMapper objectMapper;
    private final MessageHashService messageHashService;
    
    /**
     * Main Kafka listener for stock update messages
     * 
     * Consumes messages from multiple topics with retry logic and error handling.
     */
    @KafkaListener(
    topics = {"${app.kafka.topics.stock-updates}", 
          "${app.kafka.topics.high-priority-stock-updates}"},
    groupId = "${app.kafka.consumer.group}",
    containerFactory = "kafkaListenerContainerFactory"
    )
    @RetryableTopic(
        attempts = "${app.kafka.consumer.retry.max-attempts:3}",
        backoff = @Backoff(delay = 1000, multiplier = 2.0),
        autoCreateTopics = "true",
        topicSuffixingStrategy = TopicSuffixingStrategy.SUFFIX_WITH_INDEX_VALUE,
        dltStrategy = org.springframework.kafka.retrytopic.DltStrategy.ALWAYS_RETRY_ON_ERROR,
        include = {Exception.class}
    )
    public void consumeStockUpdateMessage(
            @Payload String messagePayload,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            @Header(name = KafkaHeaders.RECEIVED_TIMESTAMP, required = false) Long timestamp,
            ConsumerRecord<String, String> record,
            Acknowledgment acknowledgment) {
        
        LocalDateTime consumedAt = LocalDateTime.now();
        String messageId = generateMessageId(record);
        
        try {
            long startTime = System.currentTimeMillis();
            final long startTimeFinal = startTime;
            final Acknowledgment acknowledgmentFinal = acknowledgment;
            final String messageIdFinal = messageId;
            final String topicFinal = topic;
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("ACL-VIRTUAL-STOCK", "KafkaConsumerService");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(messageId, topic);
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("KAFKA_CONSUMER", 
                String.format("Message received - Topic: %s, Partition: %d, Offset: %d", 
                    topic, partition, offset));
            ConsumptionLog consumptionLog = null;
            StockUpdateMessage message = null;
            final StockUpdateMessage messageFinal;
            // Parse message
            try {
                message = objectMapper.readValue(messagePayload, StockUpdateMessage.class);
                messageFinal = message;
            } catch (JsonProcessingException e) {
                EnhancedLoggingConfig.LoggingUtils.logError("JSON_PARSING", 
                    "Failed to parse message payload", e, messageId);
                handleParsingError(messagePayload, topic, partition, offset, consumedAt, e);
                acknowledgment.acknowledge();
                return;
            }
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("JSON_DESERIALIZATION", 
                String.format("Message parsed successfully - CorrelationId: %s, ProductId: %s", 
                    message.getCorrelationId(), message.getProductId()));
            // Create initial consumption log
            consumptionLog = createInitialConsumptionLog(message, topic, partition, 
                    offset, consumedAt);
            consumptionLog = consumptionLogRepository.save(consumptionLog);
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("DATABASE_OPERATION", 
                "Initial consumption log created and saved");
            // Validate message hash
            if (!validateMessageHash(message)) {
                EnhancedLoggingConfig.LoggingUtils.logError("HASH_VALIDATION", 
                    "Message hash validation failed", null, messageId);
                throw new RuntimeException("Message hash validation failed");
            }
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("HASH_VALIDATION", 
                "Message hash validation successful");
            // Check for duplicate processing
            if (isDuplicateMessage(message)) {
                EnhancedLoggingConfig.LoggingUtils.logComponentInfo("DUPLICATE_CHECK", 
                    String.format("Duplicate message detected - CorrelationId: %s", 
                        message.getCorrelationId()));
                updateLogStatus(consumptionLog, ConsumptionLog.ProcessingStatus.DISCARDED,
                        "Duplicate message detected");
                acknowledgment.acknowledge();
                return;
            }
            // Check if message has expired
            if (message.isExpired()) {
                EnhancedLoggingConfig.LoggingUtils.logComponentInfo("EXPIRY_CHECK", 
                    String.format("Message expired - CorrelationId: %s", 
                        message.getCorrelationId()));
                updateLogStatus(consumptionLog, ConsumptionLog.ProcessingStatus.DISCARDED,
                        "Message expired");
                acknowledgment.acknowledge();
                return;
            }
            // Process message asynchronously
            processMessageAsync(message, consumptionLog)
                    .whenComplete((result, throwable) -> {
                        long duration = System.currentTimeMillis() - startTimeFinal;
                        if (throwable != null) {
                            EnhancedLoggingConfig.LoggingUtils.logError("ASYNC_PROCESSING", 
                                "Async processing failed", throwable, messageFinal.getCorrelationId());
                        } else {
                            EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("MESSAGE_PROCESSING", duration);
                            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("ASYNC_PROCESSING", 
                                String.format("Processing completed successfully - Duration: %dms", duration));
                        }
                        acknowledgmentFinal.acknowledge();
                        EnhancedLoggingConfig.LoggingUtils.logComponentInfo("KAFKA_ACK", 
                            "Message acknowledged");
                    });
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("MESSAGE_PROCESSING", 
                "Unexpected error processing message", e, messageId);
            if (consumptionLog != null) {
                updateLogWithError(consumptionLog, e);
            }
            // Let retry mechanism handle the error by not acknowledging
            throw new RuntimeException("Processing failed", e);
        } finally {
            // Always clear MDC context
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    /**
     * Process message asynchronously
     */
    private CompletableFuture<Void> processMessageAsync(StockUpdateMessage message, 
                                                       ConsumptionLog consumptionLog) {
        return CompletableFuture.runAsync(() -> {
            try {
                processMessage(message, consumptionLog);
            } catch (Exception e) {
                log.error("Error in async processing", e);
                updateLogWithError(consumptionLog, e);
            }
        });
    }
    
    /**
     * Process the stock update message
     */
    @Transactional
    public void processMessage(StockUpdateMessage message, ConsumptionLog consumptionLog) {
        LocalDateTime processingStartedAt = LocalDateTime.now();
        String correlationId = message.getCorrelationId();
        
        try {
            // Set logging context for this processing
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("ACL-VIRTUAL-STOCK", "MessageProcessor");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(correlationId, null);
            
            // Update log to processing status
            updateLogStatus(consumptionLog, ConsumptionLog.ProcessingStatus.PROCESSING, null);
            consumptionLog.setProcessingStartedAt(processingStartedAt);
            consumptionLogRepository.save(consumptionLog);
            
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("DATABASE_OPERATION", 
                String.format("Processing status updated - ProductId: %s", message.getProductId()));
            
            // Validate product before processing
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("EXTERNAL_API_CALL", 
                "Starting product validation");
            
            boolean isValidProduct = externalApiService.validateProduct(message.getProductId())
                    .map(validation -> validation.isValid())
                    .defaultIfEmpty(false)
                    .block();
            
            if (!isValidProduct) {
                EnhancedLoggingConfig.LoggingUtils.logError("PRODUCT_VALIDATION", 
                    "Product validation failed", null, message.getProductId());
                throw new RuntimeException("Product validation failed: " + message.getProductId());
            }
            
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("PRODUCT_VALIDATION", 
                "Product validation successful");
            
            // Process stock update via external API
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("EXTERNAL_API_CALL", 
                "Processing stock update");
            
            ApiResponse apiResponse = externalApiService.processStockUpdate(message)
                    .block();
            
            if (apiResponse == null) {
                EnhancedLoggingConfig.LoggingUtils.logError("EXTERNAL_API_CALL", 
                    "No response from external API", null, correlationId);
                throw new RuntimeException("No response from external API");
            }
            
            LocalDateTime processingCompletedAt = LocalDateTime.now();
            Long processingTime = calculateProcessingTime(processingStartedAt, processingCompletedAt);
            
            // Log performance metrics
            EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("MESSAGE_PROCESSING", processingTime);
            
            // Update consumption log with results
            consumptionLog.setProcessingCompletedAt(processingCompletedAt);
            consumptionLog.setTotalProcessingTimeMs(processingTime);
            consumptionLog.setApiResponseCode(apiResponse.getHttpStatus());
            consumptionLog.setApiResponseMessage(apiResponse.getMessage());
            
            if (apiResponse.isSuccess()) {
                consumptionLog.setStatus(ConsumptionLog.ProcessingStatus.SUCCESS);
                
                EnhancedLoggingConfig.LoggingUtils.logComponentInfo("PROCESSING_SUCCESS", 
                    String.format("Stock update completed successfully - ProductId: %s, Duration: %dms", 
                        message.getProductId(), processingTime));
                
                // Send success notification
                sendNotificationAsync(message.getCorrelationId(), message.getProductId(), 
                        true, "Stock update processed successfully");
                
            } else {
                consumptionLog.setStatus(ConsumptionLog.ProcessingStatus.FAILED);
                consumptionLog.setErrorMessage("API processing failed: " + apiResponse.getMessage());
                
                EnhancedLoggingConfig.LoggingUtils.logError("PROCESSING_FAILED", 
                    "API processing failed", null, message.getProductId());
                
                // Send failure notification
                sendNotificationAsync(message.getCorrelationId(), message.getProductId(), 
                        false, "Stock update processing failed: " + apiResponse.getMessage());
            }
            
            consumptionLogRepository.save(consumptionLog);
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("DATABASE_OPERATION", 
                "Final consumption log saved");
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("MESSAGE_PROCESSING", 
                "Error processing stock update", e, message.getProductId());
            updateLogWithError(consumptionLog, e);
            
            // Send error notification
            sendNotificationAsync(message.getCorrelationId(), message.getProductId(), 
                    false, "Processing error: " + e.getMessage());
            
            throw e;
        } finally {
            // Clear logging context
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    /**
     * Create initial consumption log entry
     */
    private ConsumptionLog createInitialConsumptionLog(StockUpdateMessage message, 
                                                      String topic, int partition, 
                                                      long offset, LocalDateTime consumedAt) {
        return ConsumptionLog.builder()
                .correlationId(message.getCorrelationId())
                .topic(topic)
                .partitionId(partition)
                .offset(offset)
                .productId(message.getProductId())
                .quantity(message.getQuantity())
                .price(message.getPrice())
                .operation(message.getOperation())
                .messageHash(message.getHash())
                .consumedAt(consumedAt)
                .status(ConsumptionLog.ProcessingStatus.RECEIVED)
                .retryCount(0)
                .priority(message.getPriority())
                .build();
    }
    
    /**
     * Update consumption log status
     */
    private void updateLogStatus(ConsumptionLog log, ConsumptionLog.ProcessingStatus status, 
                               String message) {
        log.setStatus(status);
        if (message != null) {
            log.setErrorMessage(message);
        }
        consumptionLogRepository.save(log);
    }
    
    /**
     * Update consumption log with error information
     */
    private void updateLogWithError(ConsumptionLog log, Exception error) {
        log.setStatus(ConsumptionLog.ProcessingStatus.FAILED);
        log.setErrorMessage(error.getMessage());
        log.setErrorStackTrace(getStackTrace(error));
        log.setProcessingCompletedAt(LocalDateTime.now());
        
        if (log.getProcessingStartedAt() != null) {
            log.setTotalProcessingTimeMs(
                    calculateProcessingTime(log.getProcessingStartedAt(), 
                            log.getProcessingCompletedAt()));
        }
        
        consumptionLogRepository.save(log);
    }
    
    /**
     * Handle parsing errors for malformed messages
     */
    private void handleParsingError(String messagePayload, String topic, int partition, 
                                  long offset, LocalDateTime consumedAt, Exception error) {
        ConsumptionLog errorLog = ConsumptionLog.builder()
                .correlationId("PARSE_ERROR_" + offset)
                .topic(topic)
                .partitionId(partition)
                .offset(offset)
                .productId("UNKNOWN")
                .consumedAt(consumedAt)
                .status(ConsumptionLog.ProcessingStatus.FAILED)
                .errorMessage("Failed to parse message: " + error.getMessage())
                .errorStackTrace(getStackTrace(error))
                .metadata("Raw payload: " + messagePayload)
                .build();
        
        consumptionLogRepository.save(errorLog);
    }
    
    /**
     * Validate message hash
     */
    private boolean validateMessageHash(StockUpdateMessage message) {
        try {
            String calculatedHash = messageHashService.calculateMessageHash(message);
            return calculatedHash.equals(message.getHash());
        } catch (Exception e) {
            log.error("Error validating message hash", e);
            return false;
        }
    }
    
    /**
     * Check if message is duplicate
     */
    private boolean isDuplicateMessage(StockUpdateMessage message) {
        return consumptionLogRepository.isMessageAlreadyProcessed(
                message.getCorrelationId(), message.getHash());
    }
    
    /**
     * Calculate processing time between two timestamps
     */
    private Long calculateProcessingTime(LocalDateTime start, LocalDateTime end) {
        if (start != null && end != null) {
            return java.time.Duration.between(start, end).toMillis();
        }
        return null;
    }
    
    /**
     * Get stack trace as string
     */
    private String getStackTrace(Exception e) {
        java.io.StringWriter sw = new java.io.StringWriter();
        java.io.PrintWriter pw = new java.io.PrintWriter(sw);
        e.printStackTrace(pw);
        String stackTrace = sw.toString();
        
        // Limit stack trace length
        if (stackTrace.length() > 4000) {
            return stackTrace.substring(0, 4000) + "... (truncated)";
        }
        return stackTrace;
    }
    
    /**
     * Send notification asynchronously
     */
    private void sendNotificationAsync(String correlationId, String productId, 
                                     boolean success, String message) {
    externalApiService.sendNotification(correlationId, productId, success, message)
        .subscribe(
            result -> log.debug("Notification sent for correlation ID: {}", correlationId),
            error -> log.warn("Failed to send notification for correlation ID: {} - Error: {}", 
                correlationId, error.getMessage())
        );
    }
}
