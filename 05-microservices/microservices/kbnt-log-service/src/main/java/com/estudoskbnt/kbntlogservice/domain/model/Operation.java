package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Operation - Stock operation type
 */
public class Operation {
  private String type;
  private String description;

  // Constructors
  public Operation() {}

  public Operation(String type, String description) {
    this.type = type;
    this.description = description;
  }

  // Factory methods
  public static Operation of(String type) {
    return new Operation(type, null);
  }

  public static Operation of(String type, String description) {
    if (type == null || type.isBlank()) {
      throw new IllegalArgumentException("Operation type cannot be null or empty");
    }
    return new Operation(type.toUpperCase(), description);
  }

  // Getters
  public String getType() {
    return type;
  }

  public String getDescription() {
    return description;
  }

  // Setters
  public void setType(String type) {
    this.type = type;
  }

  public void setDescription(String description) {
    this.description = description;
  }

  // Business methods
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
