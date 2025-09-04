package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Quantity - Stock quantity value object
 */
public class Quantity {
  private Integer value;

  // Constructors
  public Quantity() {}

  public Quantity(Integer value) {
    this.value = value;
  }

  // Factory methods
  public static Quantity of(Integer value) {
    if (value == null || value < 0) {
      throw new IllegalArgumentException("Quantity must be positive or zero");
    }
    return new Quantity(value);
  }

  // Getters
  public Integer getValue() {
    return value;
  }

  // Setters
  public void setValue(Integer value) {
    this.value = value;
  }

  // Business methods
  public boolean isZero() {
    return value == 0;
  }

  public boolean isPositive() {
    return value > 0;
  }
}
