package com.kbnt.logproducer.domain.port.output;

import com.kbnt.logproducer.domain.model.LogEntry;

/**
 * Porta de saída para métricas
 */
public interface MetricsPort {
    // Métodos para compatibilidade com adapters e uso
    void incrementPublishedLogs();
    void incrementValidationErrors();
    void incrementPublishingErrors();
    void incrementSkippedLogs();
    void incrementHighPriorityLogs();
    void recordLogLevel(String level);
    void recordLogService(String serviceName);
    void recordProcessingTime(long durationMillis);
    void recordBatchProcessing(int totalLogs, int successCount, int errorCount);
    void recordBatchProcessingTime(long durationMillis);
    
    /**
     * Incrementa o contador de logs produzidos
     * @param service nome do serviço
     * @param level nível do log
     * @param topic tópico de destino
     */
    void incrementLogCounter(String service, String level, String topic);
    
    /**
     * Registra o tempo de processamento
     * @param service nome do serviço
     * @param processingTimeMs tempo em millisegundos
     */
    void recordProcessingTime(String service, long processingTimeMs);
    
    /**
     * Incrementa o contador de erros
     * @param service nome do serviço
     * @param errorType tipo do erro
     */
    void incrementErrorCounter(String service, String errorType);
    
    /**
     * Registra o tamanho do payload
     * @param service nome do serviço
     * @param payloadSize tamanho em bytes
     */
    void recordPayloadSize(String service, int payloadSize);
}
