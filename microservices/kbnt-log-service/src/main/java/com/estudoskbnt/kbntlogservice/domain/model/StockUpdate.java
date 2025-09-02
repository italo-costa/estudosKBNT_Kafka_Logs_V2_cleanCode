package com.estudoskbnt.kbntlogservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Stock Update Domain Entity - Core business domain model
 * 
 * Represents a stock update operation in the inventory management system.
 * This is the central aggregate root for stock update operations.
 * 
 * Follows Domain-Driven Design principles:
 * - Rich domain model with business logic
 * - Immutable value objects
 * - Domain validation rules
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdate {
    
    private StockUpdateId id;
    private ProductId productId;
    private DistributionCenter distributionCenter;
    private Branch branch;
    private Quantity quantity;
    private Operation operation;
    private LocalDateTime timestamp;
    private CorrelationId correlationId;
    private SourceBranch sourceBranch;
    private ReasonCode reasonCode;
    private ReferenceDocument referenceDocument;
    private StockUpdateStatus status;
    
    /**
     * Factory method to create a new StockUpdate
     */
    public static StockUpdate create(ProductId productId, 
                                   DistributionCenter distributionCenter,
                                   Branch branch,
                                   Quantity quantity,
                                   Operation operation,
                                   CorrelationId correlationId) {
        return StockUpdate.builder()
                .id(StockUpdateId.generate())
                .productId(productId)
                .distributionCenter(distributionCenter)
                .branch(branch)
                .quantity(quantity)
                .operation(operation)
                .timestamp(LocalDateTime.now())
                .correlationId(correlationId)
                .status(StockUpdateStatus.PENDING)
                .build();
    }
    
    /**
     * Domain validation - Business rules enforcement
     */
    public ValidationResult validateForProcessing() {
        if (productId == null || productId.getValue().isBlank()) {
            return ValidationResult.failed("INVALID_PRODUCT_ID", "Product ID cannot be empty");
        }
        
        if (quantity == null || quantity.getValue() < 0) {
            return ValidationResult.failed("INVALID_QUANTITY", "Quantity must be positive");
        }
        
        if (operation == null) {
            return ValidationResult.failed("INVALID_OPERATION", "Operation cannot be null");
        }
        
        if (distributionCenter == null || distributionCenter.getCode().isBlank()) {
            return ValidationResult.failed("INVALID_DISTRIBUTION_CENTER", "Distribution center is required");
        }
        
        if (branch == null || branch.getCode().isBlank()) {
            return ValidationResult.failed("INVALID_BRANCH", "Branch is required");
        }
        
        // Business rule: TRANSFER operations require source branch
        if (operation.isTransfer() && (sourceBranch == null || sourceBranch.getCode().isBlank())) {
            return ValidationResult.failed("TRANSFER_REQUIRES_SOURCE", "Transfer operations require source branch");
        }
        
        return ValidationResult.success();
    }
    
    /**
     * Process the stock update - Core business logic
     */
    public StockUpdateEvent processUpdate() {
        ValidationResult validation = validateForProcessing();
        if (!validation.isValid()) {
            throw new InvalidStockUpdateException(validation.getErrorMessage());
        }
        
        // Mark as processed
        this.status = StockUpdateStatus.PROCESSED;
        this.timestamp = LocalDateTime.now();
        
        // Create domain event
        return StockUpdateEvent.builder()
                .eventId(UUID.randomUUID().toString())
                .stockUpdateId(this.id)
                .productId(this.productId)
                .distributionCenter(this.distributionCenter)
                .branch(this.branch)
                .quantity(this.quantity)
                .operation(this.operation)
                .timestamp(this.timestamp)
                .correlationId(this.correlationId)
                .eventType(determineEventType())
                .build();
    }
    
    /**
     * Determine target topic based on operation type
     */
    public String determineTargetTopic() {
        return switch (operation.getType()) {
            case "ADD", "REMOVE", "SET" -> "inventory-events";
            case "TRANSFER" -> "inventory-transfer-events";
            case "RESERVE", "RELEASE" -> "inventory-reservation-events";
            default -> "kbnt-stock-updates"; // fallback
        };
    }
    
    /**
     * Generate partition key for Kafka distribution
     */
    public String generatePartitionKey() {
        return productId.getValue() + "-" + distributionCenter.getCode();
    }
    
    private EventType determineEventType() {
        return switch (operation.getType()) {
            case "ADD" -> EventType.STOCK_INCREASED;
            case "REMOVE" -> EventType.STOCK_DECREASED;
            case "SET" -> EventType.STOCK_ADJUSTED;
            case "TRANSFER" -> EventType.STOCK_TRANSFERRED;
            case "RESERVE" -> EventType.STOCK_RESERVED;
            case "RELEASE" -> EventType.STOCK_RELEASED;
            default -> EventType.STOCK_UPDATED;
        };
    }
    
    /**
     * Check if this is a critical stock operation
     */
    public boolean isCriticalOperation() {
        return operation.isTransfer() || 
               (operation.isRemove() && quantity.getValue() > 100) ||
               operation.isReserve();
    }
    
    /**
     * Get priority level for processing
     */
    public Priority getPriority() {
        if (isCriticalOperation()) {
            return Priority.HIGH;
        }
        return operation.isAdd() ? Priority.NORMAL : Priority.LOW;
    }
}
