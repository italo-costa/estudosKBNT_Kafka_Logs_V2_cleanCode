package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Branch - Branch/Store identifier
 */
public class Branch {
  private String code;
  private String name;

  // Constructors
  public Branch() {}

  public Branch(String code, String name) {
    this.code = code;
    this.name = name;
  }

  // Factory methods
  public static Branch of(String code) {
    return new Branch(code, null);
  }

  public static Branch of(String code, String name) {
    if (code == null || code.isBlank()) {
      throw new IllegalArgumentException("Branch code cannot be null or empty");
    }
    return new Branch(code, name);
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
