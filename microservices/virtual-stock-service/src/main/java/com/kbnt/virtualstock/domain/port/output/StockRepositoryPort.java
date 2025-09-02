package com.kbnt.virtualstock.domain.port.output;

import com.kbnt.virtualstock.domain.model.Stock;

import java.util.List;
import java.util.Optional;

/**
 * Stock Repository Port - Output Port for Data Persistence
 * 
 * Domain interface for stock data operations.
 * Infrastructure adapters will implement this interface.
 */
public interface StockRepositoryPort {
    
    /**
     * Save or update stock
     */
    Stock save(Stock stock);
    
    /**
     * Find stock by ID
     */
    Optional<Stock> findById(Stock.StockId stockId);
    
    /**
     * Find stock by product ID
     */
    Optional<Stock> findByProductId(Stock.ProductId productId);
    
    /**
     * Find stock by symbol
     */
    Optional<Stock> findBySymbol(String symbol);
    
    /**
     * Find all stocks
     */
    List<Stock> findAll();
    
    /**
     * Find stocks by status
     */
    List<Stock> findByStatus(Stock.StockStatus status);
    
    /**
     * Find low stock items (quantity < threshold)
     */
    List<Stock> findLowStock(Integer threshold);
    
    /**
     * Delete stock by ID
     */
    void deleteById(Stock.StockId stockId);
    
    /**
     * Check if stock exists by product ID
     */
    boolean existsByProductId(Stock.ProductId productId);
    
    /**
     * Count total stocks
     */
    long count();
    
    /**
     * Count stocks by status
     */
    long countByStatus(Stock.StockStatus status);
}
