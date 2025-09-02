package com.kbnt.virtualstock.domain.model;

import lombok.*;
import java.math.BigDecimal;
import javax.validation.constraints.*;

/**
 * REST DTOs with proper Lombok annotations
 */

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateStockRequest {
    @NotNull
    private String productId;
    
    @NotBlank
    private String symbol;
    
    @NotBlank
    private String productName;
    
    @PositiveOrZero
    private Integer initialQuantity;
    
    @Positive
    private BigDecimal unitPrice;
    
    private String createdBy;
}

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockResponse {
    private String stockId;
    private String productId;
    private String symbol;
    private String productName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private String status;
    
    public static StockResponse from(Stock stock) {
        return StockResponse.builder()
                .stockId(stock.getStockId().getValue())
                .productId(stock.getProductId().getValue())
                .symbol(stock.getSymbol())
                .productName(stock.getProductName())
                .quantity(stock.getQuantity())
                .unitPrice(stock.getUnitPrice())
                .status(stock.getStatus().toString())
                .build();
    }
}
