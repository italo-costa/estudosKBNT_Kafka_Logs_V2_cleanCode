package com.estudoskbnt.kbntlogservice.producer;

import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import com.estudoskbnt.kbntlogservice.model.KafkaPublicationLog;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Stock Update Producer Service
 * Routes stock messages to appropriate topics based on business rules
 */
@Slf4j
@Service
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
public class StockUpdateProducer {

    private final KafkaTemplate<String, StockUpdateMessage> kafkaTemplate;
    private final ObjectMapper objectMapper;
    private final String producerId;
    
    @Value("${app.kafka.topics.stock-updates:kbnt-stock-updates}")
    private String stockUpdatesTopic;
    
    @Value("${app.kafka.topics.stock-transfers:kbnt-stock-transfers}")
    private String stockTransfersTopic;
    
    @Value("${app.kafka.topics.stock-alerts:kbnt-stock-alerts}")
    private String stockAlertsTopic;

    public StockUpdateProducer(KafkaTemplate<String, StockUpdateMessage> kafkaTemplate, 
                              ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
        this.producerId = "kbnt-producer-" + UUID.randomUUID().toString().substring(0, 8);
        
        log.info("🚀 StockUpdateProducer initialized with ID: {}", producerId);
    }

    /**
     * Process stock update with intelligent routing and detailed logging
     */
    public CompletableFuture<SendResult<String, StockUpdateMessage>> processStockUpdate(StockUpdateMessage stockMessage) {
        // Generate unique publication ID
        String publicationId = UUID.randomUUID().toString();
        LocalDateTime startTime = LocalDateTime.now();
        
        // Enrich message with metadata
        enrichStockMessage(stockMessage);
        
        // Generate message hash from timestamp for tracking
        String messageHash = generateMessageHash(stockMessage);
        
        // Determine target topic based on operation
        String targetTopic = determineTargetTopic(stockMessage);
        
        // Generate partition key for distribution
        String partitionKey = generatePartitionKey(stockMessage);
        
        // Serialize message to calculate size
        String serializedMessage = serializeMessage(stockMessage);
        int messageSizeBytes = serializedMessage.getBytes(StandardCharsets.UTF_8).length;
        
        // Create initial publication log
        KafkaPublicationLog publicationLog = KafkaPublicationLog.builder()
            .publicationId(publicationId)
            .messageHash(messageHash)
            .topicName(targetTopic)
            .correlationId(stockMessage.getCorrelationId())
            .productId(stockMessage.getProductId())
            .operation(stockMessage.getOperation())
            .messageSizeBytes(messageSizeBytes)
            .sentAt(startTime)
            .status(KafkaPublicationLog.PublicationStatus.SENT)
            .producerId(producerId)
            .messageContent(serializedMessage)
            .retryCount(0)
            .build();
        
        // Log publication attempt
        logPublicationAttempt(publicationLog, stockMessage);
        
        return kafkaTemplate.send(targetTopic, partitionKey, stockMessage)
            .whenComplete((result, exception) -> {
                LocalDateTime endTime = LocalDateTime.now();
                long processingTimeMs = java.time.Duration.between(startTime, endTime).toMillis();
                
                if (exception == null) {
                    // Update publication log with success details
                    publicationLog.setPartition(result.getRecordMetadata().partition());
                    publicationLog.setOffset(result.getRecordMetadata().offset());
                    publicationLog.setAcknowledgedAt(endTime);
                    publicationLog.setProcessingTimeMs(processingTimeMs);
                    publicationLog.setStatus(KafkaPublicationLog.PublicationStatus.ACKNOWLEDGED);
                    publicationLog.setBrokerResponse(String.format("Partition=%d, Offset=%d", 
                        result.getRecordMetadata().partition(), result.getRecordMetadata().offset()));
                    
                    // Log successful publication
                    logSuccessfulPublication(publicationLog, stockMessage);
                    
                    // Check for low stock alert
                    checkLowStockAlert(stockMessage);
                } else {
                    // Update publication log with failure details
                    publicationLog.setAcknowledgedAt(endTime);
                    publicationLog.setProcessingTimeMs(processingTimeMs);
                    publicationLog.setStatus(KafkaPublicationLog.PublicationStatus.FAILED);
                    publicationLog.setErrorMessage(exception.getMessage());
                    
                    // Log failed publication
                    logFailedPublication(publicationLog, stockMessage, exception);
                }
            });
    }

    /**
     * Stock addition (purchase, return)
     */
    public CompletableFuture<SendResult<String, StockUpdateMessage>> addStock(
            String productId, String distributionCenter, String branch, 
            Integer quantity, String reasonCode, String referenceDocument) {
        
        StockUpdateMessage message = StockUpdateMessage.builder()
            .productId(productId)
            .distributionCenter(distributionCenter)
            .branch(branch)
            .quantity(quantity)
            .operation("ADD")
            .reasonCode(reasonCode)
            .referenceDocument(referenceDocument)
            .build();
            
        return processStockUpdate(message);
    }

    /**
     * Stock removal (sale, adjustment)
     */
    public CompletableFuture<SendResult<String, StockUpdateMessage>> removeStock(
            String productId, String distributionCenter, String branch, 
            Integer quantity, String reasonCode, String referenceDocument) {
        
        StockUpdateMessage message = StockUpdateMessage.builder()
            .productId(productId)
            .distributionCenter(distributionCenter)
            .branch(branch)
            .quantity(quantity)
            .operation("REMOVE")
            .reasonCode(reasonCode)
            .referenceDocument(referenceDocument)
            .build();
            
        return processStockUpdate(message);
    }

    /**
     * Stock transfer between branches
     */
    public CompletableFuture<SendResult<String, StockUpdateMessage>> transferStock(
            String productId, String distributionCenter, 
            String sourceBranch, String targetBranch, 
            Integer quantity, String referenceDocument) {
        
        StockUpdateMessage message = StockUpdateMessage.builder()
            .productId(productId)
            .distributionCenter(distributionCenter)
            .branch(targetBranch)
            .sourceBranch(sourceBranch)
            .quantity(quantity)
            .operation("TRANSFER")
            .reasonCode("TRANSFER")
            .referenceDocument(referenceDocument)
            .build();
            
        return processStockUpdate(message);
    }

    /**
     * Set absolute stock quantity
     */
    public CompletableFuture<SendResult<String, StockUpdateMessage>> setStock(
            String productId, String distributionCenter, String branch, 
            Integer quantity, String reasonCode, String referenceDocument) {
        
        StockUpdateMessage message = StockUpdateMessage.builder()
            .productId(productId)
            .distributionCenter(distributionCenter)
            .branch(branch)
            .quantity(quantity)
            .operation("SET")
            .reasonCode(reasonCode)
            .referenceDocument(referenceDocument)
            .build();
            
        return processStockUpdate(message);
    }

    private void enrichStockMessage(StockUpdateMessage stockMessage) {
        if (stockMessage.getTimestamp() == null) {
            stockMessage.setTimestamp(LocalDateTime.now());
        }
        
        if (stockMessage.getCorrelationId() == null || stockMessage.getCorrelationId().isEmpty()) {
            stockMessage.setCorrelationId(UUID.randomUUID().toString());
        }
        
        // Validate business rules
        validateStockOperation(stockMessage);
    }

    private String determineTargetTopic(StockUpdateMessage stockMessage) {
        // Transfer operations go to dedicated topic
        if ("TRANSFER".equals(stockMessage.getOperation())) {
            return stockTransfersTopic;
        }
        
        // All other operations go to main stock updates topic
        return stockUpdatesTopic;
    }

    private String generatePartitionKey(StockUpdateMessage stockMessage) {
        // Partition by distribution center + product for balanced load
        return String.format("%s-%s", 
            stockMessage.getDistributionCenter(),
            stockMessage.getProductId());
    }

    private void validateStockOperation(StockUpdateMessage stockMessage) {
        // Validate quantity based on operation
        if ("REMOVE".equals(stockMessage.getOperation()) && stockMessage.getQuantity() <= 0) {
            throw new IllegalArgumentException("Remove operation requires positive quantity");
        }
        
        // Validate transfer has source branch
        if ("TRANSFER".equals(stockMessage.getOperation()) && 
            (stockMessage.getSourceBranch() == null || stockMessage.getSourceBranch().isEmpty())) {
            throw new IllegalArgumentException("Transfer operation requires source branch");
        }
        
        // Validate branch is different for transfers
        if ("TRANSFER".equals(stockMessage.getOperation()) && 
            stockMessage.getBranch().equals(stockMessage.getSourceBranch())) {
            throw new IllegalArgumentException("Transfer source and target branch cannot be the same");
        }
    }

    private void checkLowStockAlert(StockUpdateMessage stockMessage) {
        // Send low stock alert if quantity is below threshold
        // This would typically check against a configurable threshold per product
        if (stockMessage.getQuantity() != null && stockMessage.getQuantity() < 10) {
            
            log.warn("⚠️ Low stock alert for product {} at {}-{}: quantity={}", 
                stockMessage.getProductId(),
                stockMessage.getDistributionCenter(),
                stockMessage.getBranch(),
                stockMessage.getQuantity());
            
            // Send alert to monitoring topic (async)
            CompletableFuture.runAsync(() -> {
                try {
                    kafkaTemplate.send(stockAlertsTopic, 
                        stockMessage.getProductId(), stockMessage);
                } catch (Exception e) {
                    log.warn("Failed to send low stock alert: {}", e.getMessage());
                }
            });
        }
    }

    // ===================== PRIVATE HELPER METHODS =====================

    /**
     * Generate SHA-256 hash from message timestamp for unique tracking
     */
    private String generateMessageHash(StockUpdateMessage stockMessage) {
        try {
            String timestampString = stockMessage.getTimestamp() != null ? 
                stockMessage.getTimestamp().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) :
                LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            
            String hashInput = String.format("%s-%s-%s-%s", 
                timestampString,
                stockMessage.getProductId(),
                stockMessage.getOperation(),
                stockMessage.getCorrelationId());
            
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(hashInput.getBytes(StandardCharsets.UTF_8));
            
            // Convert to hex string
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            
            return hexString.substring(0, 16); // First 16 chars for readability
        } catch (NoSuchAlgorithmException e) {
            log.warn("SHA-256 not available, using fallback hash generation");
            return String.valueOf((stockMessage.getTimestamp() + stockMessage.getProductId()).hashCode());
        }
    }

    /**
     * Serialize message to JSON string
     */
    private String serializeMessage(StockUpdateMessage stockMessage) {
        try {
            return objectMapper.writeValueAsString(stockMessage);
        } catch (JsonProcessingException e) {
            log.warn("Failed to serialize message for logging: {}", e.getMessage());
            return String.format("{\"productId\":\"%s\",\"operation\":\"%s\"}", 
                stockMessage.getProductId(), stockMessage.getOperation());
        }
    }

    /**
     * Log publication attempt with detailed information
     */
    private void logPublicationAttempt(KafkaPublicationLog publicationLog, StockUpdateMessage stockMessage) {
        log.info("📤 [PUBLISH-ATTEMPT] ID={} | Hash={} | Topic={} | Product={} | Operation={} | Size={}B | Producer={}",
            publicationLog.getPublicationId(),
            publicationLog.getMessageHash(),
            publicationLog.getTopicName(),
            stockMessage.getProductId(),
            stockMessage.getOperation(),
            publicationLog.getMessageSizeBytes(),
            producerId);
        
        log.debug("📋 [PUBLISH-DETAILS] ID={} | Correlation={} | Location={}-{} | Quantity={} | Reason={}",
            publicationLog.getPublicationId(),
            stockMessage.getCorrelationId(),
            stockMessage.getDistributionCenter(),
            stockMessage.getBranch(),
            stockMessage.getQuantity(),
            stockMessage.getReasonCode());
    }

    /**
     * Log successful publication with commit details
     */
    private void logSuccessfulPublication(KafkaPublicationLog publicationLog, StockUpdateMessage stockMessage) {
        log.info("✅ [PUBLISH-SUCCESS] ID={} | Hash={} | Topic={} | Partition={} | Offset={} | Time={}ms | Commit=CONFIRMED",
            publicationLog.getPublicationId(),
            publicationLog.getMessageHash(),
            publicationLog.getTopicName(),
            publicationLog.getPartition(),
            publicationLog.getOffset(),
            publicationLog.getProcessingTimeMs());
        
        log.debug("🎯 [KAFKA-COMMIT] ID={} | Broker-Response=[{}] | Ack-Time={} | Message-Hash={}",
            publicationLog.getPublicationId(),
            publicationLog.getBrokerResponse(),
            publicationLog.getAcknowledgedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
            publicationLog.getMessageHash());
        
        // Log structured data for monitoring/metrics
        log.info("📊 [METRICS] PublicationId={} MessageHash={} Topic={} Partition={} Offset={} ProcessingTimeMs={} Status=SUCCESS Producer={}",
            publicationLog.getPublicationId(),
            publicationLog.getMessageHash(),
            publicationLog.getTopicName(),
            publicationLog.getPartition(),
            publicationLog.getOffset(),
            publicationLog.getProcessingTimeMs(),
            producerId);
    }

    /**
     * Log failed publication with error details
     */
    private void logFailedPublication(KafkaPublicationLog publicationLog, StockUpdateMessage stockMessage, Throwable exception) {
        log.error("❌ [PUBLISH-FAILED] ID={} | Hash={} | Topic={} | Error={} | Time={}ms | Commit=FAILED",
            publicationLog.getPublicationId(),
            publicationLog.getMessageHash(),
            publicationLog.getTopicName(),
            exception.getMessage(),
            publicationLog.getProcessingTimeMs());
        
        log.debug("💥 [ERROR-DETAILS] ID={} | Product={} | Operation={} | Exception={}",
            publicationLog.getPublicationId(),
            stockMessage.getProductId(),
            stockMessage.getOperation(),
            exception.getClass().getSimpleName());
        
        // Log structured data for monitoring/alerting
        log.error("📊 [METRICS] PublicationId={} MessageHash={} Topic={} ProcessingTimeMs={} Status=FAILED Error={} Producer={}",
            publicationLog.getPublicationId(),
            publicationLog.getMessageHash(),
            publicationLog.getTopicName(),
            publicationLog.getProcessingTimeMs(),
            exception.getMessage().replaceAll("\\s+", "_"),
            producerId);
    }

    private void enrichStockMessage(StockUpdateMessage stockMessage) {
        if (stockMessage.getTimestamp() == null) {
            stockMessage.setTimestamp(LocalDateTime.now());
        }
        
        if (stockMessage.getCorrelationId() == null || stockMessage.getCorrelationId().isEmpty()) {
            stockMessage.setCorrelationId(UUID.randomUUID().toString());
        }
        
        // Validate business rules
        validateStockOperation(stockMessage);
    }

    private String determineTargetTopic(StockUpdateMessage stockMessage) {
        // Transfer operations go to dedicated topic
        if ("TRANSFER".equals(stockMessage.getOperation())) {
            return stockTransfersTopic;
        }
        
        // All other operations go to main stock updates topic
        return stockUpdatesTopic;
    }

    private String generatePartitionKey(StockUpdateMessage stockMessage) {
        // Partition by distribution center + product for balanced load
        return String.format("%s-%s", 
            stockMessage.getDistributionCenter(),
            stockMessage.getProductId());
    }

    private void validateStockOperation(StockUpdateMessage stockMessage) {
        // Validate quantity based on operation
        if ("REMOVE".equals(stockMessage.getOperation()) && stockMessage.getQuantity() <= 0) {
            throw new IllegalArgumentException("Remove operation requires positive quantity");
        }
        
        // Validate transfer has source branch
        if ("TRANSFER".equals(stockMessage.getOperation()) && 
            (stockMessage.getSourceBranch() == null || stockMessage.getSourceBranch().isEmpty())) {
            throw new IllegalArgumentException("Transfer operation requires source branch");
        }
        
        // Validate branch is different for transfers
        if ("TRANSFER".equals(stockMessage.getOperation()) && 
            stockMessage.getBranch().equals(stockMessage.getSourceBranch())) {
            throw new IllegalArgumentException("Transfer source and target branch cannot be the same");
        }
    }

    private void checkLowStockAlert(StockUpdateMessage stockMessage) {
        // Send low stock alert if quantity is below threshold
        // This would typically check against a configurable threshold per product
        if (stockMessage.getQuantity() != null && stockMessage.getQuantity() < 10) {
            
            String alertPublicationId = UUID.randomUUID().toString();
            String alertHash = generateMessageHash(stockMessage);
            
            log.warn("⚠️ [LOW-STOCK-ALERT] ID={} | Hash={} | Product={} | Location={}-{} | Quantity={} | Threshold=10",
                alertPublicationId,
                alertHash,
                stockMessage.getProductId(),
                stockMessage.getDistributionCenter(),
                stockMessage.getBranch(),
                stockMessage.getQuantity());
            
            // Send alert to monitoring topic (async)
            CompletableFuture.runAsync(() -> {
                try {
                    LocalDateTime alertStartTime = LocalDateTime.now();
                    
                    log.info("📤 [ALERT-PUBLISH] ID={} | Hash={} | Topic={} | Product={} | Alert-Type=LOW_STOCK",
                        alertPublicationId,
                        alertHash,
                        stockAlertsTopic,
                        stockMessage.getProductId());
                    
                    kafkaTemplate.send(stockAlertsTopic, stockMessage.getProductId(), stockMessage)
                        .whenComplete((alertResult, alertException) -> {
                            LocalDateTime alertEndTime = LocalDateTime.now();
                            long alertProcessingTime = java.time.Duration.between(alertStartTime, alertEndTime).toMillis();
                            
                            if (alertException == null) {
                                log.info("✅ [ALERT-SUCCESS] ID={} | Hash={} | Topic={} | Partition={} | Offset={} | Time={}ms",
                                    alertPublicationId,
                                    alertHash,
                                    stockAlertsTopic,
                                    alertResult.getRecordMetadata().partition(),
                                    alertResult.getRecordMetadata().offset(),
                                    alertProcessingTime);
                            } else {
                                log.error("❌ [ALERT-FAILED] ID={} | Hash={} | Topic={} | Error={} | Time={}ms",
                                    alertPublicationId,
                                    alertHash,
                                    stockAlertsTopic,
                                    alertException.getMessage(),
                                    alertProcessingTime);
                            }
                        });
                } catch (Exception e) {
                    log.error("💥 [ALERT-EXCEPTION] ID={} | Error={}", alertPublicationId, e.getMessage());
                }
            });
        }
    }
}
