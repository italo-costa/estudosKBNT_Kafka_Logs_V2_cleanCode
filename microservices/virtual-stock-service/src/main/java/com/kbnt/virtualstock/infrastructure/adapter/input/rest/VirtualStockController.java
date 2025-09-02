package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;
import com.kbnt.virtualstock.infrastructure.config.EnhancedLoggingConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Virtual Stock REST Controller
 * 
 * REST adapter that exposes stock management operations via HTTP APIs.
 * Implements hexagonal architecture input adapter pattern.
 */
@RestController
@RequestMapping("/api/v1/virtual-stock")
@RequiredArgsConstructor
@Slf4j
public class VirtualStockController {
    
    private final StockManagementUseCase stockManagementUseCase;
    
    /**
     * Create new stock item
     */
    @PostMapping("/stocks")
    public ResponseEntity<ApiResponse<StockResponse>> createStock(@Valid @RequestBody CreateStockRequest request) {
        try {
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "RestController");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(request.getProductId(), null);
            
            long startTime = System.currentTimeMillis();
            
            EnhancedLoggingConfig.LoggingUtils.logApiCall("POST", "/api/v1/virtual-stock/stocks", 0, 0);
            EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("CREATE_STOCK", "STARTED", 
                "Processing create stock request");
            
            // Convert request to command
            StockManagementUseCase.CreateStockCommand command = new CreateStockCommandImpl(request);
            
            // Execute use case
            StockManagementUseCase.StockCreationResult result = stockManagementUseCase.createStock(command);
            
            long duration = System.currentTimeMillis() - startTime;
            
            if (result.isSuccess()) {
                StockResponse response = StockResponse.fromDomain(result.getStock());
                
                EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("CREATE_STOCK", duration);
                EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("CREATE_STOCK", "COMPLETED", 
                    "Stock created successfully");
                EnhancedLoggingConfig.LoggingUtils.logApiCall("POST", "/api/v1/virtual-stock/stocks", 201, duration);
                
                return ResponseEntity.status(HttpStatus.CREATED)
                        .body(ApiResponse.success(response, "Stock created successfully"));
            } else {
                EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("CREATE_STOCK", "FAILED", 
                    result.getErrorMessage());
                EnhancedLoggingConfig.LoggingUtils.logApiCall("POST", "/api/v1/virtual-stock/stocks", 400, duration);
                
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error(result.getErrorMessage()));
            }
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("CREATE_STOCK", 
                "Unexpected error creating stock", e, request.getProductId());
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        } finally {
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    /**
     * Update stock quantity
     */
    @PutMapping("/stocks/{stockId}/quantity")
    public ResponseEntity<ApiResponse<StockResponse>> updateStockQuantity(
            @PathVariable String stockId,
            @Valid @RequestBody UpdateQuantityRequest request) {
        try {
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "RestController");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(stockId, null);
            
            long startTime = System.currentTimeMillis();
            
            EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("UPDATE_QUANTITY", "STARTED", 
                String.format("Updating quantity to %d", request.getNewQuantity()));
            
            // Convert request to command
            StockManagementUseCase.UpdateStockQuantityCommand command = 
                new UpdateStockQuantityCommandImpl(stockId, request);
            
            // Execute use case
            StockManagementUseCase.StockUpdateResult result = stockManagementUseCase.updateStockQuantity(command);
            
            long duration = System.currentTimeMillis() - startTime;
            
            if (result.isSuccess()) {
                StockResponse response = StockResponse.fromDomain(result.getUpdatedStock());
                
                EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("UPDATE_QUANTITY", duration);
                EnhancedLoggingConfig.LoggingUtils.logApiCall("PUT", "/stocks/" + stockId + "/quantity", 200, duration);
                
                return ResponseEntity.ok(ApiResponse.success(response, "Stock quantity updated successfully"));
            } else {
                EnhancedLoggingConfig.LoggingUtils.logApiCall("PUT", "/stocks/" + stockId + "/quantity", 400, duration);
                return ResponseEntity.badRequest().body(ApiResponse.error(result.getErrorMessage()));
            }
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("UPDATE_QUANTITY", 
                "Unexpected error updating quantity", e, stockId);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        } finally {
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    /**
     * Reserve stock
     */
    @PostMapping("/stocks/{stockId}/reserve")
    public ResponseEntity<ApiResponse<StockReservationResponse>> reserveStock(
            @PathVariable String stockId,
            @Valid @RequestBody ReserveStockRequest request) {
        try {
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "RestController");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(stockId, null);
            
            long startTime = System.currentTimeMillis();
            
            EnhancedLoggingConfig.LoggingUtils.logWorkflowStep("RESERVE_STOCK", "STARTED", 
                String.format("Reserving %d units", request.getQuantityToReserve()));
            
            // Convert request to command
            StockManagementUseCase.ReserveStockCommand command = 
                new ReserveStockCommandImpl(stockId, request);
            
            // Execute use case
            StockManagementUseCase.StockReservationResult result = stockManagementUseCase.reserveStock(command);
            
            long duration = System.currentTimeMillis() - startTime;
            
            if (result.isSuccess()) {
                StockReservationResponse response = StockReservationResponse.builder()
                        .stock(StockResponse.fromDomain(result.getUpdatedStock()))
                        .reservedQuantity(result.getReservedQuantity())
                        .reservedAt(LocalDateTime.now())
                        .build();
                
                EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("RESERVE_STOCK", duration);
                EnhancedLoggingConfig.LoggingUtils.logApiCall("POST", "/stocks/" + stockId + "/reserve", 200, duration);
                
                return ResponseEntity.ok(ApiResponse.success(response, "Stock reserved successfully"));
            } else {
                EnhancedLoggingConfig.LoggingUtils.logApiCall("POST", "/stocks/" + stockId + "/reserve", 400, duration);
                return ResponseEntity.badRequest().body(ApiResponse.error(result.getErrorMessage()));
            }
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("RESERVE_STOCK", 
                "Unexpected error reserving stock", e, stockId);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        } finally {
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    /**
     * Get stock by ID
     */
    @GetMapping("/stocks/{stockId}")
    public ResponseEntity<ApiResponse<StockResponse>> getStock(@PathVariable String stockId) {
        try {
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "RestController");
            long startTime = System.currentTimeMillis();
            
            Optional<Stock> stockOpt = stockManagementUseCase.getStockById(Stock.StockId.builder().value(stockId).build());
            
            long duration = System.currentTimeMillis() - startTime;
            
            if (stockOpt.isPresent()) {
                StockResponse response = StockResponse.fromDomain(stockOpt.get());
                EnhancedLoggingConfig.LoggingUtils.logApiCall("GET", "/stocks/" + stockId, 200, duration);
                return ResponseEntity.ok(ApiResponse.success(response, "Stock retrieved successfully"));
            } else {
                EnhancedLoggingConfig.LoggingUtils.logApiCall("GET", "/stocks/" + stockId, 404, duration);
                return ResponseEntity.notFound().build();
            }
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("GET_STOCK", 
                "Error retrieving stock", e, stockId);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        } finally {
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
    
    /**
     * Get all stocks
     */
    @GetMapping("/stocks")
    public ResponseEntity<ApiResponse<List<StockResponse>>> getAllStocks() {
        try {
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("VIRTUAL-STOCK", "RestController");
            long startTime = System.currentTimeMillis();
            
            List<Stock> stocks = stockManagementUseCase.getAllStocks();
            List<StockResponse> responses = stocks.stream()
                    .map(StockResponse::fromDomain)
                    .collect(Collectors.toList());
            
            long duration = System.currentTimeMillis() - startTime;
            EnhancedLoggingConfig.LoggingUtils.logApiCall("GET", "/stocks", 200, duration);
            
            return ResponseEntity.ok(ApiResponse.success(responses, "Stocks retrieved successfully"));
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("GET_ALL_STOCKS", 
                "Error retrieving all stocks", e, null);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Internal server error: " + e.getMessage()));
        } finally {
            EnhancedLoggingConfig.LoggingUtils.clearContext();
        }
    }
}
