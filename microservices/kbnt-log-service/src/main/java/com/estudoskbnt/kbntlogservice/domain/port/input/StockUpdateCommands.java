package com.estudoskbnt.kbntlogservice.domain.port.input;

import com.estudoskbnt.kbntlogservice.domain.model.*;

/**
 * Generic Stock Update Command
 * 
 * Generic command for stock update operations.
 * Contains all common fields needed for any stock operation.
 */
public class GenericStockUpdateCommand implements StockUpdateCommand, AddStockCommand, RemoveStockCommand {
    
    private final ProductId productId;
    private final DistributionCenter distributionCenter;
    private final Branch branch;
    private final Quantity quantity;
    private final Operation operation;
    private final CorrelationId correlationId;
    private final ReasonCode reasonCode;
    private final ReferenceDocument referenceDocument;

    private GenericStockUpdateCommand(ProductId productId, 
                                    DistributionCenter distributionCenter,
                                    Branch branch, 
                                    Quantity quantity, 
                                    Operation operation,
                                    CorrelationId correlationId,
                                    ReasonCode reasonCode,
                                    ReferenceDocument referenceDocument) {
        this.productId = productId;
        this.distributionCenter = distributionCenter;
        this.branch = branch;
        this.quantity = quantity;
        this.operation = operation;
        this.correlationId = correlationId;
        this.reasonCode = reasonCode;
        this.referenceDocument = referenceDocument;
    }

    public static GenericStockUpdateCommand create(ProductId productId,
                                                 DistributionCenter distributionCenter,
                                                 Branch branch,
                                                 Quantity quantity,
                                                 Operation operation,
                                                 CorrelationId correlationId,
                                                 ReasonCode reasonCode,
                                                 ReferenceDocument referenceDocument) {
        return new GenericStockUpdateCommand(productId, distributionCenter, branch, quantity, 
                                           operation, correlationId, reasonCode, referenceDocument);
    }

    @Override
    public ProductId getProductId() {
        return productId;
    }

    @Override
    public DistributionCenter getDistributionCenter() {
        return distributionCenter;
    }

    @Override
    public Branch getBranch() {
        return branch;
    }

    @Override
    public Quantity getQuantity() {
        return quantity;
    }

    @Override
    public Operation getOperation() {
        return operation;
    }

    @Override
    public CorrelationId getCorrelationId() {
        return correlationId;
    }

    @Override
    public ReasonCode getReasonCode() {
        return reasonCode;
    }

    @Override
    public ReferenceDocument getReferenceDocument() {
        return referenceDocument;
    }
}

/**
 * Transfer Stock Command Interface
 * 
 * Specific command interface for stock transfer operations.
 */
interface TransferStockCommand extends StockUpdateCommand {
    SourceBranch getSourceBranch();
}

/**
 * Reserve Stock Command Interface
 * 
 * Specific command interface for stock reservation operations.
 */
interface ReserveStockCommand extends StockUpdateCommand {
    // Inherits all base command properties
}

/**
 * Release Stock Command Interface
 * 
 * Specific command interface for stock release operations.
 */
interface ReleaseStockCommand extends StockUpdateCommand {
    // Inherits all base command properties
}
