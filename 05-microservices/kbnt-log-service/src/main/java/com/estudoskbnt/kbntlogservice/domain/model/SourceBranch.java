package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Source Branch - For transfer operations
 */
public class SourceBranch {
  private String code;

  // Constructors
  public SourceBranch() {}

  public SourceBranch(String code) {
    this.code = code;
  }

  // Factory methods
  public static SourceBranch of(String code) {
    return new SourceBranch(code);
  }

  // Getters
  public String getCode() {
    return code;
  }

  // Setters
  public void setCode(String code) {
    this.code = code;
  }
}
