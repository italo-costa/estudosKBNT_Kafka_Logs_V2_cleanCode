package com.kbnt.logproducer.domain.port.input;

import com.kbnt.logproducer.domain.model.LogEntry;

/**
 * Porta de entrada para casos de uso de produção de logs
 */
public interface LogProductionUseCase {
    
    /**
     * Produz um log para o sistema de mensageria
     * @param logEntry o log a ser produzido
     * @return resultado da operação de produção
     */
    LogProductionResult produceLog(LogEntry logEntry);
    
    /**
     * Produz um log de forma assíncrona
     * @param logEntry o log a ser produzido
     */
    void produceLogAsync(LogEntry logEntry);
    
    /**
     * Resultado da operação de produção de log
     */
    record LogProductionResult(
        boolean success,
        String message,
        String topic,
        Integer partition,
        Long offset,
        Throwable error
    ) {
        
        public static LogProductionResult success(String topic, Integer partition, Long offset) {
            return new LogProductionResult(true, "Log produced successfully", topic, partition, offset, null);
        }
        
        public static LogProductionResult failure(String message, Throwable error) {
            return new LogProductionResult(false, message, null, null, null, error);
        }
    }
}
