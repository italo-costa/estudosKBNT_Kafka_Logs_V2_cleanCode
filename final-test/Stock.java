package com.kbnt.virtualstock.domain.model;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Stock Domain Aggregate - Rich Domain Model
 */
@Getter
@Builder(toBuilder = true)
@ToString
@AllArgsConstructor
@NoArgsConstructor
public class Stock {
    
    private StockId stockId;
    private ProductId productId;
    private String symbol;
    private String productName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private StockStatus status;
    private LocalDateTime lastUpdated;
    private String lastUpdatedBy;
    
    /**
     * Stock Value Object - Unique identifier
     */
    @Getter
    @Builder
    @ToString
    @AllArgsConstructor
    @NoArgsConstructor
    @EqualsAndHashCode
    public static class StockId {
        private String value;
        
        public static StockId generate() {
            return StockId.builder()
                    .value(java.util.UUID.randomUUID().toString())
                    .build();
        }
        
        public static StockId of(String value) {
            return StockId.builder()
                    .value(value)
                    .build();
        }
    }
    
    /**
     * Product Value Object - Product identifier
     */
    @Getter
    @Builder
    @ToString
    @AllArgsConstructor
    @NoArgsConstructor
    @EqualsAndHashCode
    public static class ProductId {
        private String value;
        
        public static ProductId of(String productId) {
            return ProductId.builder()
                    .value(productId)
                    .build();
        }
    }
    
    // Business methods
    public Stock updateQuantity(Integer newQuantity, String reason, String updatedBy) {
        return this.toBuilder()
                .quantity(newQuantity)
                .lastUpdated(LocalDateTime.now())
                .lastUpdatedBy(updatedBy)
                .build();
    }
    
    public Stock updatePrice(BigDecimal newPrice, String reason, String updatedBy) {
        return this.toBuilder()
                .unitPrice(newPrice)
                .lastUpdated(LocalDateTime.now())
                .lastUpdatedBy(updatedBy)
                .build();
    }
    
    public Stock reserve(Integer quantityToReserve, String reason, String reservedBy) {
        return this.toBuilder()
                .quantity(this.quantity - quantityToReserve)
                .lastUpdated(LocalDateTime.now())
                .lastUpdatedBy(reservedBy)
                .build();
    }
}

enum StockStatus {
    ACTIVE, INACTIVE, RESERVED, LOW_STOCK
}
