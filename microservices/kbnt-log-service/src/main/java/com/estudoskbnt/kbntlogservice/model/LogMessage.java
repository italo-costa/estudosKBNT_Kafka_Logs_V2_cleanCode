package com.estudoskbnt.kbntlogservice.model;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * Unified Log Message Model for AMQ Streams
 * Supports all log types: application, error, audit, financial
 */
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

    // Constructors
    public LogMessage() {}

    public LogMessage(String level, String message, String serviceName, String category, 
                     LocalDateTime timestamp, String correlationId, String userId, 
                     String sessionId, String requestId, ExceptionInfo exception, 
                     Map<String, Object> metadata, String environment, String version, 
                     String hostname) {
        this.level = level;
        this.message = message;
        this.serviceName = serviceName;
        this.category = category;
        this.timestamp = timestamp;
        this.correlationId = correlationId;
        this.userId = userId;
        this.sessionId = sessionId;
        this.requestId = requestId;
        this.exception = exception;
        this.metadata = metadata;
        this.environment = environment;
        this.version = version;
        this.hostname = hostname;
    }

    // Getters
    public String getLevel() { return level; }
    public String getMessage() { return message; }
    public String getServiceName() { return serviceName; }
    public String getCategory() { return category; }
    public LocalDateTime getTimestamp() { return timestamp; }
    public String getCorrelationId() { return correlationId; }
    public String getUserId() { return userId; }
    public String getSessionId() { return sessionId; }
    public String getRequestId() { return requestId; }
    public ExceptionInfo getException() { return exception; }
    public Map<String, Object> getMetadata() { return metadata; }
    public String getEnvironment() { return environment; }
    public String getVersion() { return version; }
    public String getHostname() { return hostname; }

    // Setters
    public void setLevel(String level) { this.level = level; }
    public void setMessage(String message) { this.message = message; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }
    public void setCategory(String category) { this.category = category; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
    public void setCorrelationId(String correlationId) { this.correlationId = correlationId; }
    public void setUserId(String userId) { this.userId = userId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }
    public void setException(ExceptionInfo exception) { this.exception = exception; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
    public void setEnvironment(String environment) { this.environment = environment; }
    public void setVersion(String version) { this.version = version; }
    public void setHostname(String hostname) { this.hostname = hostname; }

    // Builder pattern
    public static LogMessageBuilder builder() {
        return new LogMessageBuilder();
    }

    public static class LogMessageBuilder {
        private String level;
        private String message;
        private String serviceName;
        private String category;
        private LocalDateTime timestamp;
        private String correlationId;
        private String userId;
        private String sessionId;
        private String requestId;
        private ExceptionInfo exception;
        private Map<String, Object> metadata;
        private String environment;
        private String version;
        private String hostname;

        public LogMessageBuilder level(String level) { this.level = level; return this; }
        public LogMessageBuilder message(String message) { this.message = message; return this; }
        public LogMessageBuilder serviceName(String serviceName) { this.serviceName = serviceName; return this; }
        public LogMessageBuilder category(String category) { this.category = category; return this; }
        public LogMessageBuilder timestamp(LocalDateTime timestamp) { this.timestamp = timestamp; return this; }
        public LogMessageBuilder correlationId(String correlationId) { this.correlationId = correlationId; return this; }
        public LogMessageBuilder userId(String userId) { this.userId = userId; return this; }
        public LogMessageBuilder sessionId(String sessionId) { this.sessionId = sessionId; return this; }
        public LogMessageBuilder requestId(String requestId) { this.requestId = requestId; return this; }
        public LogMessageBuilder exception(ExceptionInfo exception) { this.exception = exception; return this; }
        public LogMessageBuilder metadata(Map<String, Object> metadata) { this.metadata = metadata; return this; }
        public LogMessageBuilder environment(String environment) { this.environment = environment; return this; }
        public LogMessageBuilder version(String version) { this.version = version; return this; }
        public LogMessageBuilder hostname(String hostname) { this.hostname = hostname; return this; }

        public LogMessage build() {
            return new LogMessage(level, message, serviceName, category, timestamp, correlationId,
                                userId, sessionId, requestId, exception, metadata, environment, version, hostname);
        }
    }

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

        // Constructors
        public ExceptionInfo() {}

        public ExceptionInfo(String className, String message, String stackTrace, ExceptionInfo cause) {
            this.className = className;
            this.message = message;
            this.stackTrace = stackTrace;
            this.cause = cause;
        }

        // Getters
        public String getClassName() { return className; }
        public String getMessage() { return message; }
        public String getStackTrace() { return stackTrace; }
        public ExceptionInfo getCause() { return cause; }

        // Setters
        public void setClassName(String className) { this.className = className; }
        public void setMessage(String message) { this.message = message; }
        public void setStackTrace(String stackTrace) { this.stackTrace = stackTrace; }
        public void setCause(ExceptionInfo cause) { this.cause = cause; }
    }
}
