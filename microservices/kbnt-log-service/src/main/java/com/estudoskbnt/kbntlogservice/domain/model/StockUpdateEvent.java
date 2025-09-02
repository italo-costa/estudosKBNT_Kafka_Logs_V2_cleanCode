package com.estudoskbnt.kbntlogservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Stock Update Event - Domain Event
 * 
 * Represents a business event that occurred in the stock update domain.
 * Used for event-driven communication between microservices.
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdateEvent {
    
    private String eventId;
    private StockUpdateId stockUpdateId;
    private ProductId productId;
    private DistributionCenter distributionCenter;
    private Branch branch;
    private Quantity quantity;
    private Operation operation;
    private LocalDateTime timestamp;
    private CorrelationId correlationId;
    private EventType eventType;
    private Priority priority;
    
    /**
     * Get event topic based on operation type
     */
    public String getTargetTopic() {
        return switch (operation.getType()) {
            case "ADD", "REMOVE", "SET" -> "inventory-events";
            case "TRANSFER" -> "inventory-transfer-events";
            case "RESERVE", "RELEASE" -> "inventory-reservation-events";
            default -> "kbnt-stock-updates";
        };
    }
    
    /**
     * Get partition key for event distribution
     */
    public String getPartitionKey() {
        return productId.getValue() + "-" + distributionCenter.getCode();
    }
    
    /**
     * Check if this is a high-priority event
     */
    public boolean isHighPriority() {
        return priority == Priority.HIGH;
    }
    
    /**
     * Get event metadata for tracking
     */
    public EventMetadata getMetadata() {
        return EventMetadata.builder()
                .eventId(eventId)
                .timestamp(timestamp)
                .correlationId(correlationId.getValue())
                .eventType(eventType.name())
                .priority(priority.name())
                .build();
    }
}

/**
 * Event Type Enumeration
 */
enum EventType {
    STOCK_INCREASED,
    STOCK_DECREASED,
    STOCK_ADJUSTED,
    STOCK_TRANSFERRED,
    STOCK_RESERVED,
    STOCK_RELEASED,
    STOCK_UPDATED
}

/**
 * Priority Enumeration
 */
enum Priority {
    LOW,
    NORMAL,
    HIGH,
    CRITICAL
}

/**
 * Event Metadata Value Object
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
class EventMetadata {
    private String eventId;
    private LocalDateTime timestamp;
    private String correlationId;
    private String eventType;
    private String priority;
}
