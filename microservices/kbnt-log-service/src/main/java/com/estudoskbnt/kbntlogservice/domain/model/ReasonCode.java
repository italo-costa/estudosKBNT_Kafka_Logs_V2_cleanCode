package com.estudoskbnt.kbntlogservice.domain.model;

/**
 * Reason Code - Business reason for operation
 */
public class ReasonCode {
  private String code;
  private String description;

  // Constructors
  public ReasonCode() {}

  public ReasonCode(String code, String description) {
    this.code = code;
    this.description = description;
  }

  // Getters
  public String getCode() { return code; }
  public String getDescription() { return description; }

  // Factory methods
  public static ReasonCode of(String code) {
    return new ReasonCode(code, null);
  }

  public static ReasonCode of(String code, String description) {
    return new ReasonCode(code, description);
  }
}
