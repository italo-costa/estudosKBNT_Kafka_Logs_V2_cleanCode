package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Validation Result Value Object
 */
public class ValidationResult {
    private boolean valid;
    private String errorCode;
    private String errorMessage;
    
    // Constructors
    public ValidationResult() {}
    
    public ValidationResult(boolean valid, String errorCode, String errorMessage) {
        this.valid = valid;
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }
    
    // Getters
    public boolean isValid() { return valid; }
    public String getErrorCode() { return errorCode; }
    public String getErrorMessage() { return errorMessage; }
    public String getMessage() { return errorMessage; } // Alias for compatibility
    
    // Setters
    public void setValid(boolean valid) { this.valid = valid; }
    public void setErrorCode(String errorCode) { this.errorCode = errorCode; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
    
    // Factory methods
    public static ValidationResult success() {
        return new ValidationResult(true, null, null);
    }
    
    public static ValidationResult failed(String errorCode, String errorMessage) {
        return new ValidationResult(false, errorCode, errorMessage);
    }
    
    public static ValidationResult error(String errorMessage) {
        return new ValidationResult(false, "ERROR", errorMessage);
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
