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
    public void publishLog(LogEntry logEntry, String topic, String partitionKey) {
        try {
            // Converter LogEntry para JSON
            String logJson = convertLogEntryToJson(logEntry);
            
            // Publicar no Kafka
            CompletableFuture<SendResult<String, String>> future = 
                kafkaTemplate.send(topic, partitionKey, logJson);
            
            // Callback para tratamento do resultado
            future.whenComplete((result, throwable) -> {
                if (throwable != null) {
                    System.err.println("Erro ao publicar log no Kafka: " + throwable.getMessage());
                } else {
                    System.out.println("Log publicado com sucesso no tópico: " + topic + 
                                     ", partição: " + result.getRecordMetadata().partition() +
                                     ", offset: " + result.getRecordMetadata().offset());
                }
            });
            
        } catch (Exception e) {
            throw new RuntimeException("Erro ao publicar log no Kafka: " + e.getMessage(), e);
        }
    }
    
    private String convertLogEntryToJson(LogEntry logEntry) {
        try {
            // Criar um DTO para serialização JSON
            LogEntryDto dto = new LogEntryDto();
            dto.timestamp = logEntry.getTimestamp().format(DateTimeFormatter.ISO_INSTANT);
            dto.level = logEntry.getLevel().toString();
            dto.message = logEntry.getMessage();
            dto.service = logEntry.getService().getValue();
            dto.requestId = logEntry.getRequestId().getValue();
            dto.exception = logEntry.getException();
            dto.amount = logEntry.getAmount();
            dto.metadata = logEntry.getMetadata();
            
            return objectMapper.writeValueAsString(dto);
        } catch (Exception e) {
            throw new RuntimeException("Erro ao serializar LogEntry para JSON: " + e.getMessage(), e);
        }
    }
    
    /**
     * DTO para serialização JSON do LogEntry
     */
    private static class LogEntryDto {
        public String timestamp;
        public String level;
        public String message;
        public String service;
        public String requestId;
        public String exception;
        public Double amount;
        public java.util.Map<String, Object> metadata;
    }
}
