package com.estudoskbnt.kbntlogservice.domain.model;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * Reference Document - External document reference
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ReferenceDocument {
  private String number;
  private String type;

  public static ReferenceDocument of(String number) {
    return new ReferenceDocument(number, null);
  }

  public static ReferenceDocument of(String number, String type) {
    return new ReferenceDocument(number, type);
  }
}
