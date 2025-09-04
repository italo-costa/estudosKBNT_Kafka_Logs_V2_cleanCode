package com.estudoskbnt.kbntlogservice.domain.model;

import java.util.UUID;

/**
 * Stock Update ID - Domain identifier
 */
public class StockUpdateId {
  private String value;

  // Constructors
  public StockUpdateId() {}

  public StockUpdateId(String value) {
    this.value = value;
  }

  // Factory methods
  public static StockUpdateId generate() {
    return new StockUpdateId(UUID.randomUUID().toString());
  }

  public static StockUpdateId of(String value) {
    return new StockUpdateId(value);
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
