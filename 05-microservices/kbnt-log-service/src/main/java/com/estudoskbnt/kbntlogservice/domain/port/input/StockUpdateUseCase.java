package com.estudoskbnt.kbntlogservice.domain.port.input;

import com.estudoskbnt.kbntlogservice.domain.model.*;

import java.util.concurrent.CompletableFuture;

/**
 * Stock Update Use Case - Input Port
 * 
 * Defines the core business operations for stock management.
 * Application services will implement this interface.
 * 
 * This is the primary input port for the stock update domain.
 * 
 * All command and result interfaces have been moved to individual files:
 * - StockUpdateCommand.java
 * - AddStockCommand.java, RemoveStockCommand.java, etc.
 * - StockUpdateResult.java
 * - GenericStockUpdateCommand.java
 */
public interface StockUpdateUseCase {
    
  /**
   * Process a stock update operation
   */
  CompletableFuture<StockUpdateResult> processStockUpdate(StockUpdateCommand command);
    
  /**
   * Add stock to inventory
   */
  CompletableFuture<StockUpdateResult> addStock(AddStockCommand command);
    
  /**
   * Remove stock from inventory
   */
  CompletableFuture<StockUpdateResult> removeStock(RemoveStockCommand command);
    
  /**
   * Transfer stock between locations
   */
  CompletableFuture<StockUpdateResult> transferStock(TransferStockCommand command);
    
  /**
   * Reserve stock for orders
   */
  CompletableFuture<StockUpdateResult> reserveStock(ReserveStockCommand command);
    
  /**
   * Release reserved stock
   */
  CompletableFuture<StockUpdateResult> releaseStock(ReleaseStockCommand command);
    
  /**
   * Validate a stock update without processing
   */
  ValidationResult validateStockUpdate(StockUpdateCommand command);
}
