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

/**
 * Base Stock Update Command
 */
interface StockUpdateCommand {
    ProductId getProductId();
    DistributionCenter getDistributionCenter();
    Branch getBranch();
    Quantity getQuantity();
    Operation getOperation();
    CorrelationId getCorrelationId();
    ReasonCode getReasonCode();
    ReferenceDocument getReferenceDocument();
}

/**
 * Generic Stock Update Command Implementation
 */
interface GenericStockUpdateCommand extends StockUpdateCommand {
    
    static GenericStockUpdateCommand create(ProductId productId,
                                          DistributionCenter distributionCenter,
                                          Branch branch,
                                          Quantity quantity,
                                          Operation operation,
                                          CorrelationId correlationId,
                                          ReasonCode reasonCode,
                                          ReferenceDocument referenceDocument) {
        return new GenericStockUpdateCommand() {
            @Override
            public ProductId getProductId() { return productId; }
            
            @Override
            public DistributionCenter getDistributionCenter() { return distributionCenter; }
            
            @Override
            public Branch getBranch() { return branch; }
            
            @Override
            public Quantity getQuantity() { return quantity; }
            
            @Override
            public Operation getOperation() { return operation; }
            
            @Override
            public CorrelationId getCorrelationId() { return correlationId; }
            
            @Override
            public ReasonCode getReasonCode() { return reasonCode; }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return referenceDocument; }
        };
    }
}

/**
 * Add Stock Command
 */
interface AddStockCommand extends StockUpdateCommand {
    default Operation getOperation() {
        return Operation.of("ADD");
    }
}

/**
 * Remove Stock Command
 */
interface RemoveStockCommand extends StockUpdateCommand {
    default Operation getOperation() {
        return Operation.of("REMOVE");
    }
}

/**
 * Transfer Stock Command
 */
interface TransferStockCommand extends StockUpdateCommand {
    SourceBranch getSourceBranch();
    
    default Operation getOperation() {
        return Operation.of("TRANSFER");
    }
}

/**
 * Reserve Stock Command
 */
interface ReserveStockCommand extends StockUpdateCommand {
    default Operation getOperation() {
        return Operation.of("RESERVE");
    }
}

/**
 * Release Stock Command
 */
interface ReleaseStockCommand extends StockUpdateCommand {
    default Operation getOperation() {
        return Operation.of("RELEASE");
    }
}

/**
 * Stock Update Result
 */
interface StockUpdateResult {
    boolean isSuccess();
    String getMessage();
    StockUpdateId getStockUpdateId();
    StockUpdateEvent getEvent();
    ValidationResult getValidation();
    
    static StockUpdateResult success(StockUpdateId stockUpdateId, StockUpdateEvent event) {
        return new StockUpdateResult() {
            @Override
            public boolean isSuccess() { return true; }
            
            @Override
            public String getMessage() { return "Stock update processed successfully"; }
            
            @Override
            public StockUpdateId getStockUpdateId() { return stockUpdateId; }
            
            @Override
            public StockUpdateEvent getEvent() { return event; }
            
            @Override
            public ValidationResult getValidation() { return ValidationResult.success(); }
        };
    }
    
    static StockUpdateResult failure(String message, ValidationResult validation) {
        return new StockUpdateResult() {
            @Override
            public boolean isSuccess() { return false; }
            
            @Override
            public String getMessage() { return message; }
            
            @Override
            public StockUpdateId getStockUpdateId() { return null; }
            
            @Override
            public StockUpdateEvent getEvent() { return null; }
            
            @Override
            public ValidationResult getValidation() { return validation; }
        };
    }
}
