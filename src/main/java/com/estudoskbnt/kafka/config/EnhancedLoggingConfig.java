package com.estudoskbnt.kafka.config;

import org.slf4j.MDC;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.encoder.PatternLayoutEncoder;
import ch.qos.logback.core.rolling.RollingFileAppender;
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy;
import org.slf4j.LoggerFactory;

import javax.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Enhanced Logging Configuration for Microservice A (Producer)
 * 
 * Provides structured logging with component identification, owner tracking,
 * and performance metrics using MDC (Mapped Diagnostic Context).
 */
@Configuration
public class EnhancedLoggingConfig {

    private static final String SERVICE_COMPONENT = "MICROSERVICE-A";
    private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");

    @PostConstruct
    public void configureLogging() {
        LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();
        
        // Create enhanced pattern with MDC context
        String pattern = "%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level [%X{owner}] [%X{component}] [%X{messageId}] [%X{topic}] %logger{36} - %msg%n";
        
        // Configure rolling file appender for component-specific logging
        RollingFileAppender<ch.qos.logback.classic.spi.ILoggingEvent> fileAppender = 
            new RollingFileAppender<>();
        fileAppender.setContext(loggerContext);
        fileAppender.setName("MICROSERVICE-A-FILE");
        fileAppender.setFile("logs/microservice-a.log");
        
        // Configure time-based rolling policy
        TimeBasedRollingPolicy<ch.qos.logback.classic.spi.ILoggingEvent> rollingPolicy = 
            new TimeBasedRollingPolicy<>();
        rollingPolicy.setContext(loggerContext);
        rollingPolicy.setParent(fileAppender);
        rollingPolicy.setFileNamePattern("logs/microservice-a.%d{yyyy-MM-dd}.%i.log");
        rollingPolicy.setMaxHistory(30);
        
        // Configure pattern encoder
        PatternLayoutEncoder encoder = new PatternLayoutEncoder();
        encoder.setContext(loggerContext);
        encoder.setPattern(pattern);
        encoder.start();
        
        fileAppender.setEncoder(encoder);
        fileAppender.setRollingPolicy(rollingPolicy);
        rollingPolicy.start();
        fileAppender.start();
        
        // Add appender to root logger
        Logger rootLogger = loggerContext.getLogger(Logger.ROOT_LOGGER_NAME);
        rootLogger.addAppender(fileAppender);
        
        LoggerFactory.getLogger(getClass()).info("Enhanced logging configured for {}", SERVICE_COMPONENT);
    }

    /**
     * Logging utility methods with MDC context management
     */
    @Component
    public static class LoggingUtils {
        
        /**
         * Set service context information in MDC
         * 
         * @param component Component identifier (MICROSERVICE-A, KAFKA_PRODUCER, etc.)
         * @param owner Process owner/class name
         */
        public static void setServiceContext(String component, String owner) {
            MDC.put("component", component);
            MDC.put("owner", owner);
            MDC.put("timestamp", LocalDateTime.now().format(TIMESTAMP_FORMAT));
        }
        
        /**
         * Set message-specific context in MDC
         * 
         * @param messageId Message correlation ID or unique identifier
         * @param topic Kafka topic name
         */
        public static void setMessageContext(String messageId, String topic) {
            if (messageId != null) {
                MDC.put("messageId", messageId);
            }
            if (topic != null) {
                MDC.put("topic", topic);
            }
        }
        
        /**
         * Log component-specific information
         * 
         * @param componentType Type of component (API_CALL, KAFKA_PUBLISH, DATABASE_OPERATION, etc.)
         * @param message Log message
         */
        public static void logComponentInfo(String componentType, String message) {
            MDC.put("componentType", componentType);
            LoggerFactory.getLogger("ComponentLogger").info("[{}] {}", componentType, message);
        }
        
        /**
         * Log performance metrics
         * 
         * @param operation Operation name
         * @param durationMs Duration in milliseconds
         */
        public static void logPerformanceMetrics(String operation, long durationMs) {
            MDC.put("operation", operation);
            MDC.put("duration", String.valueOf(durationMs));
            
            String performanceLevel = durationMs > 5000 ? "SLOW" : durationMs > 1000 ? "NORMAL" : "FAST";
            MDC.put("performanceLevel", performanceLevel);
            
            LoggerFactory.getLogger("PerformanceLogger").info(
                "[PERFORMANCE] {} completed in {}ms [{}]", operation, durationMs, performanceLevel);
        }
        
        /**
         * Log errors with context
         * 
         * @param errorType Type of error (VALIDATION_ERROR, KAFKA_ERROR, etc.)
         * @param message Error message
         * @param exception Exception (if any)
         * @param context Additional context information
         */
        public static void logError(String errorType, String message, Throwable exception, String context) {
            MDC.put("errorType", errorType);
            if (context != null) {
                MDC.put("errorContext", context);
            }
            
            if (exception != null) {
                LoggerFactory.getLogger("ErrorLogger").error(
                    "[ERROR:{}] {} - Context: {}", errorType, message, context, exception);
            } else {
                LoggerFactory.getLogger("ErrorLogger").error(
                    "[ERROR:{}] {} - Context: {}", errorType, message, context);
            }
        }
        
        /**
         * Log Kafka-specific operations
         * 
         * @param operation Kafka operation (PUBLISH, ACKNOWLEDGE, etc.)
         * @param topic Topic name
         * @param partition Partition (if applicable)
         * @param message Log message
         */
        public static void logKafkaOperation(String operation, String topic, Integer partition, String message) {
            MDC.put("kafkaOperation", operation);
            MDC.put("topic", topic);
            if (partition != null) {
                MDC.put("partition", String.valueOf(partition));
            }
            
            LoggerFactory.getLogger("KafkaLogger").info(
                "[KAFKA:{}] Topic: {} {} - {}", operation, topic, 
                partition != null ? "Partition: " + partition : "", message);
        }
        
        /**
         * Log API call operations
         * 
         * @param method HTTP method
         * @param endpoint API endpoint
         * @param statusCode Response status code
         * @param durationMs Request duration
         */
        public static void logApiCall(String method, String endpoint, int statusCode, long durationMs) {
            MDC.put("httpMethod", method);
            MDC.put("endpoint", endpoint);
            MDC.put("statusCode", String.valueOf(statusCode));
            MDC.put("duration", String.valueOf(durationMs));
            
            String level = statusCode >= 400 ? "ERROR" : statusCode >= 300 ? "WARN" : "INFO";
            
            LoggerFactory.getLogger("ApiLogger").info(
                "[API_CALL] {} {} -> {} ({}ms) [{}]", method, endpoint, statusCode, durationMs, level);
        }
        
        /**
         * Clear all MDC context
         */
        public static void clearContext() {
            MDC.clear();
        }
        
        /**
         * Clear specific MDC key
         * 
         * @param key Key to remove from MDC
         */
        public static void clearContext(String key) {
            MDC.remove(key);
        }
        
        /**
         * Log workflow step information
         * 
         * @param step Workflow step name
         * @param status Step status (STARTED, COMPLETED, FAILED)
         * @param details Additional details
         */
        public static void logWorkflowStep(String step, String status, String details) {
            MDC.put("workflowStep", step);
            MDC.put("stepStatus", status);
            
            LoggerFactory.getLogger("WorkflowLogger").info(
                "[WORKFLOW:{}] {} - Status: {} - {}", SERVICE_COMPONENT, step, status, details);
        }
        
        /**
         * Log business logic operations
         * 
         * @param businessOperation Business operation name
         * @param entity Entity being processed
         * @param result Operation result
         */
        public static void logBusinessOperation(String businessOperation, String entity, String result) {
            MDC.put("businessOperation", businessOperation);
            MDC.put("entity", entity);
            MDC.put("result", result);
            
            LoggerFactory.getLogger("BusinessLogger").info(
                "[BUSINESS] {} on {} -> {}", businessOperation, entity, result);
        }
    }
}
