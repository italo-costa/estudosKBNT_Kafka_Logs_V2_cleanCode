package com.kbnt.logconsumer.domain.port.output;

import com.kbnt.logconsumer.domain.model.ConsumedLog;

import java.util.List;
import java.util.Optional;

/**
 * Port de saída para persistência de logs processados
 */
public interface LogPersistencePort {
    
    /**
     * Salva um log processado
     * @param consumedLog o log a ser salvo
     */
    void saveProcessedLog(ConsumedLog consumedLog);
    
    /**
     * Atualiza o status de processamento de um log
     * @param logId identificador único do log
     * @param consumedLog log com status atualizado
     */
    void updateLogStatus(String logId, ConsumedLog consumedLog);
    
    /**
     * Busca um log pelo ID único
     * @param logId identificador único do log
     * @return log encontrado ou Optional.empty()
     */
    Optional<ConsumedLog> findLogById(String logId);
    
    /**
     * Busca logs por status de processamento
     * @param status status desejado
     * @return lista de logs com o status
     */
    List<ConsumedLog> findLogsByStatus(String status);
    
    /**
     * Busca logs que falharam e precisam de retry
     * @return lista de logs para retry
     */
    List<ConsumedLog> findLogsForRetry();
    
    /**
     * Remove logs antigos processados com sucesso
     * @param olderThanDays logs mais antigos que X dias
     * @return quantidade de logs removidos
     */
    int cleanupOldLogs(int olderThanDays);
}
