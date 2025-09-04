package com.estudoskbnt.kbntlogservice.infrastructure.adapter.input.rest;

import com.estudoskbnt.kbntlogservice.domain.model.*;
import com.estudoskbnt.kbntlogservice.domain.port.input.*;
import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import io.micrometer.core.annotation.Timed;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.support.SendResult;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * Stock Update REST Controller - Input Adapter
 * 
 * REST adapter that exposes stock management operations via HTTP APIs.
 * Implements hexagonal architecture input adapter pattern.
 * 
 * This controller acts as the Infrastructure Layer adapter for REST input.
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/stock")
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
@Validated
@RequiredArgsConstructor
public class StockUpdateController {

    private final StockUpdateUseCase stockUpdateUseCase;

    /**
     * Generic stock update endpoint
     */
    @PostMapping("/update")
    @Timed(value = "stock.update", description = "Time taken to process stock updates")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> updateStock(
            @Valid @RequestBody StockUpdateRequest request,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Received stock update: {} {} for product {} at {}-{}", 
                request.getOperation(), 
                request.getQuantity(),
                request.getProductId(),
                request.getDistributionCenter(),
                request.getBranch());

        // Convert REST request to domain command
        StockUpdateCommand command = createCommandFromRequest(request, correlationId);
        
        return stockUpdateUseCase.processStockUpdate(command)
                .thenApply(this::createSuccessResponse)
                .exceptionally(this::createErrorResponse);
    }

    /**
     * Add stock (purchases, returns)
     */
    @PostMapping("/add")
    @Timed(value = "stock.add", description = "Time taken to add stock")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> addStock(
            @RequestParam String productId,
            @RequestParam String distributionCenter,
            @RequestParam String branch,
            @RequestParam Integer quantity,
            @RequestParam(defaultValue = "PURCHASE") String reasonCode,
            @RequestParam(required = false) String referenceDocument,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Adding {} units of product {} at {}-{}", 
                quantity, productId, distributionCenter, branch);
        
        AddStockCommand command = createAddStockCommand(productId, distributionCenter, branch, 
                quantity, reasonCode, referenceDocument, correlationId);
        
        return stockUpdateUseCase.addStock(command)
                .thenApply(this::createSuccessResponse)
                .exceptionally(this::createErrorResponse);
    }

    /**
     * Remove stock (sales, adjustments)
     */
    @PostMapping("/remove")
    @Timed(value = "stock.remove", description = "Time taken to remove stock")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> removeStock(
            @RequestParam String productId,
            @RequestParam String distributionCenter,
            @RequestParam String branch,
            @RequestParam Integer quantity,
            @RequestParam(defaultValue = "SALE") String reasonCode,
            @RequestParam(required = false) String referenceDocument,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Removing {} units of product {} from {}-{}", 
                quantity, productId, distributionCenter, branch);
        
        RemoveStockCommand command = createRemoveStockCommand(productId, distributionCenter, branch, 
                quantity, reasonCode, referenceDocument, correlationId);
        
        return stockUpdateUseCase.removeStock(command)
                .thenApply(this::createSuccessResponse)
                .exceptionally(this::createErrorResponse);
    }

    /**
     * Transfer stock between branches
     */
    @PostMapping("/transfer")
    @Timed(value = "stock.transfer", description = "Time taken to transfer stock")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> transferStock(
            @RequestParam String productId,
            @RequestParam String distributionCenter,
            @RequestParam String sourceBranch,
            @RequestParam String targetBranch,
            @RequestParam Integer quantity,
            @RequestParam(required = false) String referenceDocument,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Transferring {} units of product {} from {}-{} to {}-{}", 
                quantity, productId, distributionCenter, sourceBranch, distributionCenter, targetBranch);
        
        TransferStockCommand command = createTransferStockCommand(productId, distributionCenter,
                sourceBranch, targetBranch, quantity, referenceDocument, correlationId);
        
        return stockUpdateUseCase.transferStock(command)
                .thenApply(this::createSuccessResponse)
                .exceptionally(this::createErrorResponse);
    }

    /**
     * Reserve stock for orders
     */
    @PostMapping("/reserve")
    @Timed(value = "stock.reserve", description = "Time taken to reserve stock")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> reserveStock(
            @RequestParam String productId,
            @RequestParam String distributionCenter,
            @RequestParam String branch,
            @RequestParam Integer quantity,
            @RequestParam(defaultValue = "ORDER_RESERVATION") String reasonCode,
            @RequestParam(required = false) String referenceDocument,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Reserving {} units of product {} at {}-{}", 
                quantity, productId, distributionCenter, branch);
        
        ReserveStockCommand command = createReserveStockCommand(productId, distributionCenter, branch,
                quantity, reasonCode, referenceDocument, correlationId);
        
        return stockUpdateUseCase.reserveStock(command)
                .thenApply(this::createSuccessResponse)
                .exceptionally(this::createErrorResponse);
    }

    /**
     * Release reserved stock
     */
    @PostMapping("/release")
    @Timed(value = "stock.release", description = "Time taken to release stock")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> releaseStock(
            @RequestParam String productId,
            @RequestParam String distributionCenter,
            @RequestParam String branch,
            @RequestParam Integer quantity,
            @RequestParam(defaultValue = "ORDER_CANCELLED") String reasonCode,
            @RequestParam(required = false) String referenceDocument,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Releasing {} units of product {} at {}-{}", 
                quantity, productId, distributionCenter, branch);
        
        ReleaseStockCommand command = createReleaseStockCommand(productId, distributionCenter, branch,
                quantity, reasonCode, referenceDocument, correlationId);
        
        return stockUpdateUseCase.releaseStock(command)
                .thenApply(this::createSuccessResponse)
                .exceptionally(this::createErrorResponse);
    }

    /**
     * Validate stock update without processing
     */
    @PostMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateStockUpdate(
            @Valid @RequestBody StockUpdateRequest request) {
        
        log.debug("📦 Validating stock update: {} {} for product {} at {}-{}", 
                request.getOperation(), 
                request.getQuantity(),
                request.getProductId(),
                request.getDistributionCenter(),
                request.getBranch());

        StockUpdateCommand command = createCommandFromRequest(request, null);
        ValidationResult validation = stockUpdateUseCase.validateStockUpdate(command);
        
        if (validation.isValid()) {
            var response = Map.<String, Object>of(
                    "status", "valid",
                    "message", "Stock update is valid",
                    "productId", request.getProductId(),
                    "operation", request.getOperation()
            );
            return ResponseEntity.ok(response);
        } else {
            var response = Map.<String, Object>of(
                    "status", "invalid",
                    "errorCode", validation.getErrorCode(),
                    "message", validation.getErrorMessage(),
                    "productId", request.getProductId(),
                    "operation", request.getOperation()
            );
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * Health check endpoint for stock operations
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        var response = Map.<String, Object>of(
                "status", "UP",
                "service", "Stock Update Service",
                "timestamp", java.time.LocalDateTime.now(),
                "operations", java.util.List.of("ADD", "REMOVE", "TRANSFER", "RESERVE", "RELEASE")
        );
        return ResponseEntity.ok(response);
    }

    // ==================== PRIVATE HELPER METHODS ====================

    private StockUpdateCommand createCommandFromRequest(StockUpdateRequest request, String correlationId) {
        return GenericStockUpdateCommand.create(
                ProductId.of(request.getProductId()),
                DistributionCenter.of(request.getDistributionCenter()),
                Branch.of(request.getBranch()),
                Quantity.of(request.getQuantity()),
                Operation.of(request.getOperation()),
                CorrelationId.of(correlationId),
                request.getReasonCode() != null ? ReasonCode.of(request.getReasonCode()) : null,
                request.getReferenceDocument() != null ? ReferenceDocument.of(request.getReferenceDocument()) : null
        );
    }

    private AddStockCommand createAddStockCommand(String productId, String distributionCenter, 
                                                String branch, Integer quantity, String reasonCode, 
                                                String referenceDocument, String correlationId) {
        return new AddStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of(productId); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of(distributionCenter); }
            
            @Override
            public Branch getBranch() { return Branch.of(branch); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(quantity); }
            
            @Override
            public Operation getOperation() { return Operation.of("ADD", "Add stock operation"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of(correlationId); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of(reasonCode); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { 
                return referenceDocument != null ? ReferenceDocument.of(referenceDocument) : null; 
            }
        };
    }

    private RemoveStockCommand createRemoveStockCommand(String productId, String distributionCenter, 
                                                      String branch, Integer quantity, String reasonCode, 
                                                      String referenceDocument, String correlationId) {
        return new RemoveStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of(productId); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of(distributionCenter); }
            
            @Override
            public Branch getBranch() { return Branch.of(branch); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(quantity); }
            
            @Override
            public Operation getOperation() { return Operation.of("REMOVE", "Remove stock operation"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of(correlationId); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of(reasonCode); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { 
                return referenceDocument != null ? ReferenceDocument.of(referenceDocument) : null; 
            }
        };
    }

    private TransferStockCommand createTransferStockCommand(String productId, String distributionCenter,
                                                          String sourceBranch, String targetBranch, 
                                                          Integer quantity, String referenceDocument, 
                                                          String correlationId) {
        return new TransferStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of(productId); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of(distributionCenter); }
            
            @Override
            public Branch getBranch() { return Branch.of(targetBranch); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(quantity); }
            
            @Override
            public Operation getOperation() { return Operation.of("TRANSFER", "Transfer stock operation"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of(correlationId); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("TRANSFER"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { 
                return referenceDocument != null ? ReferenceDocument.of(referenceDocument) : null; 
            }
            
            @Override
            public SourceBranch getSourceBranch() { return SourceBranch.of(sourceBranch); }
        };
    }

    private ReserveStockCommand createReserveStockCommand(String productId, String distributionCenter, 
                                                        String branch, Integer quantity, String reasonCode, 
                                                        String referenceDocument, String correlationId) {
        return new ReserveStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of(productId); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of(distributionCenter); }
            
            @Override
            public Branch getBranch() { return Branch.of(branch); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(quantity); }
            
            @Override
            public Operation getOperation() { return Operation.of("RESERVE", "Reserve stock operation"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of(correlationId); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of(reasonCode); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { 
                return referenceDocument != null ? ReferenceDocument.of(referenceDocument) : null; 
            }
        };
    }

    private ReleaseStockCommand createReleaseStockCommand(String productId, String distributionCenter, 
                                                        String branch, Integer quantity, String reasonCode, 
                                                        String referenceDocument, String correlationId) {
        return new ReleaseStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of(productId); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of(distributionCenter); }
            
            @Override
            public Branch getBranch() { return Branch.of(branch); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(quantity); }
            
            @Override
            public Operation getOperation() { return Operation.of("RELEASE", "Release stock operation"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of(correlationId); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of(reasonCode); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { 
                return referenceDocument != null ? ReferenceDocument.of(referenceDocument) : null; 
            }
        };
    }

    private ResponseEntity<Map<String, Object>> createSuccessResponse(StockUpdateResult result) {
        if (result.isSuccess()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("correlationId", result.getEvent().getCorrelationId().getValue());
            response.put("operation", result.getEvent().getOperation().getType());
            response.put("productId", result.getEvent().getProductId().getValue());
            response.put("distributionCenter", result.getEvent().getDistributionCenter().getCode());
            response.put("branch", result.getEvent().getBranch().getCode());
            response.put("quantity", result.getEvent().getQuantity().getValue());
            response.put("eventId", result.getEvent().getEventId());
            response.put("eventType", result.getEvent().getEventType().name());
            response.put("targetTopic", result.getEvent().getTargetTopic());
            response.put("message", result.getMessage());
            
            return ResponseEntity.ok(response);
        } else {
            var response = Map.<String, Object>of(
                    "status", "failed",
                    "message", result.getMessage(),
                    "errorCode", result.getValidation().getErrorCode(),
                    "timestamp", java.time.LocalDateTime.now()
            );
            return ResponseEntity.badRequest().body(response);
        }
    }

    private ResponseEntity<Map<String, Object>> createErrorResponse(Throwable throwable) {
        log.error("Failed to process stock update", throwable);
        var errorResponse = Map.<String, Object>of(
                "status", "error",
                "message", throwable.getMessage(),
                "timestamp", java.time.LocalDateTime.now()
        );
        return ResponseEntity.internalServerError().body(errorResponse);
    }
}
