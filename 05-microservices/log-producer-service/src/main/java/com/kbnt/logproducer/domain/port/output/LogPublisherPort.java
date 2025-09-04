package com.kbnt.logproducer.domain.port.output;

import com.kbnt.logproducer.domain.model.LogEntry;

import java.util.concurrent.CompletableFuture;

/**
 * Porta de saída para publicação de logs
 */
public interface LogPublisherPort {
    
    /**
     * Publica um log em um tópico
     * @param topic o tópico de destino
     * @param key a chave de particionamento
     * @param logEntry o log a ser publicado
     * @return resultado da publicação
     */
    CompletableFuture<PublishResult> publish(String topic, String key, LogEntry logEntry);
    
    /**
     * Resultado da publicação
     */
    record PublishResult(
        boolean success,
        String topic,
        Integer partition,
        Long offset,
        String errorMessage
    ) {
        
        public static PublishResult success(String topic, Integer partition, Long offset) {
            return new PublishResult(true, topic, partition, offset, null);
        }
        
        public static PublishResult failure(String topic, String errorMessage) {
            return new PublishResult(false, topic, null, null, errorMessage);
        }
    }
}
