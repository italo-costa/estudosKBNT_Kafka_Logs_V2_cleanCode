package com.estudoskbnt.kbntlogservice.infrastructure.adapter.input.rest;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Pattern;

/**
 * Stock Update Request DTO
 * 
 * Data Transfer Object for REST API stock update requests.
 * Represents the input format for stock operations via HTTP.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdateRequest {

    @NotBlank(message = "Product ID is required")
    @JsonProperty("productId")
    private String productId;

    @NotBlank(message = "Distribution center is required")
    @JsonProperty("distributionCenter")
    private String distributionCenter;

    @NotBlank(message = "Branch is required")
    @JsonProperty("branch")
    private String branch;

    @NotNull(message = "Quantity is required")
    @Positive(message = "Quantity must be positive")
    @JsonProperty("quantity")
    private Integer quantity;

    @NotBlank(message = "Operation is required")
    @Pattern(regexp = "ADD|REMOVE|TRANSFER|RESERVE|RELEASE", 
            message = "Operation must be one of: ADD, REMOVE, TRANSFER, RESERVE, RELEASE")
    @JsonProperty("operation")
    private String operation;

    @JsonProperty("reasonCode")
    private String reasonCode;

    @JsonProperty("referenceDocument")
    private String referenceDocument;

    @JsonProperty("sourceBranch")
    private String sourceBranch; // Para operações de TRANSFER

    @JsonProperty("targetBranch")
    private String targetBranch; // Para operações de TRANSFER
}
