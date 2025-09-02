package com.kbnt.virtualstock.domain.port.output;

import com.kbnt.virtualstock.domain.model.Stock;

import java.util.List;
import java.util.Optional;

/**
 * Output Port for Stock Repository operations
 * Defines the contract for stock persistence in hexagonal architecture
 */
public interface StockRepositoryPort {
    
    /**
     * Find stock by unique stock identifier
     */
    Optional<Stock> findByStockId(String stockId);
    
    /**
     * Find stock by product identifier
     */
    Optional<Stock> findByProductId(String productId);
    
    /**
     * Find stocks for multiple product identifiers
     */
    List<Stock> findByProductIdIn(List<String> productIds);
    
    /**
     * Find all stocks
     */
    List<Stock> findAll();
    
    /**
     * Save or update stock
     */
    Stock save(Stock stock);
    
    /**
     * Delete stock by identifier
     */
    void delete(String stockId);
    
    /**
     * Check if stock exists for product
     */
    boolean existsByProductId(String productId);
}
