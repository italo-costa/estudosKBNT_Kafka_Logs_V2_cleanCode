package com.kbnt.logconsumer.domain.port.output;

/**
 * Port de saída para métricas do consumer
 */
public interface ConsumerMetricsPort {
    
    /**
     * Incrementa contador de logs consumidos
     */
    void incrementConsumedLogs();
    
    /**
     * Incrementa contador de logs processados com sucesso
     */
    void incrementProcessedLogs();
    
    /**
     * Incrementa contador de erros de processamento
     */
    void incrementProcessingErrors();
    
    /**
     * Incrementa contador de chamadas de API externas
     */
    void incrementExternalApiCalls();
    
    /**
     * Incrementa contador de falhas de API externa
     */
    void incrementExternalApiFailures();
    
    /**
     * Registra tempo de processamento de um log
     * @param durationMillis duração em milissegundos
     */
    void recordProcessingTime(long durationMillis);
    
    /**
     * Registra tempo de resposta da API externa
     * @param durationMillis duração em milissegundos
     */
    void recordApiResponseTime(long durationMillis);
    
    /**
     * Registra métrica por nível de log
     * @param level nível do log
     */
    void recordLogLevel(String level);
    
    /**
     * Registra métrica por serviço origem
     * @param serviceName nome do serviço
     */
    void recordSourceService(String serviceName);
    
    /**
     * Registra status code de resposta da API
     * @param statusCode código de status HTTP
     */
    void recordApiResponseStatus(int statusCode);
    
    /**
     * Incrementa contador de logs críticos
     */
    void incrementCriticalLogs();
    
    /**
     * Incrementa contador de retries
     */
    void incrementRetries();
}
