package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka;

import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;
import com.estudoskbnt.kbntlogservice.domain.port.output.EventPublisherPort;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * Kafka Event Publisher Adapter
 * 
 * Infrastructure adapter that publishes domain events to Kafka topics.
 * Implements the EventPublisherPort from the domain layer.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KafkaEventPublisherAdapter implements EventPublisherPort {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper = createObjectMapper();

    @Override
    public CompletableFuture<Void> publishStockUpdateEvent(StockUpdateEvent event) {
        log.debug("📤 Publishing stock update event: {} for product {} to topic {}", 
                event.getEventType(), event.getProductId().getValue(), event.getTargetTopic());

        try {
            // Convert domain event to Kafka message
            KafkaStockUpdateMessage message = createKafkaMessage(event);
            String messageJson = objectMapper.writeValueAsString(message);
            
            // Use product ID as partition key for ordering
            String partitionKey = event.getProductId().getValue();
            
            CompletableFuture<SendResult<String, String>> sendFuture = 
                    kafkaTemplate.send(event.getTargetTopic(), partitionKey, messageJson);
            
            return sendFuture
                    .thenApply(result -> {
                        log.info("✅ Successfully published event {} to topic {} partition {} offset {}", 
                                event.getEventId(), 
                                event.getTargetTopic(),
                                result.getRecordMetadata().partition(),
                                result.getRecordMetadata().offset());
                        return null;
                    })
                    .exceptionally(throwable -> {
                        log.error("❌ Failed to publish event {} to topic {}: {}", 
                                event.getEventId(), event.getTargetTopic(), throwable.getMessage(), throwable);
                        throw new EventPublicationException(
                                "Failed to publish stock update event: " + throwable.getMessage(), throwable);
                    });
                    
        } catch (JsonProcessingException e) {
            log.error("❌ Failed to serialize event {} to JSON: {}", event.getEventId(), e.getMessage());
            CompletableFuture<Void> future = new CompletableFuture<>();
            future.completeExceptionally(new EventPublicationException(
                    "Failed to serialize stock update event: " + e.getMessage(), e));
            return future;
        }
    }

    @Override
    public CompletableFuture<Void> publishAuditEvent(StockUpdateEvent event) {
        log.debug("📤 Publishing audit event: {} for product {}", 
                event.getEventType(), event.getProductId().getValue());

        try {
            // Create audit-specific message format
            KafkaAuditMessage auditMessage = createAuditMessage(event);
            String messageJson = objectMapper.writeValueAsString(auditMessage);
            
            // Use correlation ID as partition key for audit trail
            String partitionKey = event.getCorrelationId().getValue();
            String auditTopic = "kbnt-audit-logs";
            
            CompletableFuture<SendResult<String, String>> sendFuture = 
                    kafkaTemplate.send(auditTopic, partitionKey, messageJson);
            
            return sendFuture
                    .thenApply(result -> {
                        log.debug("✅ Successfully published audit event {} to topic {} partition {} offset {}", 
                                event.getEventId(), 
                                auditTopic,
                                result.getRecordMetadata().partition(),
                                result.getRecordMetadata().offset());
                        return null;
                    })
                    .exceptionally(throwable -> {
                        log.error("❌ Failed to publish audit event {} to topic {}: {}", 
                                event.getEventId(), auditTopic, throwable.getMessage(), throwable);
                        throw new EventPublicationException(
                                "Failed to publish audit event: " + throwable.getMessage(), throwable);
                    });
                    
        } catch (JsonProcessingException e) {
            log.error("❌ Failed to serialize audit event {} to JSON: {}", event.getEventId(), e.getMessage());
            CompletableFuture<Void> future = new CompletableFuture<>();
            future.completeExceptionally(new EventPublicationException(
                    "Failed to serialize audit event: " + e.getMessage(), e));
            return future;
        }
    }

    @Override
    public CompletableFuture<Void> publishApplicationLogEvent(String logLevel, String message, Map<String, Object> context) {
        log.debug("📤 Publishing application log event: {}", logLevel);

        try {
            // Create application log message
            KafkaApplicationLogMessage logMessage = createApplicationLogMessage(logLevel, message, context);
            String messageJson = objectMapper.writeValueAsString(logMessage);
            
            // Use log level as partition key for log aggregation
            String partitionKey = logLevel;
            String logTopic = "application-logs";
            
            CompletableFuture<SendResult<String, String>> sendFuture = 
                    kafkaTemplate.send(logTopic, partitionKey, messageJson);
            
            return sendFuture
                    .thenApply(result -> {
                        log.trace("✅ Successfully published log event to topic {} partition {} offset {}", 
                                logTopic,
                                result.getRecordMetadata().partition(),
                                result.getRecordMetadata().offset());
                        return null;
                    })
                    .exceptionally(throwable -> {
                        log.error("❌ Failed to publish log event to topic {}: {}", 
                                logTopic, throwable.getMessage(), throwable);
                        throw new EventPublicationException(
                                "Failed to publish application log event: " + throwable.getMessage(), throwable);
                    });
                    
        } catch (JsonProcessingException e) {
            log.error("❌ Failed to serialize log event to JSON: {}", e.getMessage());
            CompletableFuture<Void> future = new CompletableFuture<>();
            future.completeExceptionally(new EventPublicationException(
                    "Failed to serialize application log event: " + e.getMessage(), e));
            return future;
        }
    }

    // ==================== PRIVATE HELPER METHODS ====================

    private ObjectMapper createObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        return mapper;
    }

    private KafkaStockUpdateMessage createKafkaMessage(StockUpdateEvent event) {
        return KafkaStockUpdateMessage.builder()
                .eventId(event.getEventId())
                .eventType(event.getEventType().name())
                .productId(event.getProductId().getValue())
                .distributionCenter(event.getDistributionCenter().getCode())
                .branch(event.getBranch().getCode())
                .quantity(event.getQuantity().getValue())
                .operation(event.getOperation().getType())
                .correlationId(event.getCorrelationId().getValue())
                .reasonCode(event.getReasonCode() != null ? event.getReasonCode().getCode() : null)
                .referenceDocument(event.getReferenceDocument() != null ? event.getReferenceDocument().getValue() : null)
                .sourceBranch(event.getSourceBranch() != null ? event.getSourceBranch().getCode() : null)
                .timestamp(event.getTimestamp())
                .version(event.getVersion())
                .build();
    }

    private KafkaAuditMessage createAuditMessage(StockUpdateEvent event) {
        return KafkaAuditMessage.builder()
                .auditId(java.util.UUID.randomUUID().toString())
                .eventId(event.getEventId())
                .eventType("STOCK_UPDATE_AUDIT")
                .entityType("STOCK_UPDATE")
                .entityId(event.getProductId().getValue())
                .operation(event.getOperation().getType())
                .correlationId(event.getCorrelationId().getValue())
                .userId("system") // TODO: Get from security context
                .timestamp(event.getTimestamp())
                .details(createAuditDetails(event))
                .build();
    }

    private KafkaApplicationLogMessage createApplicationLogMessage(String logLevel, String message, Map<String, Object> context) {
        Map<String, Object> enhancedContext = new HashMap<>(context != null ? context : new HashMap<>());
        enhancedContext.put("service", "kbnt-log-service");
        enhancedContext.put("component", "stock-update");
        
        return KafkaApplicationLogMessage.builder()
                .logId(java.util.UUID.randomUUID().toString())
                .level(logLevel)
                .message(message)
                .service("kbnt-log-service")
                .component("stock-update")
                .timestamp(java.time.LocalDateTime.now())
                .context(enhancedContext)
                .build();
    }

    private Map<String, Object> createAuditDetails(StockUpdateEvent event) {
        Map<String, Object> details = new HashMap<>();
        details.put("productId", event.getProductId().getValue());
        details.put("distributionCenter", event.getDistributionCenter().getCode());
        details.put("branch", event.getBranch().getCode());
        details.put("quantity", event.getQuantity().getValue());
        details.put("operation", event.getOperation().getType());
        
        if (event.getReasonCode() != null) {
            details.put("reasonCode", event.getReasonCode().getCode());
        }
        if (event.getReferenceDocument() != null) {
            details.put("referenceDocument", event.getReferenceDocument().getValue());
        }
        if (event.getSourceBranch() != null) {
            details.put("sourceBranch", event.getSourceBranch().getCode());
        }
        
        return details;
    }

    /**
     * Exception thrown when event publication fails
     */
    public static class EventPublicationException extends RuntimeException {
        public EventPublicationException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
