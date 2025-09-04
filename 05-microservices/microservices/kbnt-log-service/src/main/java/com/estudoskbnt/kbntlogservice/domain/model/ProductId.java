package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Product ID - Product identifier
 */
public class ProductId {
  private String value;

  // Constructors
  public ProductId() {}

  public ProductId(String value) {
    this.value = value;
  }

  // Factory methods
  public static ProductId of(String value) {
    if (value == null || value.isBlank()) {
      throw new IllegalArgumentException("Product ID cannot be null or empty");
    }
    return new ProductId(value);
  }

  // Getters
  public String getValue() {
    return value;
  }

  // Setters
  public void setValue(String value) {
    this.value = value;
  }
}
