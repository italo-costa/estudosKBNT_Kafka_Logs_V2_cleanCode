package com.kbnt.logconsumer.domain.model;

/**
 * Enumeration para o status de processamento do log
 */
public enum ProcessingStatus {
    PENDING("Aguardando processamento"),
    PROCESSING("Em processamento"),
    PROCESSED("Processado com sucesso"),
    ERROR("Erro no processamento"),
    RETRY("Aguardando retry");
    
    private final String description;
    
    ProcessingStatus(String description) {
        this.description = description;
    }
    
    public String getDescription() {
        return description;
    }
    
    public boolean isCompleted() {
        return this == PROCESSED;
    }
    
    public boolean hasError() {
        return this == ERROR;
    }
    
    public boolean isPending() {
        return this == PENDING || this == RETRY;
    }
    
    public boolean isProcessing() {
        return this == PROCESSING;
    }
}
