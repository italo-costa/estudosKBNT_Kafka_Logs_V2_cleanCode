package com.kbnt.logconsumer.domain.model;

import java.util.Objects;

/**
 * Value Object representando o nível de log
 */
public class LogLevel {
    
    private final String value;
    
    // Constantes para níveis padrão
    public static final LogLevel DEBUG = new LogLevel("DEBUG");
    public static final LogLevel INFO = new LogLevel("INFO");
    public static final LogLevel WARN = new LogLevel("WARN");
    public static final LogLevel ERROR = new LogLevel("ERROR");
    public static final LogLevel FATAL = new LogLevel("FATAL");
    
    public LogLevel(String value) {
        if (value == null || value.trim().isEmpty()) {
            throw new IllegalArgumentException("Valor do LogLevel não pode ser nulo ou vazio");
        }
        this.value = value.trim().toUpperCase();
    }
    
    /**
     * Cria um LogLevel a partir de uma string
     */
    public static LogLevel fromString(String level) {
        return new LogLevel(level);
    }
    
    public String getValue() {
        return value;
    }
    
    public boolean isDebug() {
        return "DEBUG".equals(value);
    }
    
    public boolean isInfo() {
        return "INFO".equals(value);
    }
    
    public boolean isWarn() {
        return "WARN".equals(value);
    }
    
    public boolean isError() {
        return "ERROR".equals(value);
    }
    
    public boolean isFatal() {
        return "FATAL".equals(value);
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof LogLevel)) return false;
        LogLevel logLevel = (LogLevel) o;
        return Objects.equals(value, logLevel.value);
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
