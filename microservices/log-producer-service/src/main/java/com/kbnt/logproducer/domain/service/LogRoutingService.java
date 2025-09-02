package com.kbnt.logproducer.domain.service;

import com.kbnt.logproducer.domain.model.LogEntry;
import com.kbnt.logproducer.domain.model.LogLevel;

/**
 * Serviço de domínio para roteamento de logs
 */
public class LogRoutingService {
    
    /**
     * Determina o tópico Kafka baseado nas regras de negócio
     * @param logEntry o log a ser roteado
     * @return nome do tópico
     */
    public String determineKafkaTopic(LogEntry logEntry) {
        // Regra 1: Logs de erro vão para tópico específico
        if (isErrorLevel(logEntry.getLevel())) {
            return "error-logs";
        }
        
        // Regra 2: Logs relacionados à segurança vão para auditoria
        if (isSecurityRelated(logEntry)) {
            return "audit-logs";
        }
        
        // Regra 3: Logs de transações financeiras vão para tópico específico
        if (isFinancialTransaction(logEntry)) {
            return "financial-logs";
        }
        
        // Regra padrão: logs de aplicação
        return "application-logs";
    }
    
    /**
     * Determina a prioridade de processamento
     * @param logEntry o log
     * @return nível de prioridade (1=alta, 2=média, 3=baixa)
     */
    public int determinePriority(LogEntry logEntry) {
        if (logEntry.getLevel().isFatal() || logEntry.getLevel().isError()) {
            return 1; // Alta prioridade
        }
        
        if (logEntry.getLevel().isWarn() || isSecurityRelated(logEntry)) {
            return 2; // Média prioridade
        }
        
        return 3; // Baixa prioridade
    }
    
    /**
     * Gera chave de particionamento para distribuição balanceada
     * @param logEntry o log
     * @return chave de particionamento
     */
    public String generatePartitionKey(LogEntry logEntry) {
        // Usa o nome do serviço como base para particionamento
        // Isso garante que logs do mesmo serviço vão para a mesma partição
        return logEntry.getService().getValue();
    }
    
    private boolean isErrorLevel(LogLevel level) {
        return level.isError() || level.isFatal();
    }
    
    private boolean isSecurityRelated(LogEntry logEntry) {
        String message = logEntry.getMessage().toLowerCase();
        return message.contains("security") ||
               message.contains("login") ||
               message.contains("auth") ||
               message.contains("unauthorized") ||
               message.contains("access denied") ||
               message.contains("permission");
    }
    
    private boolean isFinancialTransaction(LogEntry logEntry) {
        return logEntry.getAmount() != null ||
               logEntry.getMessage().toLowerCase().contains("payment") ||
               logEntry.getMessage().toLowerCase().contains("transaction") ||
               logEntry.getMessage().toLowerCase().contains("purchase");
    }
}
