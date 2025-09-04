package com.kbnt.logproducer.infrastructure.adapter.output;

import com.kbnt.logproducer.domain.model.LogEntry;
import com.kbnt.logproducer.domain.port.output.LogPublisherPort;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;

import java.time.format.DateTimeFormatter;
import java.util.concurrent.CompletableFuture;

/**
 * Adaptador para publicação de logs no Apache Kafka
 */
@Component
public class KafkaLogPublisherAdapter implements LogPublisherPort {
    
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;
    
    public KafkaLogPublisherAdapter(KafkaTemplate<String, String> kafkaTemplate, 
                                  ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }
    
    @Override
    public CompletableFuture<PublishResult> publish(String topic, String key, LogEntry logEntry) {
        try {
            String logJson = convertLogEntryToJson(logEntry);
            CompletableFuture<SendResult<String, String>> future = kafkaTemplate.send(topic, key, logJson);
            CompletableFuture<PublishResult> resultFuture = new CompletableFuture<>();
            future.whenComplete((result, throwable) -> {
                if (throwable != null) {
                    resultFuture.complete(PublishResult.failure(topic, throwable.getMessage()));
                } else {
                    resultFuture.complete(PublishResult.success(
                        topic,
                        result.getRecordMetadata().partition(),
                        result.getRecordMetadata().offset()
                    ));
                }
            });
            return resultFuture;
        } catch (Exception e) {
            CompletableFuture<PublishResult> failed = new CompletableFuture<>();
            failed.complete(PublishResult.failure(topic, e.getMessage()));
            return failed;
        }
    }

    private String convertLogEntryToJson(LogEntry logEntry) {
        try {
            LogEntryDto dto = new LogEntryDto();
            dto.timestamp = DateTimeFormatter.ISO_INSTANT.format(logEntry.getTimestamp());
            dto.level = logEntry.getLevel().toString();
            dto.message = logEntry.getMessage();
            dto.service = logEntry.getService().getValue();
            dto.requestId = logEntry.getRequestId().getValue();
            dto.amount = logEntry.getAmount();
            dto.metadata = logEntry.getMetadata();
            return objectMapper.writeValueAsString(dto);
        } catch (Exception e) {
            throw new RuntimeException("Erro ao serializar LogEntry para JSON: " + e.getMessage(), e);
        }
    }

    // DTO para serialização JSON do LogEntry
    private static class LogEntryDto {
    public String timestamp;
    public String level;
    public String message;
    public String service;
    public String requestId;
    public Double amount;
    public java.util.Map<String, Object> metadata;
    }
}
