package com.kbnt.logconsumer.domain.model;

import java.time.Instant;
import java.util.Map;
import java.util.Objects;

/**
 * Entidade de domínio representando um log consumido
 */
public class ConsumedLog {
    
    private final Instant timestamp;
    private final LogLevel level;
    private final String message;
    private final ServiceName service;
    private final RequestId requestId;
    private final String exception;
    private final Double amount;
    private final Map<String, Object> metadata;
    
    // Status de processamento
    private ProcessingStatus processingStatus;
    private Instant processedAt;
    private String processingError;
    
    public ConsumedLog(Instant timestamp,
                      LogLevel level,
                      String message,
                      ServiceName service,
                      RequestId requestId,
                      String exception,
                      Double amount,
                      Map<String, Object> metadata) {
        this.timestamp = Objects.requireNonNull(timestamp, "Timestamp não pode ser nulo");
        this.level = Objects.requireNonNull(level, "Level não pode ser nulo");
        this.message = Objects.requireNonNull(message, "Message não pode ser nulo");
        this.service = Objects.requireNonNull(service, "Service não pode ser nulo");
        this.requestId = Objects.requireNonNull(requestId, "RequestId não pode ser nulo");
        this.exception = exception;
        this.amount = amount;
        this.metadata = metadata != null ? Map.copyOf(metadata) : Map.of();
        this.processingStatus = ProcessingStatus.PENDING;
    }
    
    // Métodos de negócio
    
    /**
     * Marca o log como processado com sucesso
     */
    public void markAsProcessed() {
        this.processingStatus = ProcessingStatus.PROCESSED;
        this.processedAt = Instant.now();
        this.processingError = null;
    }
    
    /**
     * Marca o log como erro no processamento
     */
    public void markAsError(String errorMessage) {
        this.processingStatus = ProcessingStatus.ERROR;
        this.processedAt = Instant.now();
        this.processingError = errorMessage;
    }
    
    /**
     * Marca o log como em processamento
     */
    public void markAsProcessing() {
        this.processingStatus = ProcessingStatus.PROCESSING;
    }
    
    /**
     * Verifica se o log requer processamento prioritário
     */
    public boolean requiresPriorityProcessing() {
        return level.isError() || level.isFatal() ||
               isSecurityRelated() ||
               isFinancialTransaction();
    }
    
    /**
     * Verifica se é um log relacionado à segurança
     */
    public boolean isSecurityRelated() {
        String lowerMessage = message.toLowerCase();
        return lowerMessage.contains("security") ||
               lowerMessage.contains("login") ||
               lowerMessage.contains("auth") ||
               lowerMessage.contains("unauthorized") ||
               lowerMessage.contains("access denied");
    }
    
    /**
     * Verifica se é uma transação financeira
     */
    public boolean isFinancialTransaction() {
        return amount != null ||
               message.toLowerCase().contains("payment") ||
               message.toLowerCase().contains("transaction");
    }
    
    /**
     * Calcula a idade do log em milissegundos
     */
    public long getAgeInMillis() {
        return Instant.now().toEpochMilli() - timestamp.toEpochMilli();
    }
    
    /**
     * Gera um identificador único para o log
     */
    public String generateUniqueId() {
        return String.format("%s-%s-%s", 
            timestamp.toEpochMilli(),
            service.getValue(),
            requestId.getValue().hashCode());
    }
    
    // Getters
    
    public Instant getTimestamp() {
        return timestamp;
    }
    
    public LogLevel getLevel() {
        return level;
    }
    
    public String getMessage() {
        return message;
    }
    
    public ServiceName getService() {
        return service;
    }
    
    public RequestId getRequestId() {
        return requestId;
    }
    
    public String getException() {
        return exception;
    }
    
    public Double getAmount() {
        return amount;
    }
    
    public Map<String, Object> getMetadata() {
        return metadata;
    }
    
    public ProcessingStatus getProcessingStatus() {
        return processingStatus;
    }
    
    public Instant getProcessedAt() {
        return processedAt;
    }
    
    public String getProcessingError() {
        return processingError;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ConsumedLog)) return false;
        ConsumedLog that = (ConsumedLog) o;
        return Objects.equals(timestamp, that.timestamp) &&
               Objects.equals(requestId, that.requestId) &&
               Objects.equals(service, that.service);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(timestamp, requestId, service);
    }
    
    @Override
    public String toString() {
        return String.format("ConsumedLog{timestamp=%s, level=%s, service=%s, requestId=%s, status=%s}",
            timestamp, level, service.getValue(), requestId.getValue(), processingStatus);
    }
}
