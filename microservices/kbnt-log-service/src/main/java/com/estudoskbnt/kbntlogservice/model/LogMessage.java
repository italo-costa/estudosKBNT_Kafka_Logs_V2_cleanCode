package com.estudoskbnt.kbntlogservice.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * Unified Log Message Model for AMQ Streams
 * Supports all log types: application, error, audit, financial
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LogMessage {

    /**
     * Log level: DEBUG, INFO, WARN, ERROR, FATAL
     */
    @NotBlank(message = "Log level is required")
    private String level;

    /**
     * Log message content
     */
    @NotBlank(message = "Log message is required")
    private String message;

    /**
     * Service/application name that generated the log
     */
    private String serviceName;

    /**
     * Log category: APPLICATION, ERROR, AUDIT, FINANCIAL
     */
    private String category;

    /**
     * Timestamp when the log was generated
     */
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private LocalDateTime timestamp;

    /**
     * Correlation ID for request tracing
     */
    private String correlationId;

    /**
     * User ID associated with the log (for audit trails)
     */
    private String userId;

    /**
     * Session ID (for web applications)
     */
    private String sessionId;

    /**
     * Request ID for API calls
     */
    private String requestId;

    /**
     * Exception information (for error logs)
     */
    private ExceptionInfo exception;

    /**
     * Additional metadata as key-value pairs
     */
    private Map<String, Object> metadata;

    /**
     * Environment: dev, test, prod
     */
    private String environment;

    /**
     * Application version
     */
    private String version;

    /**
     * Host/pod name where the log originated
     */
    private String hostname;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExceptionInfo {
        
        /**
         * Exception class name
         */
        private String className;
        
        /**
         * Exception message
         */
        private String message;
        
        /**
         * Stack trace
         */
        private String stackTrace;
        
        /**
         * Root cause exception
         */
        private ExceptionInfo cause;
    }
}
