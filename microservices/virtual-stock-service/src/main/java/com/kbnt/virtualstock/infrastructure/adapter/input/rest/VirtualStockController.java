package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase.*;
import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto.ApiResponse;
import com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto.CreateStockRequest;
import com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto.UpdatePriceRequest;
import com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto.UpdateQuantityRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * REST Controller for Virtual Stock Service.
 * 
 * Provides endpoints for complete stock management operations.
 * Following Clean Architecture principles with proper error handling.
 */
@RestController
@RequestMapping("/api/v1/virtual-stock")
@CrossOrigin(origins = "*")
public class VirtualStockController {

    private static final Logger logger = LoggerFactory.getLogger(VirtualStockController.class);

    private final StockManagementUseCase stockManagementUseCase;

    @Autowired
    public VirtualStockController(StockManagementUseCase stockManagementUseCase) {
        this.stockManagementUseCase = stockManagementUseCase;
    }

    /**
     * Create a new stock item.
     */
    @PostMapping("/stocks")
    public ResponseEntity<ApiResponse<Stock>> createStock(@RequestBody CreateStockRequest request) {
        try {
            logger.info("Creating stock with symbol: {}", request.getSymbol());
            
            CreateStockCommand command = new CreateStockCommandImpl(
                request.getProductId(),
                request.getSymbol(),
                request.getProductName(),
                request.getQuantity(),
                request.getUnitPrice(),
                request.getCreatedBy()
            );
            
            StockCreationResult result = stockManagementUseCase.createStock(command);
            
            if (result.isSuccess()) {
                logger.info("Stock created successfully: {}", result.getStock().getStockId());
                return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(result.getStock(), "Stock created successfully"));
            } else {
                logger.error("Failed to create stock: {}", result.getErrorMessage());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(result.getErrorMessage()));
            }
            
        } catch (Exception e) {
            logger.error("Error creating stock", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        }
    }

    /**
     * Get all stocks.
     */
    @GetMapping("/stocks")
    public ResponseEntity<ApiResponse<List<Stock>>> getAllStocks() {
        try {
            logger.info("Retrieving all stocks");
            List<Stock> stocks = stockManagementUseCase.getAllStocks();
            
            return ResponseEntity.ok(
                ApiResponse.success(stocks, "Stocks retrieved successfully")
            );
            
        } catch (Exception e) {
            logger.error("Error retrieving stocks", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        }
    }

    /**
     * Get stock by ID.
     */
    @GetMapping("/stocks/{stockId}")
    public ResponseEntity<ApiResponse<Stock>> getStock(@PathVariable String stockId) {
        try {
            logger.info("Retrieving stock with ID: {}", stockId);
            
            Optional<Stock> stock = stockManagementUseCase.getStockById(new Stock.StockId(stockId));
            
            if (stock.isPresent()) {
                return ResponseEntity.ok(
                    ApiResponse.success(stock.get(), "Stock retrieved successfully")
                );
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Stock not found with ID: " + stockId));
            }
            
        } catch (Exception e) {
            logger.error("Error retrieving stock with ID: {}", stockId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        }
    }

    /**
     * Update stock price.
     */
    @PutMapping("/stocks/{stockId}/price")
    public ResponseEntity<ApiResponse<Stock>> updatePrice(
            @PathVariable String stockId, 
            @RequestBody UpdatePriceRequest request) {
        try {
            logger.info("Updating price for stock ID: {} to {}", stockId, request.getPrice());
            
            UpdateStockPriceCommand command = new UpdateStockPriceCommandImpl(
                new Stock.StockId(stockId),
                request.getPrice(),
                request.getUpdatedBy(),
                request.getReason()
            );
            
            StockUpdateResult result = stockManagementUseCase.updateStockPrice(command);
            
            if (result.isSuccess()) {
                logger.info("Stock price updated successfully: {}", stockId);
                return ResponseEntity.ok(
                    ApiResponse.success(result.getUpdatedStock(), "Stock price updated successfully")
                );
            } else {
                logger.error("Failed to update stock price: {}", result.getErrorMessage());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(result.getErrorMessage()));
            }
            
        } catch (Exception e) {
            logger.error("Error updating stock price for ID: {}", stockId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        }
    }

    /**
     * Update stock quantity.
     */
    @PutMapping("/stocks/{stockId}/quantity")
    public ResponseEntity<ApiResponse<Stock>> updateQuantity(
            @PathVariable String stockId, 
            @RequestBody UpdateQuantityRequest request) {
        try {
            logger.info("Updating quantity for stock ID: {} to {}", stockId, request.getQuantity());
            
            UpdateStockQuantityCommand command = new UpdateStockQuantityCommandImpl(
                new Stock.StockId(stockId),
                request.getQuantity(),
                request.getUpdatedBy(),
                request.getReason()
            );
            
            StockUpdateResult result = stockManagementUseCase.updateStockQuantity(command);
            
            if (result.isSuccess()) {
                logger.info("Stock quantity updated successfully: {}", stockId);
                return ResponseEntity.ok(
                    ApiResponse.success(result.getUpdatedStock(), "Stock quantity updated successfully")
                );
            } else {
                logger.error("Failed to update stock quantity: {}", result.getErrorMessage());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(result.getErrorMessage()));
            }
            
        } catch (Exception e) {
            logger.error("Error updating stock quantity for ID: {}", stockId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        }
    }

    /**
     * Health check endpoint.
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(
            ApiResponse.success("OK", "Virtual Stock Service is healthy")
        );
    }

    // Command Implementation Classes
    private static class CreateStockCommandImpl implements CreateStockCommand {
        private final Stock.ProductId productId;
        private final String symbol;
        private final String productName;
        private final Integer initialQuantity;
        private final BigDecimal unitPrice;
        private final String createdBy;

        public CreateStockCommandImpl(Stock.ProductId productId, String symbol, String productName,
                                    Integer initialQuantity, BigDecimal unitPrice, String createdBy) {
            this.productId = productId;
            this.symbol = symbol;
            this.productName = productName;
            this.initialQuantity = initialQuantity;
            this.unitPrice = unitPrice;
            this.createdBy = createdBy;
        }

        @Override public Stock.ProductId getProductId() { return productId; }
        @Override public String getSymbol() { return symbol; }
        @Override public String getProductName() { return productName; }
        @Override public Integer getInitialQuantity() { return initialQuantity; }
        @Override public BigDecimal getUnitPrice() { return unitPrice; }
        @Override public String getCreatedBy() { return createdBy; }
    }

    private static class UpdateStockPriceCommandImpl implements UpdateStockPriceCommand {
        private final Stock.StockId stockId;
        private final BigDecimal newPrice;
        private final String updatedBy;
        private final String reason;

        public UpdateStockPriceCommandImpl(Stock.StockId stockId, BigDecimal newPrice, 
                                         String updatedBy, String reason) {
            this.stockId = stockId;
            this.newPrice = newPrice;
            this.updatedBy = updatedBy;
            this.reason = reason;
        }

        @Override public Stock.StockId getStockId() { return stockId; }
        @Override public BigDecimal getNewPrice() { return newPrice; }
        @Override public String getUpdatedBy() { return updatedBy; }
        @Override public String getReason() { return reason; }
    }

    private static class UpdateStockQuantityCommandImpl implements UpdateStockQuantityCommand {
        private final Stock.StockId stockId;
        private final Integer newQuantity;
        private final String updatedBy;
        private final String reason;

        public UpdateStockQuantityCommandImpl(Stock.StockId stockId, Integer newQuantity, 
                                            String updatedBy, String reason) {
            this.stockId = stockId;
            this.newQuantity = newQuantity;
            this.updatedBy = updatedBy;
            this.reason = reason;
        }

        @Override public Stock.StockId getStockId() { return stockId; }
        @Override public Integer getNewQuantity() { return newQuantity; }
        @Override public String getUpdatedBy() { return updatedBy; }
        @Override public String getReason() { return reason; }
    }
}
