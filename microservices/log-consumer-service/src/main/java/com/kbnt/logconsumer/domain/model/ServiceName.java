package com.kbnt.logconsumer.domain.model;

import java.util.Objects;

/**
 * Value Object representando o nome de um serviço
 */
public class ServiceName {
    
    private final String value;
    
    public ServiceName(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Nome do serviço não pode ser nulo ou vazio");
        }
        
        String trimmedValue = value.trim();
        if (trimmedValue.length() > 100) {
            throw new IllegalArgumentException("Nome do serviço não pode exceder 100 caracteres");
        }
        
        if (!trimmedValue.matches("^[a-zA-Z0-9-_.]+$")) {
            throw new IllegalArgumentException("Nome do serviço deve conter apenas letras, números, hífens, sublinhados e pontos");
        }
        
        this.value = trimmedValue;
    }
    
    public String getValue() {
        return value;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ServiceName)) return false;
        ServiceName that = (ServiceName) o;
        return Objects.equals(value, that.value);
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
