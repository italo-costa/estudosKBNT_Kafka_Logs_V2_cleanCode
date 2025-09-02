package com.kbnt.logconsumer.domain.port.input;

import com.kbnt.logconsumer.domain.model.ConsumedLog;

/**
 * Port de entrada para o processamento de logs
 */
public interface LogProcessingUseCase {
    
    /**
     * Processa um log consumido do Kafka
     * @param consumedLog o log a ser processado
     */
    void processLog(ConsumedLog consumedLog);
    
    /**
     * Processa um log de forma assíncrona
     * @param consumedLog o log a ser processado
     */
    void processLogAsync(ConsumedLog consumedLog);
    
    /**
     * Reprocessa um log que teve erro
     * @param consumedLog o log a ser reprocessado
     */
    void retryProcessing(ConsumedLog consumedLog);
}
