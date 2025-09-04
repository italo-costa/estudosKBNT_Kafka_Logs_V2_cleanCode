package com.kbnt.virtualstock.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

/**
 * Stock Updated Domain Event.
 * 
 * <p>
 * Domain event published when stock is updated, following DDD principles.
 * This event will be translated to Kafka messages by infrastructure adapters.
 */
public class StockUpdatedEvent {
  public static Builder builder() { 
    return new Builder(); 
  }

  /**
   * Builder for StockUpdatedEvent.
   */
  public static class Builder {
    private String eventId;
    private String correlationId;
    private Stock.StockId stockId;
    private Stock.ProductId productId;
    private String symbol;
    private String productName;
    private Integer previousQuantity;
    private Integer newQuantity;
    private BigDecimal previousPrice;
    private BigDecimal newPrice;
    private Stock.StockStatus previousStatus;
    private Stock.StockStatus newStatus;
    private StockOperation operation;
    private String operationBy;
    private LocalDateTime occurredAt;
    private String reason;

    public Builder eventId(String eventId) { 
      this.eventId = eventId; 
      return this; 
    }

    public Builder correlationId(String correlationId) { 
      this.correlationId = correlationId; 
      return this; 
    }

    public Builder stockId(Stock.StockId stockId) { 
      this.stockId = stockId; 
      return this; 
    }

    public Builder productId(Stock.ProductId productId) { 
      this.productId = productId; 
      return this; 
    }

    public Builder symbol(String symbol) { 
      this.symbol = symbol; 
      return this; 
    }

    public Builder productName(String productName) { 
      this.productName = productName; 
      return this; 
    }

    public Builder previousQuantity(Integer previousQuantity) { 
      this.previousQuantity = previousQuantity; 
      return this; 
    }

    public Builder newQuantity(Integer newQuantity) { 
      this.newQuantity = newQuantity; 
      return this; 
    }

    public Builder previousPrice(BigDecimal previousPrice) { 
      this.previousPrice = previousPrice; 
      return this; 
    }

    public Builder newPrice(BigDecimal newPrice) { 
      this.newPrice = newPrice; 
      return this; 
    }

    public Builder previousStatus(Stock.StockStatus previousStatus) { 
      this.previousStatus = previousStatus; 
      return this; 
    }

    public Builder newStatus(Stock.StockStatus newStatus) { 
      this.newStatus = newStatus; 
      return this; 
    }

    public Builder operation(StockOperation operation) { 
      this.operation = operation; 
      return this; 
    }

    public Builder operationBy(String operationBy) { 
      this.operationBy = operationBy; 
      return this; 
    }

    public Builder occurredAt(LocalDateTime occurredAt) { 
      this.occurredAt = occurredAt; 
      return this; 
    }

    public Builder reason(String reason) { 
      this.reason = reason; 
      return this; 
    }

    public StockUpdatedEvent build() {
      return new StockUpdatedEvent(eventId, correlationId, stockId, productId, symbol, 
          productName, previousQuantity, newQuantity, previousPrice, newPrice, 
          previousStatus, newStatus, operation, operationBy, occurredAt, reason);
    }
  }
  private String eventId;
  private String correlationId;
  private Stock.StockId stockId;
  private Stock.ProductId productId;
  private String symbol;
  private String productName;
  private Integer previousQuantity;
  private Integer newQuantity;
  private BigDecimal previousPrice;
  private BigDecimal newPrice;
  private Stock.StockStatus previousStatus;
  private Stock.StockStatus newStatus;
  private StockOperation operation;
  private String operationBy;
  private LocalDateTime occurredAt;
  private String reason;

  public StockUpdatedEvent() {
    this.eventId = java.util.UUID.randomUUID().toString();
  }

  /**
   * Constructor for StockUpdatedEvent.
   */
  public StockUpdatedEvent(String eventId, String correlationId, Stock.StockId stockId, 
      Stock.ProductId productId, String symbol, String productName, Integer previousQuantity, 
      Integer newQuantity, BigDecimal previousPrice, BigDecimal newPrice, 
      Stock.StockStatus previousStatus, Stock.StockStatus newStatus, StockOperation operation, 
      String operationBy, LocalDateTime occurredAt, String reason) {
    this.eventId = eventId != null ? eventId : java.util.UUID.randomUUID().toString();
    this.correlationId = correlationId;
    this.stockId = stockId;
    this.productId = productId;
    this.symbol = symbol;
    this.productName = productName;
    this.previousQuantity = previousQuantity;
    this.newQuantity = newQuantity;
    this.previousPrice = previousPrice;
    this.newPrice = newPrice;
    this.previousStatus = previousStatus;
    this.newStatus = newStatus;
    this.operation = operation;
    this.operationBy = operationBy;
    this.occurredAt = occurredAt;
    this.reason = reason;
  }

  // Getters and setters for all fields
  public String getEventId() { 
    return eventId; 
  }

  public void setEventId(String eventId) { 
    this.eventId = eventId; 
  }

  public String getCorrelationId() { 
    return correlationId; 
  }

  public void setCorrelationId(String correlationId) { 
    this.correlationId = correlationId; 
  }

  public Stock.StockId getStockId() { 
    return stockId; 
  }

  public void setStockId(Stock.StockId stockId) { 
    this.stockId = stockId; 
  }

  public Stock.ProductId getProductId() { 
    return productId; 
  }

  public void setProductId(Stock.ProductId productId) { 
    this.productId = productId; 
  }

  public String getSymbol() { 
    return symbol; 
  }

  public void setSymbol(String symbol) { 
    this.symbol = symbol; 
  }

  public String getProductName() { 
    return productName; 
  }

  public void setProductName(String productName) { 
    this.productName = productName; 
  }

  public Integer getPreviousQuantity() { 
    return previousQuantity; 
  }

  public void setPreviousQuantity(Integer previousQuantity) { 
    this.previousQuantity = previousQuantity; 
  }

  public Integer getNewQuantity() { 
    return newQuantity; 
  }

  public void setNewQuantity(Integer newQuantity) { 
    this.newQuantity = newQuantity; 
  }

  public BigDecimal getPreviousPrice() { 
    return previousPrice; 
  }

  public void setPreviousPrice(BigDecimal previousPrice) { 
    this.previousPrice = previousPrice; 
  }

  public BigDecimal getNewPrice() { 
    return newPrice; 
  }

  public void setNewPrice(BigDecimal newPrice) { 
    this.newPrice = newPrice; 
  }

  public Stock.StockStatus getPreviousStatus() { 
    return previousStatus; 
  }

  public void setPreviousStatus(Stock.StockStatus previousStatus) { 
    this.previousStatus = previousStatus; 
  }

  public Stock.StockStatus getNewStatus() { 
    return newStatus; 
  }

  public void setNewStatus(Stock.StockStatus newStatus) { 
    this.newStatus = newStatus; 
  }

  public StockOperation getOperation() { 
    return operation; 
  }

  public void setOperation(StockOperation operation) { 
    this.operation = operation; 
  }

  public String getOperationBy() { 
    return operationBy; 
  }

  public void setOperationBy(String operationBy) { 
    this.operationBy = operationBy; 
  }

  public LocalDateTime getOccurredAt() { 
    return occurredAt; 
  }

  public void setOccurredAt(LocalDateTime occurredAt) { 
    this.occurredAt = occurredAt; 
  }

  public String getReason() { 
    return reason; 
  }

  public void setReason(String reason) { 
    this.reason = reason; 
  }

  /**
   * Stock Operation Types.
   * 
   * <p>Enum representing different types of stock operations.</p>
   */
  public enum StockOperation {
    QUANTITY_UPDATE("Quantity Updated"),
    PRICE_UPDATE("Price Updated"),
    STOCK_RESERVATION("Stock Reserved"),
    STOCK_REPLENISHMENT("Stock Replenished"),
    STATUS_CHANGE("Status Changed"),
    INITIAL_CREATION("Stock Created");

    private final String description;

    StockOperation(String description) {
      this.description = description;
    }

    public String getDescription() {
      return description;
    }
  }
    
  /**
   * Factory method to create quantity update event.
   * 
   * <p>Creates an event when stock quantity is updated.</p>
   */
  public static StockUpdatedEvent forQuantityUpdate(Stock previousStock, Stock updatedStock, 
      String operationBy, String reason) {
    return StockUpdatedEvent.builder()
        .eventId(java.util.UUID.randomUUID().toString())
        .correlationId(java.util.UUID.randomUUID().toString())
        .stockId(updatedStock.getStockId())
        .productId(updatedStock.getProductId())
        .symbol(updatedStock.getSymbol())
        .productName(updatedStock.getProductName())
        .previousQuantity(previousStock != null ? previousStock.getQuantity() : 0)
        .newQuantity(updatedStock.getQuantity())
        .previousPrice(previousStock != null ? previousStock.getUnitPrice() 
            : updatedStock.getUnitPrice())
        .newPrice(updatedStock.getUnitPrice())
        .previousStatus(previousStock != null ? previousStock.getStatus() 
            : Stock.StockStatus.OUT_OF_STOCK)
        .newStatus(updatedStock.getStatus())
        .operation(StockOperation.QUANTITY_UPDATE)
        .operationBy(operationBy)
        .occurredAt(LocalDateTime.now())
        .reason(reason)
        .build();
  }

  /**
   * Factory method to create price update event.
   * 
   * <p>Creates an event when stock price is updated.</p>
   */
  public static StockUpdatedEvent forPriceUpdate(Stock previousStock, Stock updatedStock, 
      String operationBy, String reason) {
    return StockUpdatedEvent.builder()
        .eventId(java.util.UUID.randomUUID().toString())
        .correlationId(java.util.UUID.randomUUID().toString())
        .stockId(updatedStock.getStockId())
        .productId(updatedStock.getProductId())
        .symbol(updatedStock.getSymbol())
        .productName(updatedStock.getProductName())
        .previousQuantity(updatedStock.getQuantity())
        .newQuantity(updatedStock.getQuantity())
        .previousPrice(previousStock != null ? previousStock.getUnitPrice() : BigDecimal.ZERO)
        .newPrice(updatedStock.getUnitPrice())
        .previousStatus(updatedStock.getStatus())
        .newStatus(updatedStock.getStatus())
        .operation(StockOperation.PRICE_UPDATE)
        .operationBy(operationBy)
        .occurredAt(LocalDateTime.now())
        .reason(reason)
        .build();
  }
  
  /**
   * Factory method to create reservation event.
   * 
   * <p>Creates an event when stock is reserved.</p>
   */
  public static StockUpdatedEvent forReservation(Stock previousStock, Stock updatedStock, 
      String operationBy, String reason) {
    return StockUpdatedEvent.builder()
        .eventId(java.util.UUID.randomUUID().toString())
        .correlationId(java.util.UUID.randomUUID().toString())
        .stockId(updatedStock.getStockId())
        .productId(updatedStock.getProductId())
        .symbol(updatedStock.getSymbol())
        .productName(updatedStock.getProductName())
        .previousQuantity(previousStock.getQuantity())
        .newQuantity(updatedStock.getQuantity())
        .previousPrice(updatedStock.getUnitPrice())
        .newPrice(updatedStock.getUnitPrice())
        .previousStatus(previousStock.getStatus())
        .newStatus(updatedStock.getStatus())
        .operation(StockOperation.STOCK_RESERVATION)
        .operationBy(operationBy)
        .occurredAt(LocalDateTime.now())
        .reason(reason)
        .build();
  }
  
  /**
   * Factory method to create initial stock creation event.
   * 
   * <p>Creates an event when stock is initially created.</p>
   */
  public static StockUpdatedEvent forCreation(Stock stock, String operationBy) {
    return StockUpdatedEvent.builder()
        .eventId(java.util.UUID.randomUUID().toString())
        .correlationId(java.util.UUID.randomUUID().toString())
        .stockId(stock.getStockId())
        .productId(stock.getProductId())
        .symbol(stock.getSymbol())
        .productName(stock.getProductName())
        .previousQuantity(0)
        .newQuantity(stock.getQuantity())
        .previousPrice(BigDecimal.ZERO)
        .newPrice(stock.getUnitPrice())
        .previousStatus(Stock.StockStatus.OUT_OF_STOCK)
        .newStatus(stock.getStatus())
        .operation(StockOperation.INITIAL_CREATION)
        .operationBy(operationBy)
        .occurredAt(LocalDateTime.now())
        .reason("Initial stock creation")
        .build();
  }
  
  /**
   * Check if this event represents a significant change.
   * 
   * <p>Determines if the event represents a significant change worth noting.</p>
   */
  public boolean isSignificantChange() {
    return operation == StockOperation.INITIAL_CREATION
        || operation == StockOperation.STOCK_RESERVATION
        || (operation == StockOperation.QUANTITY_UPDATE 
            && Math.abs(newQuantity - previousQuantity) >= 10)
        || (operation == StockOperation.PRICE_UPDATE 
            && newPrice.subtract(previousPrice).abs().compareTo(new BigDecimal("10")) >= 0);
  }

  /**
   * Get quantitative change.
   * 
   * <p>Returns the difference between new and previous quantity.</p>
   */
  public Integer getQuantityChange() {
    return newQuantity - previousQuantity;
  }

  /**
   * Get price change.
   * 
   * <p>Returns the difference between new and previous price.</p>
   */
  public BigDecimal getPriceChange() {
    return newPrice.subtract(previousPrice);
  }
}
