package com.kbnt.virtualstock.infrastructure.adapter.output.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Spring Data JPA Repository for Stock entities
 */
@Repository
public interface SpringDataStockRepository extends JpaRepository<StockEntity, Long> {
    
    Optional<StockEntity> findByStockId(String stockId);
    
    Optional<StockEntity> findByProductId(String productId);
    
    List<StockEntity> findByProductIdIn(List<String> productIds);
    
    boolean existsByProductId(String productId);
    
    @Query("SELECT s FROM StockEntity s WHERE s.quantity > s.reservedQuantity")
    List<StockEntity> findAllWithAvailableStock();
    
    @Query("SELECT s FROM StockEntity s WHERE s.productId = :productId AND s.quantity > s.reservedQuantity")
    Optional<StockEntity> findByProductIdWithAvailableStock(@Param("productId") String productId);
}
