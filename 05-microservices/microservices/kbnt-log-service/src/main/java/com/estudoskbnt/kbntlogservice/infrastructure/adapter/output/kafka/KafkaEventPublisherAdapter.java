package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka;

import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;
import com.estudoskbnt.kbntlogservice.domain.port.output.EventPublisherPort;
import com.estudoskbnt.kbntlogservice.domain.port.output.EventPublicationResult;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * Kafka Event Publisher Adapter
 */
@Component
@RequiredArgsConstructor
public class KafkaEventPublisherAdapter implements EventPublisherPort {

    private static final Logger log = LoggerFactory.getLogger(KafkaEventPublisherAdapter.class);
    private final KafkaTemplate<String, String> kafkaTemplate;

    @Override
    public CompletableFuture<EventPublicationResult> publishEvent(StockUpdateEvent event) {
        log.debug("📤 Publishing stock update event for product {}", event.getProductId().getValue());

        try {
            ObjectMapper mapper = new ObjectMapper();
            mapper.registerModule(new JavaTimeModule());
            
            Map<String, Object> message = new HashMap<>();
            message.put("eventId", event.getEventId());
            message.put("productId", event.getProductId().getValue());
            message.put("distributionCenter", event.getDistributionCenter().getCode());
            message.put("branch", event.getBranch().getCode());
            message.put("quantity", event.getQuantity().getValue());
            message.put("operation", event.getOperation().getType());
            message.put("correlationId", event.getCorrelationId().getValue());
            message.put("timestamp", event.getTimestamp());
            
            String messageJson = mapper.writeValueAsString(message);
            String partitionKey = event.getProductId().getValue();
            String topic = "kbnt-stock-updates";
            
            CompletableFuture<SendResult<String, String>> sendFuture = 
                    kafkaTemplate.send(topic, partitionKey, messageJson);
            
            return sendFuture
                    .thenApply(result -> {
                        String messageId = result.getRecordMetadata().toString();
                        String partition = String.valueOf(result.getRecordMetadata().partition());
                        Long offset = result.getRecordMetadata().offset();
                        
                        log.info("✅ Successfully published event to topic {} partition {} offset {}", 
                               topic, partition, offset);
                        return EventPublicationResult.success(messageId, topic, partition, offset);
                    })
                    .exceptionally(throwable -> {
                        log.error("❌ Failed to publish event: {}", throwable.getMessage());
                        Exception ex = (throwable instanceof Exception) ? (Exception) throwable : new Exception(throwable);
                        return EventPublicationResult.failure(throwable.getMessage(), ex);
                    });
                    
        } catch (JsonProcessingException e) {
            log.error("❌ Failed to serialize event: {}", e.getMessage());
            return CompletableFuture.completedFuture(
                    EventPublicationResult.failure("Event serialization failed: " + e.getMessage(), e));
        }
    }

    @Override
    public CompletableFuture<EventPublicationResult> publishEvent(StockUpdateEvent event, String topic) {
        return publishEvent(event); // Simplified implementation
    }

    @Override
    public CompletableFuture<EventPublicationResult> publishHighPriorityEvent(StockUpdateEvent event) {
        return publishEvent(event); // Simplified implementation
    }
}
