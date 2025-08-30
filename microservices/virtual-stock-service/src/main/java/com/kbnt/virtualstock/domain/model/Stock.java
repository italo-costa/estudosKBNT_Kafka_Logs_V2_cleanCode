package com.kbnt.virtualstock.domain.model;

import lombok.Builder;
import lombok.Getter;
import lombok.ToString;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Stock Domain Entity - Core business domain model
 * 
 * Represents a stock item in the virtual stock management system.
 * This is the central aggregate root for stock operations.
 */
@Getter
@Builder
@ToString
public class Stock {
    
    private final StockId stockId;
    private final ProductId productId;
    private final String symbol;
    private final String productName;
    private final Integer quantity;
    private final BigDecimal unitPrice;
    private final StockStatus status;
    private final LocalDateTime lastUpdated;
    private final String lastUpdatedBy;
    
    /**
     * Stock Value Object - Unique identifier
     */
    @Getter
    @Builder
    @ToString
    public static class StockId {
        private final String value;
        
        public static StockId generate() {
            return StockId.builder()
                    .value(java.util.UUID.randomUUID().toString())
                    .build();
        }
        
        @Override
        public boolean equals(Object obj) {
            if (this == obj) return true;
            if (obj == null || getClass() != obj.getClass()) return false;
            StockId stockId = (StockId) obj;
            return Objects.equals(value, stockId.value);
        }
        
        @Override
        public int hashCode() {
            return Objects.hash(value);
        }
    }
    
    /**
     * Product Value Object - Product identifier
     */
    @Getter
    @Builder
    @ToString
    public static class ProductId {
        private final String value;
        
        public static ProductId of(String productId) {
            return ProductId.builder()
                    .value(productId)
                    .build();
        }
        
        @Override
        public boolean equals(Object obj) {
            if (this == obj) return true;
            if (obj == null || getClass() != obj.getClass()) return false;
            ProductId productId = (ProductId) obj;
            return Objects.equals(value, productId.value);
        }
        
        @Override
        public int hashCode() {
            return Objects.hash(value);
        }
    }
    
    /**
     * Stock Status Enumeration
     */
    public enum StockStatus {
        AVAILABLE,
        RESERVED,
        OUT_OF_STOCK,
        DISCONTINUED,
        PENDING_RESTOCK
    }
    
    /**
     * Business method to update stock quantity
     */
    public Stock updateQuantity(Integer newQuantity, String updatedBy) {
        validateQuantity(newQuantity);
        
        StockStatus newStatus = determineStatusByQuantity(newQuantity);
        
        return Stock.builder()
                .stockId(this.stockId)
                .productId(this.productId)
                .symbol(this.symbol)
                .productName(this.productName)
                .quantity(newQuantity)
                .unitPrice(this.unitPrice)
                .status(newStatus)
                .lastUpdated(LocalDateTime.now())
                .lastUpdatedBy(updatedBy)
                .build();
    }
    
    /**
     * Business method to update stock price
     */
    public Stock updatePrice(BigDecimal newPrice, String updatedBy) {
        validatePrice(newPrice);
        
        return Stock.builder()
                .stockId(this.stockId)
                .productId(this.productId)
                .symbol(this.symbol)
                .productName(this.productName)
                .quantity(this.quantity)
                .unitPrice(newPrice)
                .status(this.status)
                .lastUpdated(LocalDateTime.now())
                .lastUpdatedBy(updatedBy)
                .build();
    }
    
    /**
     * Business method to reserve stock
     */
    public Stock reserve(Integer quantityToReserve, String reservedBy) {
        if (!canReserve(quantityToReserve)) {
            throw new IllegalArgumentException("Cannot reserve " + quantityToReserve + 
                    " units. Available: " + this.quantity);
        }
        
        Integer remainingQuantity = this.quantity - quantityToReserve;
        StockStatus newStatus = remainingQuantity == 0 ? StockStatus.OUT_OF_STOCK : 
                                remainingQuantity < 10 ? StockStatus.PENDING_RESTOCK : 
                                StockStatus.AVAILABLE;
        
        return Stock.builder()
                .stockId(this.stockId)
                .productId(this.productId)
                .symbol(this.symbol)
                .productName(this.productName)
                .quantity(remainingQuantity)
                .unitPrice(this.unitPrice)
                .status(newStatus)
                .lastUpdated(LocalDateTime.now())
                .lastUpdatedBy(reservedBy)
                .build();
    }
    
    /**
     * Business rule validation
     */
    public boolean canReserve(Integer quantityToReserve) {
        return this.status == StockStatus.AVAILABLE && 
               this.quantity >= quantityToReserve &&
               quantityToReserve > 0;
    }
    
    /**
     * Calculate total value of stock
     */
    public BigDecimal getTotalValue() {
        return this.unitPrice.multiply(BigDecimal.valueOf(this.quantity));
    }
    
    /**
     * Business rule - is stock low?
     */
    public boolean isLowStock() {
        return this.quantity != null && this.quantity < 10;
    }
    
    /**
     * Business rule - is stock available?
     */
    public boolean isAvailable() {
        return this.status == StockStatus.AVAILABLE && this.quantity > 0;
    }
    
    private void validateQuantity(Integer quantity) {
        if (quantity == null || quantity < 0) {
            throw new IllegalArgumentException("Quantity must be non-negative");
        }
    }
    
    private void validatePrice(BigDecimal price) {
        if (price == null || price.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Price must be non-negative");
        }
    }
    
    private StockStatus determineStatusByQuantity(Integer quantity) {
        if (quantity == 0) {
            return StockStatus.OUT_OF_STOCK;
        } else if (quantity < 10) {
            return StockStatus.PENDING_RESTOCK;
        } else {
            return StockStatus.AVAILABLE;
        }
    }
}
