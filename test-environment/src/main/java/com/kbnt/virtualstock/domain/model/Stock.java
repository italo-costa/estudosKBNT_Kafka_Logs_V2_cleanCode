package com.kbnt.virtualstock.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Stock Aggregate Root - Test Environment
 * Simplified version for testing Lombok compilation
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Stock {
    
    private String stockId;
    private String productId;
    private BigDecimal quantity;
    private BigDecimal reservedQuantity;
    private LocalDateTime lastUpdated;
    private Integer version;
    
    // Business methods
    public void updateQuantity(BigDecimal newQuantity) {
        this.quantity = newQuantity;
        this.lastUpdated = LocalDateTime.now();
    }
    
    public void reserveQuantity(BigDecimal amount) {
        if (amount.compareTo(getAvailableQuantity()) > 0) {
            throw new IllegalStateException("Insufficient stock available");
        }
        this.reservedQuantity = this.reservedQuantity.add(amount);
        this.lastUpdated = LocalDateTime.now();
    }
    
    public BigDecimal getAvailableQuantity() {
        return quantity.subtract(reservedQuantity);
    }
    
    // Equals and HashCode based on business key
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Stock stock = (Stock) o;
        return Objects.equals(stockId, stock.stockId);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(stockId);
    }
}
