package com.kbnt.logproducer.domain.model;

import lombok.Value;

/**
 * Value Object para representar o nível de log
 */
@Value
public class LogLevel {
    
    String value;
    
    public static LogLevel of(String level) {
        return new LogLevel(level.toUpperCase());
    }
    
    public static LogLevel trace() { return new LogLevel("TRACE"); }
    public static LogLevel debug() { return new LogLevel("DEBUG"); }
    public static LogLevel info() { return new LogLevel("INFO"); }
    public static LogLevel warn() { return new LogLevel("WARN"); }
    public static LogLevel error() { return new LogLevel("ERROR"); }
    public static LogLevel fatal() { return new LogLevel("FATAL"); }
    
    public boolean isTrace() { return "TRACE".equals(value); }
    public boolean isDebug() { return "DEBUG".equals(value); }
    public boolean isInfo() { return "INFO".equals(value); }
    public boolean isWarn() { return "WARN".equals(value); }
    public boolean isError() { return "ERROR".equals(value); }
    public boolean isFatal() { return "FATAL".equals(value); }
    
    public int getPriority() {
        return switch (value) {
            case "TRACE" -> 0;
            case "DEBUG" -> 1;
            case "INFO" -> 2;
            case "WARN" -> 3;
            case "ERROR" -> 4;
            case "FATAL" -> 5;
            default -> 2; // default to INFO
        };
    }
    
    public boolean isValid() {
        return value != null && 
               ("TRACE".equals(value) || "DEBUG".equals(value) || 
                "INFO".equals(value) || "WARN".equals(value) || 
                "ERROR".equals(value) || "FATAL".equals(value));
    }
}
