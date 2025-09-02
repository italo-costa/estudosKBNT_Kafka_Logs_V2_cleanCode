package com.kbnt.virtualstock.infrastructure.adapter.output.repository;

import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Stock JPA Entity
 * Persistence layer representation of Stock aggregate
 * Maps to the rich domain model with full business logic
 */
@Entity
@Table(name = "stocks", indexes = {
    @Index(name = "idx_stock_id", columnList = "stock_id"),
    @Index(name = "idx_product_id", columnList = "product_id"),
    @Index(name = "idx_status", columnList = "status")
})
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
    
    @Column(name = "symbol", length = 50)
    private String symbol;
    
    @Column(name = "product_name", nullable = false)
    private String productName;
    
    @Column(name = "quantity", nullable = false)
    private Integer quantity = 0;
    
    @Column(name = "unit_price", precision = 19, scale = 2)
    private BigDecimal unitPrice = BigDecimal.ZERO;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private StockStatus status = StockStatus.AVAILABLE;
    
    @Column(name = "last_updated", nullable = false)
    private LocalDateTime lastUpdated;
    
    @Column(name = "last_updated_by")
    private String lastUpdatedBy;
    
    @Version
    @Column(name = "version")
    private Integer version;
    
    /**
     * Stock Status enumeration matching domain model
     */
    public enum StockStatus {
        AVAILABLE,
        RESERVED,
        OUT_OF_STOCK,
        DISCONTINUED,
        PENDING_RESTOCK
    }
    
    @PrePersist
    @PreUpdate
    protected void onSave() {
        if (lastUpdated == null) {
            lastUpdated = LocalDateTime.now();
        }
        
        // Auto-set status based on quantity if not manually set
        if (status == StockStatus.AVAILABLE && quantity <= 0) {
            status = StockStatus.OUT_OF_STOCK;
        }
    }
}
