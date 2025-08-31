package com.kbnt.virtualstock.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

/**
 * Stock Updated Domain Event
 * 
 * Domain event published when stock is updated, following DDD principles.
 * This event will be translated to Kafka messages by infrastructure adapters.
 */
@Getter
@Builder
@ToString
@Getter
@Builder
@ToString
@AllArgsConstructor
@NoArgsConstructor
public class StockUpdatedEvent {
    
    private final String eventId;
    private final String correlationId;
    private final Stock.StockId stockId;
    private final Stock.ProductId productId;
    private final String symbol;
    private final String productName;
    private final Integer previousQuantity;
    private final Integer newQuantity;
    private final BigDecimal previousPrice;
    private final BigDecimal newPrice;
    private final Stock.StockStatus previousStatus;
    private final Stock.StockStatus newStatus;
    private final StockOperation operation;
    private final String operationBy;
    private final LocalDateTime occurredAt;
    private final String reason;
    
    /**
     * Stock Operation Types
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
     * Factory method to create quantity update event
     */
    public static StockUpdatedEvent forQuantityUpdate(
            Stock previousStock, Stock updatedStock, String operationBy, String reason) {
        return StockUpdatedEvent.builder()
                .eventId(java.util.UUID.randomUUID().toString())
                .correlationId(java.util.UUID.randomUUID().toString())
                .stockId(updatedStock.getStockId())
                .productId(updatedStock.getProductId())
                .symbol(updatedStock.getSymbol())
                .productName(updatedStock.getProductName())
                .previousQuantity(previousStock != null ? previousStock.getQuantity() : 0)
                .newQuantity(updatedStock.getQuantity())
                .previousPrice(previousStock != null ? previousStock.getUnitPrice() : updatedStock.getUnitPrice())
                .newPrice(updatedStock.getUnitPrice())
                .previousStatus(previousStock != null ? previousStock.getStatus() : Stock.StockStatus.OUT_OF_STOCK)
                .newStatus(updatedStock.getStatus())
                .operation(StockOperation.QUANTITY_UPDATE)
                .operationBy(operationBy)
                .occurredAt(LocalDateTime.now())
                .reason(reason)
                .build();
    }
    
    /**
     * Factory method to create price update event
     */
    public static StockUpdatedEvent forPriceUpdate(
            Stock previousStock, Stock updatedStock, String operationBy, String reason) {
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
     * Factory method to create reservation event
     */
    public static StockUpdatedEvent forReservation(
            Stock previousStock, Stock updatedStock, String operationBy, String reason) {
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
     * Factory method to create initial stock creation event
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
     * Check if this event represents a significant change
     */
    public boolean isSignificantChange() {
        return operation == StockOperation.INITIAL_CREATION ||
               operation == StockOperation.STOCK_RESERVATION ||
               (operation == StockOperation.QUANTITY_UPDATE && 
                Math.abs(newQuantity - previousQuantity) >= 10) ||
               (operation == StockOperation.PRICE_UPDATE && 
                newPrice.subtract(previousPrice).abs().compareTo(new BigDecimal("10")) >= 0);
    }
    
    /**
     * Get quantitative change
     */
    public Integer getQuantityChange() {
        return newQuantity - previousQuantity;
    }
    
    /**
     * Get price change
     */
    public BigDecimal getPriceChange() {
        return newPrice.subtract(previousPrice);
    }
}
