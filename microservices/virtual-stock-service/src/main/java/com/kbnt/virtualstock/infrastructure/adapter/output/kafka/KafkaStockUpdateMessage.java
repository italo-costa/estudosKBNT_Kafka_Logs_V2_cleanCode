package com.kbnt.virtualstock.infrastructure.adapter.output.kafka;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Builder;
import lombok.Getter;
import lombok.ToString;

/**
 * Kafka Stock Update Message
 * 
 * Message format sent to Red Hat AMQ Streams (Kafka) topics.
 * This is the external representation of stock events.
 */
@Getter
@Builder
@ToString
public class KafkaStockUpdateMessage {
    
    // Event identification
    private final String correlationId;
    private final String eventId;
    
    // Stock information
    private final String stockId;
    private final String productId;
    private final String symbol;
    private final String productName;
    
    // Quantity changes
    private final Integer previousQuantity;
    private final Integer newQuantity;
    
    // Price changes
    private final BigDecimal previousPrice;
    private final BigDecimal newPrice;
    
    // Status changes
    private final String previousStatus;
    private final String newStatus;
    
    // Operation details
    private final String operation;
    private final String operationDescription;
    private final String operationBy;
    private final String reason;
    
    // Timestamps
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private final LocalDateTime occurredAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private final LocalDateTime publishedAt;
    
    // Publishing metadata
    private final String publishedBy;
    private final String messageHash;
    private final String priority;
    
    // Derived calculations
    public Integer getQuantityChange() {
        return newQuantity - previousQuantity;
    }
    
    public BigDecimal getPriceChange() {
        return newPrice.subtract(previousPrice);
    }
    
    public boolean isQuantityIncreased() {
        return getQuantityChange() > 0;
    }
    
    public boolean isPriceIncreased() {
        return getPriceChange().compareTo(BigDecimal.ZERO) > 0;
    }
    
    public boolean isSignificantQuantityChange() {
        return Math.abs(getQuantityChange()) >= 10;
    }
    
    public boolean isSignificantPriceChange() {
        return getPriceChange().abs().compareTo(new BigDecimal("10")) >= 0;
    }
}
