package com.kbnt.virtualstock.infrastructure.adapter.output.kafka;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kbnt.virtualstock.domain.model.StockUpdatedEvent;
import com.kbnt.virtualstock.domain.port.output.StockEventPublisherPort;
import com.kbnt.virtualstock.infrastructure.config.EnhancedLoggingConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;
import org.springframework.util.concurrent.FailureCallback;
import org.springframework.util.concurrent.SuccessCallback;

import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.CompletableFuture;

/**
 * Kafka Stock Event Publisher Adapter
 * 
 * Infrastructure adapter that implements the StockEventPublisherPort
 * to publish stock events to Red Hat AMQ Streams (Kafka).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class KafkaStockEventPublisherAdapter implements StockEventPublisherPort {
    
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    
    @Value("${virtual-stock.kafka.topics.stock-updates:virtual-stock-updates}")
    private String stockUpdatesTopic;
    
    @Value("${virtual-stock.kafka.topics.high-priority-stock-updates:virtual-stock-high-priority-updates}")
    private String highPriorityStockUpdatesTopic;
    
    @Override
    public EventPublicationResult publishStockUpdated(StockUpdatedEvent event) {
        try {
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "KafkaEventPublisher");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(event.getCorrelationId(), null);
            
            long startTime = System.currentTimeMillis();
            
            EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("KAFKA_PUBLISH", "STARTED", 
                "Publishing stock updated event");
            
            // Determine topic based on event significance
            String topic = event.isSignificantChange() ? highPriorityStockUpdatesTopic : stockUpdatesTopic;
            
            // Create Kafka message
            KafkaStockUpdateMessage kafkaMessage = createKafkaMessage(event);
            String messageJson = objectMapper.writeValueAsString(kafkaMessage);
            
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("JSON_SERIALIZATION", 
                "Event serialized to Kafka message format");
            
            // Publish synchronously
            org.springframework.util.concurrent.ListenableFuture<SendResult<String, String>> future = 
                kafkaTemplate.send(topic, event.getCorrelationId(), messageJson);
            SendResult<String, String> result = future.get(); // Wait for completion
            
            long duration = System.currentTimeMillis() - startTime;
            EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("KAFKA_PUBLISH", duration);
            
            EnhancedLoggingConfig.LoggingUtils.logKafkaOperation("PUBLISH", topic, 
                result.getRecordMetadata().partition(), 
                String.format("Offset: %d, MessageId: %s", 
                    result.getRecordMetadata().offset(), event.getCorrelationId()));
            
            return EventPublicationResult.success(
                event.getCorrelationId(),
                String.valueOf(result.getRecordMetadata().partition()),
                result.getRecordMetadata().offset()
            );
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("KAFKA_PUBLISH", 
                "Failed to publish stock updated event", e, event.getCorrelationId());
            return EventPublicationResult.failure("Kafka publication failed: " + e.getMessage(), e);
        } finally {
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    @Override
    public void publishStockUpdatedAsync(StockUpdatedEvent event) {
        try {
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "KafkaEventPublisher");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(event.getCorrelationId(), null);
            
            EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("KAFKA_PUBLISH_ASYNC", "STARTED", 
                "Publishing stock updated event asynchronously");
            
            // Determine topic based on event significance
            String topic = event.isSignificantChange() ? highPriorityStockUpdatesTopic : stockUpdatesTopic;
            
            // Create Kafka message
            KafkaStockUpdateMessage kafkaMessage = createKafkaMessage(event);
            String messageJson = objectMapper.writeValueAsString(kafkaMessage);
            
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("JSON_SERIALIZATION", 
                "Event serialized to Kafka message format");
            
            // Publish asynchronously with callbacks
            org.springframework.util.concurrent.ListenableFuture<SendResult<String, String>> future = 
                kafkaTemplate.send(topic, event.getCorrelationId(), messageJson);
            future.addCallback(new org.springframework.util.concurrent.ListenableFutureCallback<SendResult<String, String>>() {
                @Override
                public void onSuccess(SendResult<String, String> result) {
                    EnhancedLoggingConfig.LoggingUtils.logKafkaOperation("PUBLISH_ASYNC", topic,
                        result.getRecordMetadata().partition(),
                        String.format("Offset: %d, MessageId: %s",
                            result.getRecordMetadata().offset(), event.getCorrelationId()));
                    EnhancedLoggingConfig.LoggingUtils.clearContext();
                }
                @Override
                public void onFailure(Throwable throwable) {
                    EnhancedLoggingConfig.LoggingUtils.logError("KAFKA_PUBLISH_ASYNC",
                        "Async publication failed", throwable, event.getCorrelationId());
                    EnhancedLoggingConfig.LoggingUtils.clearContext();
                }
            });
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("KAFKA_PUBLISH_ASYNC", 
                "Failed to initiate async publication", e, event.getCorrelationId());
        }
    }
    
    /**
     * Convert domain event to Kafka message format
     */
    private KafkaStockUpdateMessage createKafkaMessage(StockUpdatedEvent event) {
        return KafkaStockUpdateMessage.builder()
                .correlationId(event.getCorrelationId())
                .eventId(event.getEventId())
                .stockId(event.getStockId().getValue())
                .productId(event.getProductId().getValue())
                .symbol(event.getSymbol())
                .productName(event.getProductName())
                .previousQuantity(event.getPreviousQuantity())
                .newQuantity(event.getNewQuantity())
                .previousPrice(event.getPreviousPrice())
                .newPrice(event.getNewPrice())
                .previousStatus(event.getPreviousStatus().name())
                .newStatus(event.getNewStatus().name())
                .operation(event.getOperation().name())
                .operationDescription(event.getOperation().getDescription())
                .operationBy(event.getOperationBy())
                .occurredAt(event.getOccurredAt())
                .reason(event.getReason())
                .publishedAt(LocalDateTime.now())
                .publishedBy("VIRTUAL-STOCK-SERVICE")
                .messageHash(calculateMessageHash(event))
                .priority(event.isSignificantChange() ? "HIGH" : "NORMAL")
                .build();
    }
    
    /**
     * Calculate message hash for integrity verification
     */
    private String calculateMessageHash(StockUpdatedEvent event) {
        try {
            String content = String.format("%s:%s:%s:%d:%s", 
                event.getCorrelationId(),
                event.getProductId().getValue(),
                event.getOperation().name(),
                event.getNewQuantity(),
                event.getOccurredAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            );
            
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = digest.digest(content.getBytes("UTF-8"));
            
            StringBuilder hexString = new StringBuilder();
            for (byte b : hashBytes) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            
            return hexString.toString();
            
        } catch (Exception e) {
            log.warn("Failed to calculate message hash, using fallback", e);
            return "hash-calculation-failed-" + System.currentTimeMillis();
        }
    }
}
