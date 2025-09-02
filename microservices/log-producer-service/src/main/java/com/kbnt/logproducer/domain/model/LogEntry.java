package com.kbnt.logproducer.domain.model;

import lombok.Builder;
import lombok.Value;
import lombok.With;

import java.time.Instant;
import java.util.Map;

/**
 * Entidade de domínio para LogEntry
 * Representa um log no contexto do domínio, livre de dependências externas
 */
@Value
@Builder
@With
public class LogEntry {
    
    RequestId requestId;
    ServiceName service;
    LogLevel level;
    String message;
    Instant timestamp;
    String host;
    String environment;
    String userId;
    String sessionId;
    String transactionId;
    
    // Campos específicos por tipo de log
    String httpMethod;
    String endpoint;
    Integer statusCode;
    Long responseTimeMs;
    Double amount;
    String itemId;
    Integer currentStock;
    
    // Metadados flexíveis
    Map<String, Object> metadata;
    
    /**
     * Verifica se o log é de alta prioridade (ERROR ou FATAL)
     */
    public boolean isHighPriority() {
        return level.isError() || level.isFatal();
    }
    
    /**
     * Verifica se o log está relacionado à segurança
     */
    public boolean isSecurityRelated() {
        return message.toLowerCase().contains("security") ||
               message.toLowerCase().contains("login") ||
               message.toLowerCase().contains("auth") ||
               message.toLowerCase().contains("unauthorized");
    }
    
    /**
     * Determina o tópico Kafka baseado no nível e conteúdo
     */
    public String determineKafkaTopic() {
        if (isHighPriority()) {
            return "error-logs";
        } else if (isSecurityRelated()) {
            return "audit-logs";
        } else {
            return "application-logs";
        }
    }
    
    /**
     * Gera uma chave para particionamento no Kafka
     */
    public String generatePartitionKey() {
        return service.getValue();
    }
    
    /**
     * Valida se o log entry está completo e válido
     */
    public boolean isValid() {
        return requestId != null &&
               service != null &&
               level != null &&
               message != null && !message.trim().isEmpty() &&
               timestamp != null;
    }
}
