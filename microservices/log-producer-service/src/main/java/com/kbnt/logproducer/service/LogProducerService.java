package com.kbnt.logproducer.service;

import com.kbnt.logproducer.model.LogEntry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class LogProducerService {

    private final KafkaTemplate<String, LogEntry> kafkaTemplate;
    
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
        // Usa o serviço como chave para particionamento
        String key = logEntry.getService();
        
        log.debug("Sending log to topic '{}' with key '{}': {}", 
                  topic, key, logEntry.getMessage());
        
        CompletableFuture<SendResult<String, LogEntry>> future = 
            kafkaTemplate.send(topic, key, logEntry);
            
        future.whenComplete((result, ex) -> {
            if (ex == null) {
                log.debug("Log sent successfully to topic '{}' partition {} offset {}", 
                         result.getRecordMetadata().topic(),
                         result.getRecordMetadata().partition(),
                         result.getRecordMetadata().offset());
            } else {
                log.error("Failed to send log to topic '{}': {}", topic, ex.getMessage(), ex);
            }
        });
        
        return future;
    }
    
    public CompletableFuture<SendResult<String, LogEntry>> sendLogToTopic(String topic, LogEntry logEntry) {
        return sendLog(topic, logEntry);
    }
}
