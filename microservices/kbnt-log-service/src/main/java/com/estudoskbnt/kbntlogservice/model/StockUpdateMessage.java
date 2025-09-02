package com.estudoskbnt.kbntlogservice.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import java.time.LocalDateTime;

/**
 * Stock Update Message Model
 * Minimal attributes for inventory management across distribution centers and branches
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdateMessage {

    /**
     * Product/SKU identifier - Primary key
     */
    @NotBlank(message = "Product ID is required")
    private String productId;

    /**
     * Distribution center code
     */
    @NotBlank(message = "Distribution center is required")
    private String distributionCenter;

    /**
     * Branch/store code - can be same as distribution center for DC stock
     */
    @NotBlank(message = "Branch is required")
    private String branch;

    /**
     * Current stock quantity
     */
    @NotNull(message = "Quantity is required")
    @PositiveOrZero(message = "Quantity must be positive or zero")
    private Integer quantity;

    /**
     * Operation type: ADD, REMOVE, SET, TRANSFER
     */
    @NotBlank(message = "Operation type is required")
    private String operation;

    /**
     * Transaction timestamp
     */
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private LocalDateTime timestamp;

    /**
     * Transaction correlation ID for tracking
     */
    private String correlationId;

    /**
     * Source branch (for TRANSFER operations)
     */
    private String sourceBranch;

    /**
     * Reason code: SALE, PURCHASE, ADJUSTMENT, TRANSFER, RETURN
     */
    private String reasonCode;

    /**
     * Reference document (invoice, order, etc.)
     */
    private String referenceDocument;
}
