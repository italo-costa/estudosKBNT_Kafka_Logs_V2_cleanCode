package com.estudoskbnt.kbntlogservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Value Objects for Stock Update Domain
 */

/**
 * Stock Update ID - Domain identifier
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class StockUpdateId {
    private String value;
    
    public static StockUpdateId generate() {
        return new StockUpdateId(UUID.randomUUID().toString());
    }
    
    public static StockUpdateId of(String value) {
        return new StockUpdateId(value);
    }
}

/**
 * Product ID - Product identifier
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ProductId {
    private String value;
    
    public static ProductId of(String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Product ID cannot be null or empty");
        }
        return new ProductId(value);
    }
}

/**
 * Distribution Center - Location identifier
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class DistributionCenter {
    private String code;
    private String name;
    
    public static DistributionCenter of(String code) {
        return new DistributionCenter(code, null);
    }
    
    public static DistributionCenter of(String code, String name) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException("Distribution center code cannot be null or empty");
        }
        return new DistributionCenter(code, name);
    }
}

/**
 * Branch - Branch/Store identifier
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Branch {
    private String code;
    private String name;
    
    public static Branch of(String code) {
        return new Branch(code, null);
    }
    
    public static Branch of(String code, String name) {
        if (code == null || code.isBlank()) {
            throw new IllegalArgumentException("Branch code cannot be null or empty");
        }
        return new Branch(code, name);
    }
}

/**
 * Quantity - Stock quantity value object
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Quantity {
    private Integer value;
    
    public static Quantity of(Integer value) {
        if (value == null || value < 0) {
            throw new IllegalArgumentException("Quantity must be positive or zero");
        }
        return new Quantity(value);
    }
    
    public boolean isZero() {
        return value == 0;
    }
    
    public boolean isPositive() {
        return value > 0;
    }
}

/**
 * Operation - Stock operation type
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class Operation {
    private String type;
    private String description;
    
    public static Operation of(String type) {
        return new Operation(type, null);
    }
    
    public static Operation of(String type, String description) {
        if (type == null || type.isBlank()) {
            throw new IllegalArgumentException("Operation type cannot be null or empty");
        }
        return new Operation(type.toUpperCase(), description);
    }
    
    public boolean isAdd() {
        return "ADD".equals(type);
    }
    
    public boolean isRemove() {
        return "REMOVE".equals(type);
    }
    
    public boolean isSet() {
        return "SET".equals(type);
    }
    
    public boolean isTransfer() {
        return "TRANSFER".equals(type);
    }
    
    public boolean isReserve() {
        return "RESERVE".equals(type);
    }
    
    public boolean isRelease() {
        return "RELEASE".equals(type);
    }
}

/**
 * Correlation ID - Request tracking identifier
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class CorrelationId {
    private String value;
    
    public static CorrelationId generate() {
        return new CorrelationId(UUID.randomUUID().toString());
    }
    
    public static CorrelationId of(String value) {
        return new CorrelationId(value != null ? value : UUID.randomUUID().toString());
    }
}

/**
 * Source Branch - For transfer operations
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class SourceBranch {
    private String code;
    
    public static SourceBranch of(String code) {
        return new SourceBranch(code);
    }
}

/**
 * Reason Code - Business reason for operation
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ReasonCode {
    private String code;
    private String description;
    
    public static ReasonCode of(String code) {
        return new ReasonCode(code, null);
    }
    
    public static ReasonCode of(String code, String description) {
        return new ReasonCode(code, description);
    }
}

/**
 * Reference Document - External document reference
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ReferenceDocument {
    private String number;
    private String type;
    
    public static ReferenceDocument of(String number) {
        return new ReferenceDocument(number, null);
    }
    
    public static ReferenceDocument of(String number, String type) {
        return new ReferenceDocument(number, type);
    }
    
    public String getValue() {
        return number;
    }
}

/**
 * Stock Update Status - Processing status
 */
enum StockUpdateStatus {
    PENDING,
    PROCESSING,
    PROCESSED,
    FAILED,
    CANCELLED
}
