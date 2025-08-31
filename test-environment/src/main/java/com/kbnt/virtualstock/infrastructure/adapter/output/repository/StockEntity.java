package com.kbnt.virtualstock.infrastructure.adapter.output.repository;

import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Stock JPA Entity
 * Persistence layer representation of Stock aggregate
 */
@Entity
@Table(name = "stocks")
@Data
@NoArgsConstructor
public class StockEntity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "stock_id", unique = true, nullable = false)
    private String stockId;
    
    @Column(name = "product_id", nullable = false)
    private String productId;
    
    @Column(name = "quantity", precision = 19, scale = 2, nullable = false)
    private BigDecimal quantity = BigDecimal.ZERO;
    
    @Column(name = "reserved_quantity", precision = 19, scale = 2, nullable = false)
    private BigDecimal reservedQuantity = BigDecimal.ZERO;
    
    @Column(name = "last_updated", nullable = false)
    private LocalDateTime lastUpdated;
    
    @Version
    @Column(name = "version")
    private Integer version;
    
    @PrePersist
    @PreUpdate
    protected void onSave() {
        if (lastUpdated == null) {
            lastUpdated = LocalDateTime.now();
        }
    }
}
