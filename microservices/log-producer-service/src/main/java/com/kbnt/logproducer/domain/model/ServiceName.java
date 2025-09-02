package com.kbnt.logproducer.domain.model;

import lombok.Value;

/**
 * Value Object para representar o nome de um serviço
 */
@Value
public class ServiceName {
    
    String value;
    
    public static ServiceName of(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("ServiceName cannot be null or empty");
        }
        return new ServiceName(value.trim().toLowerCase());
    }
    
    public boolean isValid() {
        return value != null && 
               !value.trim().isEmpty() && 
               value.matches("^[a-z0-9-]+$"); // apenas letras minúsculas, números e hífen
    }
}
