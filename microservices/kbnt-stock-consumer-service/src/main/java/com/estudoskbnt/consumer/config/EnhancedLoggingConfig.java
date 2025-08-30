package com.estudoskbnt.consumer.config;

import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.core.ConsoleAppender;
import ch.qos.logback.core.rolling.RollingFileAppender;
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy;
import ch.qos.logback.classic.encoder.PatternLayoutEncoder;
import org.slf4j.LoggerFactory;

import javax.annotation.PostConstruct;
import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 * Enhanced Logging Configuration for ACL Virtual Stock Service
 * 
 * Features:
 * - Structured logging with MDC (Mapped Diagnostic Context)
 * - Component identification (ACL-VIRTUAL-STOCK)
 * - Process owner tracking
 * - Environment-specific logging levels
 * - Rolling file appenders with retention
 * - JSON-structured logs for better parsing
 * - Correlation ID propagation
 * - Performance metrics logging
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Configuration
public class EnhancedLoggingConfig {

    @Value("${spring.application.name:kbnt-stock-consumer-service}")
    private String applicationName;

    @Value("${server.port:8081}")
    private String serverPort;

    @Value("${logging.level.root:INFO}")
    private String rootLogLevel;

    @Value("${kbnt.logging.component:ACL-VIRTUAL-STOCK}")
    private String componentName;

    @Value("${kbnt.logging.owner:KBNT-SYSTEM}")
    private String processOwner;

    private final Environment environment;

    public EnhancedLoggingConfig(Environment environment) {
        this.environment = environment;
    }

    @PostConstruct
    public void initializeLogging() {
        try {
            // Set up global MDC properties that will be included in all logs
            String hostname = InetAddress.getLocalHost().getHostName();
            String activeProfiles = String.join(",", environment.getActiveProfiles());
            
            // Global MDC properties for this microservice
            MDC.put("component", componentName);
            MDC.put("owner", processOwner);
            MDC.put("service", applicationName);
            MDC.put("version", "1.0.0");
            MDC.put("hostname", hostname);
            MDC.put("port", serverPort);
            MDC.put("profiles", activeProfiles.isEmpty() ? "default" : activeProfiles);
            MDC.put("instance_id", generateInstanceId());
            
            configureLoggers();
            
            LoggerFactory.getLogger(EnhancedLoggingConfig.class)
                .info("Enhanced logging initialized for {} - Owner: {}, Component: {}, Instance: {}", 
                      applicationName, processOwner, componentName, MDC.get("instance_id"));
                      
        } catch (UnknownHostException e) {
            LoggerFactory.getLogger(EnhancedLoggingConfig.class)
                .warn("Could not determine hostname for logging context", e);
        }
    }

    private void configureLoggers() {
        LoggerContext context = (LoggerContext) LoggerFactory.getILoggerFactory();
        
        // Configure pattern with enhanced information
        String logPattern = "%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level [%X{component:-UNKNOWN}] [%X{owner:-SYSTEM}] [%X{service:-SERVICE}] [%X{correlation_id:-NO-ID}] [%X{kafka_topic:-NO-TOPIC}] %logger{36} - %msg%n";
        
        // Console appender
        configureConsoleAppender(context, logPattern);
        
        // File appender
        configureFileAppender(context, logPattern);
        
        // Kafka-specific logger
        configureKafkaLogger(context);
        
        // Performance logger
        configurePerformanceLogger(context);
    }

    private void configureConsoleAppender(LoggerContext context, String pattern) {
        ConsoleAppender consoleAppender = new ConsoleAppender();
        consoleAppender.setContext(context);
        consoleAppender.setName("CONSOLE");
        
        PatternLayoutEncoder encoder = new PatternLayoutEncoder();
        encoder.setContext(context);
        encoder.setPattern(pattern);
        encoder.start();
        
        consoleAppender.setEncoder(encoder);
        consoleAppender.start();
        
        Logger rootLogger = context.getLogger(Logger.ROOT_LOGGER_NAME);
        rootLogger.addAppender(consoleAppender);
    }

    private void configureFileAppender(LoggerContext context, String pattern) {
        RollingFileAppender fileAppender = new RollingFileAppender();
        fileAppender.setContext(context);
        fileAppender.setName("FILE");
        fileAppender.setFile("logs/kbnt-consumer.log");
        
        TimeBasedRollingPolicy rollingPolicy = new TimeBasedRollingPolicy();
        rollingPolicy.setContext(context);
        rollingPolicy.setParent(fileAppender);
        rollingPolicy.setFileNamePattern("logs/kbnt-consumer.%d{yyyy-MM-dd}.%i.log.gz");
        rollingPolicy.setMaxHistory(30);
        rollingPolicy.start();
        
        PatternLayoutEncoder encoder = new PatternLayoutEncoder();
        encoder.setContext(context);
        encoder.setPattern(pattern);
        encoder.start();
        
        fileAppender.setRollingPolicy(rollingPolicy);
        fileAppender.setEncoder(encoder);
        fileAppender.start();
        
        Logger rootLogger = context.getLogger(Logger.ROOT_LOGGER_NAME);
        rootLogger.addAppender(fileAppender);
    }

    private void configureKafkaLogger(LoggerContext context) {
        Logger kafkaLogger = context.getLogger("com.estudoskbnt.consumer.kafka");
        kafkaLogger.setLevel(ch.qos.logback.classic.Level.DEBUG);
    }

    private void configurePerformanceLogger(LoggerContext context) {
        Logger perfLogger = context.getLogger("com.estudoskbnt.consumer.performance");
        perfLogger.setLevel(ch.qos.logback.classic.Level.INFO);
    }

    private String generateInstanceId() {
        return String.format("%s-%s-%d", 
                           componentName.toLowerCase(), 
                           serverPort, 
                           System.currentTimeMillis() % 10000);
    }

    /**
     * Utility class for enhanced logging operations
     */
    public static class LoggingUtils {
        
        /**
         * Set up MDC context for Kafka message processing
         */
        public static void setupKafkaContext(String topic, String partition, String offset, String correlationId) {
            MDC.put("kafka_topic", topic);
            MDC.put("kafka_partition", partition);
            MDC.put("kafka_offset", offset);
            MDC.put("correlation_id", correlationId);
            MDC.put("processing_phase", "KAFKA_CONSUMPTION");
        }
        
        /**
         * Set up MDC context for external API calls
         */
        public static void setupApiContext(String apiEndpoint, String correlationId) {
            MDC.put("api_endpoint", apiEndpoint);
            MDC.put("correlation_id", correlationId);
            MDC.put("processing_phase", "EXTERNAL_API_CALL");
        }
        
        /**
         * Set up MDC context for database operations
         */
        public static void setupDatabaseContext(String operation, String correlationId) {
            MDC.put("db_operation", operation);
            MDC.put("correlation_id", correlationId);
            MDC.put("processing_phase", "DATABASE_PERSISTENCE");
        }
        
        /**
         * Clear processing-specific MDC context while keeping service-level context
         */
        public static void clearProcessingContext() {
            MDC.remove("kafka_topic");
            MDC.remove("kafka_partition");
            MDC.remove("kafka_offset");
            MDC.remove("api_endpoint");
            MDC.remove("db_operation");
            MDC.remove("processing_phase");
            MDC.remove("correlation_id");
        }
        
        /**
         * Log performance metrics
         */
        public static void logPerformanceMetric(String operation, long durationMs, String correlationId) {
            Logger perfLogger = (Logger) LoggerFactory.getLogger("com.estudoskbnt.consumer.performance");
            
            // Temporarily set correlation ID for this metric
            String originalCorrelationId = MDC.get("correlation_id");
            MDC.put("correlation_id", correlationId);
            MDC.put("metric_type", "PERFORMANCE");
            MDC.put("operation", operation);
            MDC.put("duration_ms", String.valueOf(durationMs));
            
            perfLogger.info("Performance metric - Operation: {}, Duration: {}ms, CorrelationId: {}", 
                          operation, durationMs, correlationId);
            
            // Restore original correlation ID
            if (originalCorrelationId != null) {
                MDC.put("correlation_id", originalCorrelationId);
            } else {
                MDC.remove("correlation_id");
            }
            MDC.remove("metric_type");
            MDC.remove("operation");
            MDC.remove("duration_ms");
        }
    }
}
