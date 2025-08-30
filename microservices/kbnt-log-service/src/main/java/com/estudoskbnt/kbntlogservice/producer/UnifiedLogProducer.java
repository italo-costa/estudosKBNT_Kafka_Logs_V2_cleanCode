package com.estudoskbnt.kbntlogservice.producer;

import com.estudoskbnt.kbntlogservice.model.LogMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Unified Log Producer Service for AMQ Streams
 * Routes different log types to appropriate topics
 */
@Slf4j
@Service
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
public class UnifiedLogProducer {

    private final KafkaTemplate<String, LogMessage> kafkaTemplate;
    
    @Value("${app.kafka.topics.application-logs}")
    private String applicationLogsTopic;
    
    @Value("${app.kafka.topics.error-logs}")
    private String errorLogsTopic;
    
    @Value("${app.kafka.topics.audit-logs}")
    private String auditLogsTopic;
    
    @Value("${app.kafka.topics.financial-logs}")
    private String financialLogsTopic;

    public UnifiedLogProducer(KafkaTemplate<String, LogMessage> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * Produces log message to appropriate topic based on log type
     */
    public CompletableFuture<SendResult<String, LogMessage>> produceLogMessage(LogMessage logMessage) {
        // Enrich message with metadata
        enrichLogMessage(logMessage);
        
        // Determine target topic
        String targetTopic = determineTargetTopic(logMessage);
        
        // Generate partition key for even distribution
        String partitionKey = generatePartitionKey(logMessage);
        
        log.debug("📤 Producing log message to topic: {} with key: {}", targetTopic, partitionKey);
        
        return kafkaTemplate.send(targetTopic, partitionKey, logMessage)
            .whenComplete((result, exception) -> {
                if (exception == null) {
                    log.debug("✅ Successfully sent log message to topic: {} partition: {} offset: {}", 
                        targetTopic,
                        result.getRecordMetadata().partition(),
                        result.getRecordMetadata().offset());
                } else {
                    log.error("❌ Failed to send log message to topic: {} - {}", 
                        targetTopic, exception.getMessage());
                }
            });
    }

    private void enrichLogMessage(LogMessage logMessage) {
        if (logMessage.getTimestamp() == null) {
            logMessage.setTimestamp(LocalDateTime.now());
        }
        
        if (logMessage.getCorrelationId() == null || logMessage.getCorrelationId().isEmpty()) {
            logMessage.setCorrelationId(UUID.randomUUID().toString());
        }
        
        if (logMessage.getServiceName() == null || logMessage.getServiceName().isEmpty()) {
            logMessage.setServiceName("kbnt-log-service");
        }
    }

    private String determineTargetTopic(LogMessage logMessage) {
        String level = logMessage.getLevel().toUpperCase();
        String category = logMessage.getCategory() != null ? logMessage.getCategory().toLowerCase() : "";
        
        // Financial logs have priority
        if ("FINANCIAL".equalsIgnoreCase(category) || 
            logMessage.getMessage().toLowerCase().contains("transaction") ||
            logMessage.getMessage().toLowerCase().contains("payment")) {
            return financialLogsTopic;
        }
        
        // Audit logs
        if ("AUDIT".equalsIgnoreCase(category) || 
            logMessage.getMessage().toLowerCase().contains("audit") ||
            logMessage.getMessage().toLowerCase().contains("security")) {
            return auditLogsTopic;
        }
        
        // Error logs for critical levels
        if ("ERROR".equals(level) || "FATAL".equals(level)) {
            return errorLogsTopic;
        }
        
        // Default to application logs
        return applicationLogsTopic;
    }

    private String generatePartitionKey(LogMessage logMessage) {
        // Use service name and level for balanced partitioning
        return String.format("%s-%s", 
            logMessage.getServiceName() != null ? logMessage.getServiceName() : "unknown",
            logMessage.getLevel());
    }

    /**
     * Produce application log
     */
    public CompletableFuture<SendResult<String, LogMessage>> produceApplicationLog(LogMessage logMessage) {
        logMessage.setCategory("APPLICATION");
        return produceLogMessage(logMessage);
    }

    /**
     * Produce error log
     */
    public CompletableFuture<SendResult<String, LogMessage>> produceErrorLog(LogMessage logMessage) {
        logMessage.setCategory("ERROR");
        logMessage.setLevel("ERROR");
        return produceLogMessage(logMessage);
    }

    /**
     * Produce audit log
     */
    public CompletableFuture<SendResult<String, LogMessage>> produceAuditLog(LogMessage logMessage) {
        logMessage.setCategory("AUDIT");
        return produceLogMessage(logMessage);
    }

    /**
     * Produce financial log
     */
    public CompletableFuture<SendResult<String, LogMessage>> produceFinancialLog(LogMessage logMessage) {
        logMessage.setCategory("FINANCIAL");
        return produceLogMessage(logMessage);
    }
}
