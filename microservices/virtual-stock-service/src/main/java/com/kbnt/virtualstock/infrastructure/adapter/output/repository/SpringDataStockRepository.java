package com.kbnt.virtualstock.infrastructure.adapter.output.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Spring Data JPA Repository for Stock entities
 * Provides database operations for stock persistence layer
 */
@Repository
public interface SpringDataStockRepository extends JpaRepository<StockEntity, Long> {
    
    /**
     * Find stock by business identifier
     */
    Optional<StockEntity> findByStockId(String stockId);
    
    /**
     * Find stock by product identifier
     */
    Optional<StockEntity> findByProductId(String productId);
    
    /**
     * Find stock by symbol
     */
    Optional<StockEntity> findBySymbol(String symbol);
    
    /**
     * Find stocks for multiple product identifiers
     */
    List<StockEntity> findByProductIdIn(List<String> productIds);
    
    /**
     * Find stocks by status
     */
    List<StockEntity> findByStatus(StockEntity.StockStatus status);
    
    /**
     * Find stocks with quantity less than or equal to threshold
     */
    List<StockEntity> findByQuantityLessThanEqual(Integer threshold);
    
    /**
     * Check if stock exists for product
     */
    boolean existsByProductId(String productId);
    
    /**
     * Count stocks by status
     */
    long countByStatus(StockEntity.StockStatus status);
    
    /**
     * Find all stocks with available quantity (quantity > 0)
     */
    @Query("SELECT s FROM StockEntity s WHERE s.quantity > 0")
    List<StockEntity> findAllWithAvailableStock();
    
    /**
     * Find stock by product ID that has available quantity
     */
    @Query("SELECT s FROM StockEntity s WHERE s.productId = :productId AND s.quantity > 0")
    Optional<StockEntity> findByProductIdWithAvailableStock(@Param("productId") String productId);
    
    /**
     * Count total products with stock
     */
    @Query("SELECT COUNT(DISTINCT s.productId) FROM StockEntity s WHERE s.quantity > 0")
    long countProductsWithStock();
}
