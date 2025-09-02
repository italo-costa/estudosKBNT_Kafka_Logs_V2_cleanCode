package com.estudoskbnt.kbntlogservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * Validation Result Value Object
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidationResult {
    private boolean valid;
    private String errorCode;
    private String errorMessage;
    
    public static ValidationResult success() {
        return ValidationResult.builder()
                .valid(true)
                .build();
    }
    
    public static ValidationResult failed(String errorCode, String errorMessage) {
        return ValidationResult.builder()
                .valid(false)
                .errorCode(errorCode)
                .errorMessage(errorMessage)
                .build();
    }
    
    public boolean isValid() {
        return valid;
    }
    
    public boolean hasError() {
        return !valid;
    }
}

/**
 * Domain Exception for invalid stock updates
 */
class InvalidStockUpdateException extends RuntimeException {
    public InvalidStockUpdateException(String message) {
        super(message);
    }
}
