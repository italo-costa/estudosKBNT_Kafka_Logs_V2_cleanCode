package com.kbnt.logproducer.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LogEntry {
    
    @NotBlank(message = "Service name is required")
    private String service;
    
    @NotNull(message = "Log level is required")
    @Pattern(regexp = "TRACE|DEBUG|INFO|WARN|ERROR|FATAL", message = "Invalid log level")
    private String level;
    
    @NotBlank(message = "Message is required")
    private String message;
    
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private Instant timestamp;
    
    private String host;
    private String environment;
    private String requestId;
    private String userId;
    private String sessionId;
    private String transactionId;
    
    // Campos específicos por tipo de log
    private String httpMethod;
    private String endpoint;
    private Integer statusCode;
    private Long responseTimeMs;
    private Double amount;
    private String itemId;
    private Integer currentStock;
    
    // Campos adicionais flexíveis
    private Map<String, Object> additionalFields;
    
    // Campos de contexto
    private String correlationId;
    private String traceId;
    private String spanId;
    
    public static LogEntry createInfo(String service, String message) {
        return LogEntry.builder()
                .service(service)
                .level("INFO")
                .message(message)
                .timestamp(Instant.now())
                .build();
    }
    
    public static LogEntry createError(String service, String message) {
        return LogEntry.builder()
                .service(service)
                .level("ERROR")
                .message(message)
                .timestamp(Instant.now())
                .build();
    }
    
    public static LogEntry createWarn(String service, String message) {
        return LogEntry.builder()
                .service(service)
                .level("WARN")
                .message(message)
                .timestamp(Instant.now())
                .build();
    }
}
