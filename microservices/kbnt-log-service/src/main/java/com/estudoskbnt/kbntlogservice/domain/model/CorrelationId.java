package com.estudoskbnt.kbntlogservice.domain.model;

import java.util.UUID;

/**
 * Correlation ID - Request tracking identifier
 */
public class CorrelationId {
  private String value;

  // Constructors
  public CorrelationId() {}

  public CorrelationId(String value) {
    this.value = value;
  }

  // Factory methods
  public static CorrelationId generate() {
    return new CorrelationId(UUID.randomUUID().toString());
  }

  public static CorrelationId of(String value) {
    return new CorrelationId(value != null ? value : UUID.randomUUID().toString());
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
