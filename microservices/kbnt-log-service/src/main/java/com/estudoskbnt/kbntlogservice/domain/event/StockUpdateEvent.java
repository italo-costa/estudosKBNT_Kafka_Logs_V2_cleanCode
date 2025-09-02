package com.estudoskbnt.kbntlogservice.domain.event;

import com.estudoskbnt.kbntlogservice.domain.model.*;

import java.time.LocalDateTime;

/**
 * Stock Update Event - Domain Event
 * 
 * Represents a business event that occurred in the stock update domain.
 * Used for event-driven communication between microservices.
 * 
 * Located in domain.event package following Hexagonal Architecture
 */
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

  // Constructors
  public StockUpdateEvent() {
  }

  public StockUpdateEvent(String eventId, StockUpdateId stockUpdateId, ProductId productId,
                         DistributionCenter distributionCenter, Branch branch, Quantity quantity,
                         Operation operation, LocalDateTime timestamp, CorrelationId correlationId,
                         EventType eventType, Priority priority) {
    this.eventId = eventId;
    this.stockUpdateId = stockUpdateId;
    this.productId = productId;
    this.distributionCenter = distributionCenter;
    this.branch = branch;
    this.quantity = quantity;
    this.operation = operation;
    this.timestamp = timestamp;
    this.correlationId = correlationId;
    this.eventType = eventType;
    this.priority = priority;
  }

  // Getters
  public String getEventId() { return eventId; }
  public StockUpdateId getStockUpdateId() { return stockUpdateId; }
  public ProductId getProductId() { return productId; }
  public DistributionCenter getDistributionCenter() { return distributionCenter; }
  public Branch getBranch() { return branch; }
  public Quantity getQuantity() { return quantity; }
  public Operation getOperation() { return operation; }
  public LocalDateTime getTimestamp() { return timestamp; }
  public CorrelationId getCorrelationId() { return correlationId; }
  public EventType getEventType() { return eventType; }
  public Priority getPriority() { return priority; }
    
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
            .correlationId(correlationId)
            .build();
  }
}
