package com.estudoskbnt.kbntlogservice.domain.port.output;

import com.estudoskbnt.kbntlogservice.domain.model.StockUpdate;
import com.estudoskbnt.kbntlogservice.domain.model.StockUpdateId;
import com.estudoskbnt.kbntlogservice.domain.model.ProductId;

import java.util.Optional;
import java.util.concurrent.CompletableFuture;

/**
 * Stock Update Repository Port - Output Port
 * 
 * Defines persistence operations for stock updates.
 * Infrastructure adapters will implement this interface.
 */
public interface StockUpdateRepositoryPort {
    
    /**
     * Save a stock update
     */
    CompletableFuture<StockUpdate> save(StockUpdate stockUpdate);
    
    /**
     * Find stock update by ID
     */
    CompletableFuture<Optional<StockUpdate>> findById(StockUpdateId id);
    
    /**
     * Find latest stock update for a product
     */
    CompletableFuture<Optional<StockUpdate>> findLatestByProductId(ProductId productId);
    
    /**
     * Check if stock update exists
     */
    CompletableFuture<Boolean> existsById(StockUpdateId id);
    
    /**
     * Delete stock update
     */
    CompletableFuture<Void> deleteById(StockUpdateId id);
}
