package com.estudoskbnt.consumer.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Stock Update Message DTO
 * 
 * Represents the stock update message consumed from Kafka AMQ Streams.
 * This matches the format produced by Microservice A.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdateMessage {
    
    /**
     * Unique correlation ID for request tracing
     */
    @NotBlank(message = "Correlation ID cannot be blank")
    @JsonProperty("correlation_id")
    private String correlationId;
    
    /**
     * Product identifier
     */
    @NotBlank(message = "Product ID cannot be blank")
    @Size(min = 3, max = 50, message = "Product ID must be between 3 and 50 characters")
    @JsonProperty("product_id")
    private String productId;
    
    /**
     * Stock quantity to update
     */
    @NotNull(message = "Quantity cannot be null")
    @Min(value = 0, message = "Quantity must be non-negative")
    @Max(value = 99999, message = "Quantity cannot exceed 99999")
    @JsonProperty("quantity")
    private Integer quantity;
    
    /**
     * Product price per unit
     */
    @NotNull(message = "Price cannot be null")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0.01")
    @DecimalMax(value = "99999.99", message = "Price cannot exceed 99999.99")
    @JsonProperty("price")
    private BigDecimal price;
    
    /**
     * Update operation type
     */
    @NotBlank(message = "Operation cannot be blank")
    @Pattern(regexp = "ADD|REMOVE|SET|ADJUST", message = "Operation must be ADD, REMOVE, SET, or ADJUST")
    @JsonProperty("operation")
    private String operation;
    
    /**
     * Product category
     */
    @Size(max = 100, message = "Category cannot exceed 100 characters")
    @JsonProperty("category")
    private String category;
    
    /**
     * Supplier information
     */
    @Size(max = 100, message = "Supplier cannot exceed 100 characters")
    @JsonProperty("supplier")
    private String supplier;
    
    /**
     * Warehouse location
     */
    @Size(max = 50, message = "Location cannot exceed 50 characters")
    @JsonProperty("location")
    private String location;
    
    /**
     * Message publication timestamp
     */
    @JsonProperty("published_at")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss.SSS")
    private LocalDateTime publishedAt;
    
    /**
     * SHA-256 hash of the message content for verification
     */
    @NotBlank(message = "Hash cannot be blank")
    @Size(min = 64, max = 64, message = "Hash must be exactly 64 characters (SHA-256)")
    @JsonProperty("hash")
    private String hash;
    
    /**
     * Priority level for processing
     */
    @Pattern(regexp = "LOW|NORMAL|HIGH|CRITICAL", message = "Priority must be LOW, NORMAL, HIGH, or CRITICAL")
    @JsonProperty("priority")
    private String priority;
    
    /**
     * Processing deadline
     */
    @JsonProperty("deadline")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss.SSS")
    private LocalDateTime deadline;
    
    /**
     * Calculate the total value of the stock update
     * 
     * @return Total value (quantity * price)
     */
    public BigDecimal getTotalValue() {
        if (quantity != null && price != null) {
            return price.multiply(BigDecimal.valueOf(quantity));
        }
        return BigDecimal.ZERO;
    }
    
    /**
     * Check if the message has expired based on deadline
     * 
     * @return true if the message has expired
     */
    public boolean isExpired() {
        if (deadline == null) {
            return false;
        }
        return LocalDateTime.now().isAfter(deadline);
    }
    
    /**
     * Get priority as enum for easier comparison
     */
    public Priority getPriorityEnum() {
        try {
            return Priority.valueOf(priority != null ? priority.toUpperCase() : "NORMAL");
        } catch (IllegalArgumentException e) {
            return Priority.NORMAL;
        }
    }
    
    /**
     * Priority enumeration
     */
    public enum Priority {
        LOW(1),
        NORMAL(2), 
        HIGH(3),
        CRITICAL(4);
        
        private final int level;
        
        Priority(int level) {
            this.level = level;
        }
        
        public int getLevel() {
            return level;
        }
    }
}
