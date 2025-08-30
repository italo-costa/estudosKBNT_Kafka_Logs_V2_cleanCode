package com.estudoskbnt.kbntlogservice.controller;

import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import com.estudoskbnt.kbntlogservice.producer.StockUpdateProducer;
import io.micrometer.core.annotation.Timed;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.support.SendResult;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * Stock Update REST Controller
 * Handles inventory management operations for distribution centers and branches
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/stock")
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
@Validated
public class StockUpdateController {

    private final StockUpdateProducer stockUpdateProducer;

    public StockUpdateController(StockUpdateProducer stockUpdateProducer) {
        this.stockUpdateProducer = stockUpdateProducer;
    }

    /**
     * Generic stock update endpoint
     */
    @PostMapping("/update")
    @Timed(value = "stock.update", description = "Time taken to process stock updates")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> updateStock(
            @Valid @RequestBody StockUpdateMessage stockMessage,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        if (correlationId != null && !correlationId.isEmpty()) {
            stockMessage.setCorrelationId(correlationId);
        }
        
        log.debug("📦 Received stock update: {} {} for product {} at {}-{}", 
            stockMessage.getOperation(), 
            stockMessage.getQuantity(),
            stockMessage.getProductId(),
            stockMessage.getDistributionCenter(),
            stockMessage.getBranch());

        return stockUpdateProducer.processStockUpdate(stockMessage)
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
        
        return stockUpdateProducer.addStock(productId, distributionCenter, branch, 
                quantity, reasonCode, referenceDocument)
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
        
        return stockUpdateProducer.removeStock(productId, distributionCenter, branch, 
                quantity, reasonCode, referenceDocument)
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
        
        return stockUpdateProducer.transferStock(productId, distributionCenter, 
                sourceBranch, targetBranch, quantity, referenceDocument)
            .thenApply(this::createSuccessResponse)
            .exceptionally(this::createErrorResponse);
    }

    /**
     * Set absolute stock quantity
     */
    @PostMapping("/set")
    @Timed(value = "stock.set", description = "Time taken to set stock quantity")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> setStock(
            @RequestParam String productId,
            @RequestParam String distributionCenter,
            @RequestParam String branch,
            @RequestParam Integer quantity,
            @RequestParam(defaultValue = "ADJUSTMENT") String reasonCode,
            @RequestParam(required = false) String referenceDocument,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Setting stock of product {} at {}-{} to {}", 
            productId, distributionCenter, branch, quantity);
        
        return stockUpdateProducer.setStock(productId, distributionCenter, branch, 
                quantity, reasonCode, referenceDocument)
            .thenApply(this::createSuccessResponse)
            .exceptionally(this::createErrorResponse);
    }

    /**
     * Batch stock operations
     */
    @PostMapping("/batch")
    @Timed(value = "stock.batch", description = "Time taken to process batch stock updates")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> batchStockUpdate(
            @Valid @RequestBody StockUpdateMessage[] stockMessages,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📦 Processing batch of {} stock updates", stockMessages.length);
        
        var futures = new CompletableFuture[stockMessages.length];
        
        for (int i = 0; i < stockMessages.length; i++) {
            if (correlationId != null) {
                stockMessages[i].setCorrelationId(correlationId + "-" + i);
            }
            futures[i] = stockUpdateProducer.processStockUpdate(stockMessages[i]);
        }
        
        return CompletableFuture.allOf(futures)
            .thenApply(v -> {
                var response = Map.of(
                    "status", "accepted",
                    "batchSize", stockMessages.length,
                    "correlationId", correlationId != null ? correlationId : "batch-" + System.currentTimeMillis(),
                    "message", "Batch stock updates processed successfully"
                );
                return ResponseEntity.accepted().body(response);
            })
            .exceptionally(throwable -> {
                log.error("Failed to process batch stock updates", throwable);
                var errorResponse = Map.of(
                    "status", "error",
                    "message", throwable.getMessage(),
                    "batchSize", stockMessages.length
                );
                return ResponseEntity.internalServerError().body(errorResponse);
            });
    }

    /**
     * Health check endpoint for stock operations
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        var response = Map.of(
            "status", "UP",
            "service", "Stock Update Service",
            "timestamp", java.time.LocalDateTime.now(),
            "operations", java.util.List.of("ADD", "REMOVE", "TRANSFER", "SET")
        );
        return ResponseEntity.ok(response);
    }

    private ResponseEntity<Map<String, Object>> createSuccessResponse(SendResult<String, StockUpdateMessage> result) {
        var stockMessage = result.getProducerRecord().value();
        var response = Map.of(
            "status", "accepted",
            "correlationId", stockMessage.getCorrelationId(),
            "operation", stockMessage.getOperation(),
            "productId", stockMessage.getProductId(),
            "location", stockMessage.getDistributionCenter() + "-" + stockMessage.getBranch(),
            "quantity", stockMessage.getQuantity(),
            "topic", result.getRecordMetadata().topic(),
            "partition", result.getRecordMetadata().partition(),
            "offset", result.getRecordMetadata().offset()
        );
        return ResponseEntity.accepted().body(response);
    }

    private ResponseEntity<Map<String, Object>> createErrorResponse(Throwable throwable) {
        log.error("Failed to process stock update", throwable);
        var errorResponse = Map.of(
            "status", "error",
            "message", throwable.getMessage(),
            "timestamp", java.time.LocalDateTime.now()
        );
        return ResponseEntity.internalServerError().body(errorResponse);
    }
}
