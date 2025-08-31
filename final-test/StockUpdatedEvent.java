package com.kbnt.virtualstock.domain.model;

import lombok.*;
import java.time.LocalDateTime;

/**
 * StockUpdatedEvent Domain Event
 */
@Getter
@Builder
@ToString
@AllArgsConstructor
@NoArgsConstructor
public class StockUpdatedEvent {
    private String eventId;
    private String stockId;
    private String productId;
    private String eventType;
    private String reason;
    private LocalDateTime timestamp;
    private String updatedBy;
    
    // Stock data for event
    private String symbol;
    private String productName;
    private Integer previousQuantity;
    private Integer newQuantity;
    private String status;
    
    public static StockUpdatedEvent quantityUpdated(Stock previousStock, Stock updatedStock, String reason) {
        return StockUpdatedEvent.builder()
                .eventId(java.util.UUID.randomUUID().toString())
                .stockId(updatedStock.getStockId().getValue())
                .productId(updatedStock.getProductId().getValue())
                .symbol(updatedStock.getSymbol())
                .productName(updatedStock.getProductName())
                .previousQuantity(previousStock.getQuantity())
                .newQuantity(updatedStock.getQuantity())
                .status(updatedStock.getStatus().toString())
                .eventType("QUANTITY_UPDATED")
                .reason(reason)
                .updatedBy(updatedStock.getLastUpdatedBy())
                .timestamp(LocalDateTime.now())
                .build();
    }
}
