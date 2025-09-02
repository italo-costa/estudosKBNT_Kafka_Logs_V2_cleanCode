package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Distribution Center - Location identifier
 */
public class DistributionCenter {
  private String code;
  private String name;

  // Constructors
  public DistributionCenter() {}

  public DistributionCenter(String code, String name) {
    this.code = code;
    this.name = name;
  }

  // Factory methods
  public static DistributionCenter of(String code) {
    return new DistributionCenter(code, null);
  }

  public static DistributionCenter of(String code, String name) {
    if (code == null || code.isBlank()) {
      throw new IllegalArgumentException("Distribution center code cannot be null or empty");
    }
    return new DistributionCenter(code, name);
  }

  // Getters
  public String getCode() {
    return code;
  }

  public String getName() {
    return name;
  }

  // Setters
  public void setCode(String code) {
    this.code = code;
  }

  public void setName(String name) {
    this.name = name;
  }
}
