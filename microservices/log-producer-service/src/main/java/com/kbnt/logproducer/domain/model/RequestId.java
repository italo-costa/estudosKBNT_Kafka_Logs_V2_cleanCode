package com.kbnt.logproducer.domain.model;

import lombok.Value;

import java.util.UUID;

/**
 * Value Object para representar um Request ID
 */
@Value
public class RequestId {
    
    String value;
    
    public static RequestId of(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("RequestId cannot be null or empty");
        }
        return new RequestId(value.trim());
    }
    
    public static RequestId generate() {
        return new RequestId("req-" + UUID.randomUUID().toString());
    }
    
    public boolean isValid() {
        return value != null && !value.trim().isEmpty();
    }
}
