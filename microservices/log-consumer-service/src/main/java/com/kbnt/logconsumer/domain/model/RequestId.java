package com.kbnt.logconsumer.domain.model;

import java.util.Objects;
import java.util.regex.Pattern;

/**
 * Value Object representando um ID de requisição
 */
public class RequestId {
    
    private static final Pattern UUID_PATTERN = 
        Pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
    
    private final String value;
    
    public RequestId(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("RequestId não pode ser nulo ou vazio");
        }
        
        String trimmedValue = value.trim();
        if (!UUID_PATTERN.matcher(trimmedValue).matches()) {
            throw new IllegalArgumentException("RequestId deve seguir o formato UUID");
        }
        
        this.value = trimmedValue;
    }
    
    public String getValue() {
        return value;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof RequestId)) return false;
        RequestId requestId = (RequestId) o;
        return Objects.equals(value, requestId.value);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(value);
    }
    
    @Override
    public String toString() {
        return value;
    }
}
