package com.kbnt.logproducer.service;

import com.kbnt.logproducer.model.LogEntry;
import com.kbnt.logproducer.config.EnhancedLoggingConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
@Slf4j
public class LogProducerService {

    private final KafkaTemplate<String, LogEntry> kafkaTemplate;
    
    public LogProducerService(@Qualifier("logEntryKafkaTemplate") KafkaTemplate<String, LogEntry> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }
    
    @Value("${app.kafka.topics.application-logs:application-logs}")
    private String applicationLogsTopic;
    
    @Value("${app.kafka.topics.error-logs:error-logs}")
    private String errorLogsTopic;
    
    @Value("${app.kafka.topics.audit-logs:audit-logs}")
    private String auditLogsTopic;

    public CompletableFuture<SendResult<String, LogEntry>> sendApplicationLog(LogEntry logEntry) {
        return sendLog(applicationLogsTopic, logEntry);
    }

    public CompletableFuture<SendResult<String, LogEntry>> sendErrorLog(LogEntry logEntry) {
        return sendLog(errorLogsTopic, logEntry);
    }

    public CompletableFuture<SendResult<String, LogEntry>> sendAuditLog(LogEntry logEntry) {
        return sendLog(auditLogsTopic, logEntry);
    }

    public CompletableFuture<SendResult<String, LogEntry>> sendLog(String topic, LogEntry logEntry) {
        String messageId = UUID.randomUUID().toString();
        String key = logEntry.getService();
        
        try {
            // Set enhanced logging context
            EnhancedLoggingConfig.LoggingUtils.setServiceContext("MICROSERVICE-A", "LogProducerService");
            EnhancedLoggingConfig.LoggingUtils.setMessageContext(messageId, topic);
            
            long startTime = System.currentTimeMillis();
            
            EnhancedLoggingConfig.LoggingUtils.logComponentInfo("LOG_PREPARATION", 
                String.format("Preparing log message - Service: %s, Level: %s", 
                    logEntry.getService(), logEntry.getLevel()));
            
            EnhancedLoggingConfig.LoggingUtils.logKafkaOperation("PUBLISH_START", topic, null, 
                String.format("Starting to send log to topic with key '%s'", key));
            
            CompletableFuture<SendResult<String, LogEntry>> future = 
                kafkaTemplate.send(topic, key, logEntry);
                
            future.whenComplete((result, ex) -> {
                long duration = System.currentTimeMillis() - startTime;
                
                if (ex == null) {
                    // Log success with performance metrics
                    EnhancedLoggingConfig.LoggingUtils.logPerformanceMetrics("KAFKA_PUBLISH", duration);
                    
                    EnhancedLoggingConfig.LoggingUtils.logKafkaOperation("PUBLISH_SUCCESS", 
                        result.getRecordMetadata().topic(), 
                        result.getRecordMetadata().partition(),
                        String.format("Message sent successfully - Offset: %d, Duration: %dms", 
                            result.getRecordMetadata().offset(), duration));
                    
                    EnhancedLoggingConfig.LoggingUtils.logComponentInfo("KAFKA_PRODUCER", 
                        String.format("Log published successfully - MessageId: %s", messageId));
                } else {
                    EnhancedLoggingConfig.LoggingUtils.logError("KAFKA_PUBLISH_ERROR", 
                        "Failed to send log to Kafka", ex, topic);
                }
                
                // Clear context after completion
                EnhancedLoggingConfig.LoggingUtils.clearContext();
            });
            
            return future;
            
        } catch (Exception e) {
            EnhancedLoggingConfig.LoggingUtils.logError("KAFKA_SEND_ERROR", 
                "Unexpected error during log sending", e, messageId);
            EnhancedLoggingConfig.LoggingUtils.clearContext();
            throw e;
        }
    }
    
    public CompletableFuture<SendResult<String, LogEntry>> sendLogToTopic(String topic, LogEntry logEntry) {
        return sendLog(topic, logEntry);
    }
}
