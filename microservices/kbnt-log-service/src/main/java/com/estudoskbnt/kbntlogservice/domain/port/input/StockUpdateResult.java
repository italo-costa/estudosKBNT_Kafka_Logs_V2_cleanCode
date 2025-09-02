package com.estudoskbnt.kbntlogservice.domain.port.input;

import com.estudoskbnt.kbntlogservice.domain.model.*;
import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;

/**
 * Stock Update Result
 * 
 * Represents the result of a stock update operation.
 */
public interface StockUpdateResult {
  boolean isSuccess();
  String getMessage();
  StockUpdateId getStockUpdateId();
  ValidationResult getValidationResult();
  StockUpdateEvent getEvent();
  ValidationResult getValidation();
  
  /**
   * Success result implementation
   */
  class Success implements StockUpdateResult {
    private final StockUpdateId stockUpdateId;
    private final String message;
    private final StockUpdateEvent event;
    
    public Success(StockUpdateId stockUpdateId, String message) {
      this.stockUpdateId = stockUpdateId;
      this.message = message;
      this.event = null;
    }
    
    public Success(StockUpdateId stockUpdateId, StockUpdateEvent event) {
      this.stockUpdateId = stockUpdateId;
      this.message = "Success";
      this.event = event;
    }
    
    @Override
    public boolean isSuccess() {
      return true;
    }
    
    @Override
    public String getMessage() {
      return message;
    }
    
    @Override
    public StockUpdateId getStockUpdateId() {
      return stockUpdateId;
    }
    
    @Override
    public ValidationResult getValidationResult() {
      return ValidationResult.success();
    }
    
    @Override
    public StockUpdateEvent getEvent() {
      return event;
    }
    
    @Override
    public ValidationResult getValidation() {
      return ValidationResult.success();
    }
  }
  
  /**
   * Failure result implementation
   */
  class Failure implements StockUpdateResult {
    private final String message;
    private final ValidationResult validationResult;
    
    public Failure(String message, ValidationResult validationResult) {
      this.message = message;
      this.validationResult = validationResult;
    }
    
    public Failure(String message) {
      this.message = message;
      this.validationResult = ValidationResult.error(message);
    }
    
    @Override
    public boolean isSuccess() {
      return false;
    }
    
    @Override
    public String getMessage() {
      return message;
    }
    
    @Override
    public StockUpdateId getStockUpdateId() {
      return null;
    }
    
    @Override
    public ValidationResult getValidationResult() {
      return validationResult;
    }
    
    @Override
    public StockUpdateEvent getEvent() {
      return null;
    }
    
    @Override
    public ValidationResult getValidation() {
      return validationResult;
    }
  }
  
  // Factory methods
  static StockUpdateResult success(StockUpdateId stockUpdateId, String message) {
    return new Success(stockUpdateId, message);
  }
  
  static StockUpdateResult success(StockUpdateId stockUpdateId, StockUpdateEvent event) {
    return new Success(stockUpdateId, event);
  }
  
  static StockUpdateResult failure(String message) {
    return new Failure(message);
  }
  
  static StockUpdateResult failure(String message, ValidationResult validationResult) {
    return new Failure(message, validationResult);
  }
}
