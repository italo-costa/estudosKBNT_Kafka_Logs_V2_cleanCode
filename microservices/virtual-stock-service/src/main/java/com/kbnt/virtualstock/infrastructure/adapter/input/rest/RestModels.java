package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import lombok.Builder;
import lombok.Getter;

import javax.validation.constraints.*;
import java.math.BigDecimal;

/**
 * REST API Request/Response DTOs
 */

@Getter
public class CreateStockRequest {
    @NotBlank(message = "Product ID is required")
    private String productId;
    
    @NotBlank(message = "Symbol is required")
    @Size(min = 1, max = 10, message = "Symbol must be between 1 and 10 characters")
    private String symbol;
    
    @NotBlank(message = "Product name is required")
    @Size(min = 1, max = 100, message = "Product name must be between 1 and 100 characters")
    private String productName;
    
    @NotNull(message = "Initial quantity is required")
    @Min(value = 0, message = "Initial quantity must be non-negative")
    private Integer initialQuantity;
    
    @NotNull(message = "Unit price is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "Unit price must be positive")
    private BigDecimal unitPrice;
    
    @NotBlank(message = "Created by is required")
    private String createdBy;
}

@Getter
public class UpdateQuantityRequest {
    @NotNull(message = "New quantity is required")
    @Min(value = 0, message = "New quantity must be non-negative")
    private Integer newQuantity;
    
    @NotBlank(message = "Updated by is required")
    private String updatedBy;
    
    private String reason;
}

@Getter
public class UpdatePriceRequest {
    @NotNull(message = "New price is required")
    @DecimalMin(value = "0.0", inclusive = false, message = "New price must be positive")
    private BigDecimal newPrice;
    
    @NotBlank(message = "Updated by is required")
    private String updatedBy;
    
    private String reason;
}

@Getter
public class ReserveStockRequest {
    @NotNull(message = "Quantity to reserve is required")
    @Min(value = 1, message = "Quantity to reserve must be positive")
    private Integer quantityToReserve;
    
    @NotBlank(message = "Reserved by is required")
    private String reservedBy;
    
    private String reason;
}

@Getter
@Builder
public class StockResponse {
    private final String stockId;
    private final String productId;
    private final String symbol;
    private final String productName;
    private final Integer quantity;
    private final BigDecimal unitPrice;
    private final String status;
    private final String lastUpdatedBy;
    private final String lastUpdated;
    private final BigDecimal totalValue;
    private final boolean isLowStock;
    private final boolean isAvailable;
    
    public static StockResponse fromDomain(Stock stock) {
        return StockResponse.builder()
                .stockId(stock.getStockId().getValue())
                .productId(stock.getProductId().getValue())
                .symbol(stock.getSymbol())
                .productName(stock.getProductName())
                .quantity(stock.getQuantity())
                .unitPrice(stock.getUnitPrice())
                .status(stock.getStatus().name())
                .lastUpdatedBy(stock.getLastUpdatedBy())
                .lastUpdated(stock.getLastUpdated().toString())
                .totalValue(stock.getTotalValue())
                .isLowStock(stock.isLowStock())
                .isAvailable(stock.isAvailable())
                .build();
    }
}

@Getter
@Builder
public class StockReservationResponse {
    private final StockResponse stock;
    private final Integer reservedQuantity;
    private final String reservedAt;
}

@Getter
@Builder
public class ApiResponse<T> {
    private final boolean success;
    private final T data;
    private final String message;
    private final String timestamp;
    
    public static <T> ApiResponse<T> success(T data, String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .data(data)
                .message(message)
                .timestamp(java.time.LocalDateTime.now().toString())
                .build();
    }
    
    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .data(null)
                .message(message)
                .timestamp(java.time.LocalDateTime.now().toString())
                .build();
    }
}
