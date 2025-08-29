package com.kbnt.logproducer.domain.service;

import com.kbnt.logproducer.domain.model.LogEntry;
import com.kbnt.logproducer.domain.model.LogLevel;

import java.util.List;
import java.util.ArrayList;

/**
 * Serviço de domínio para validação de logs
 */
public class LogValidationService {
    
    private static final int MAX_MESSAGE_LENGTH = 10000;
    private static final int MAX_SERVICE_NAME_LENGTH = 100;
    
    /**
     * Valida um log entry completamente
     * @param logEntry o log a ser validado
     * @return lista de erros de validação (vazia se válido)
     */
    public List<String> validateLogEntry(LogEntry logEntry) {
        List<String> errors = new ArrayList<>();
        
        // Validações básicas
        if (logEntry == null) {
            errors.add("LogEntry não pode ser nulo");
            return errors;
        }
        
        // Validar timestamp
        if (logEntry.getTimestamp() == null) {
            errors.add("Timestamp é obrigatório");
        }
        
        // Validar nível
        if (logEntry.getLevel() == null) {
            errors.add("Nível do log é obrigatório");
        }
        
        // Validar mensagem
        validateMessage(logEntry.getMessage(), errors);
        
        // Validar service
        if (logEntry.getService() == null) {
            errors.add("Nome do serviço é obrigatório");
        } else {
            validateServiceName(logEntry.getService().getValue(), errors);
        }
        
        // Validar requestId
        if (logEntry.getRequestId() == null) {
            errors.add("RequestId é obrigatório");
        }
        
        // Validações específicas do contexto
        validateBusinessRules(logEntry, errors);
        
        return errors;
    }
    
    /**
     * Verifica se um log deve ser processado baseado em regras de negócio
     * @param logEntry o log
     * @return true se deve ser processado
     */
    public boolean shouldProcessLog(LogEntry logEntry) {
        // Não processar logs de DEBUG em produção (simulação)
        if (isProductionEnvironment() && logEntry.getLevel().isDebug()) {
            return false;
        }
        
        // Não processar logs muito antigos (mais de 24 horas)
        if (isLogTooOld(logEntry)) {
            return false;
        }
        
        // Não processar logs duplicados baseado em hash
        if (isDuplicateLog(logEntry)) {
            return false;
        }
        
        return true;
    }
    
    /**
     * Calcula um hash para detectar duplicatas
     * @param logEntry o log
     * @return hash único do log
     */
    public String calculateLogHash(LogEntry logEntry) {
        StringBuilder hashBuilder = new StringBuilder();
        hashBuilder.append(logEntry.getTimestamp().toString());
        hashBuilder.append("|");
        hashBuilder.append(logEntry.getLevel().toString());
        hashBuilder.append("|");
        hashBuilder.append(logEntry.getMessage());
        hashBuilder.append("|");
        hashBuilder.append(logEntry.getService().getValue());
        
        // Simples hash code para exemplo
        return String.valueOf(hashBuilder.toString().hashCode());
    }
    
    private void validateMessage(String message, List<String> errors) {
        if (message == null || message.trim().isEmpty()) {
            errors.add("Mensagem do log não pode estar vazia");
        } else if (message.length() > MAX_MESSAGE_LENGTH) {
            errors.add("Mensagem do log excede o tamanho máximo de " + MAX_MESSAGE_LENGTH + " caracteres");
        }
    }
    
    private void validateServiceName(String serviceName, List<String> errors) {
        if (serviceName == null || serviceName.trim().isEmpty()) {
            errors.add("Nome do serviço não pode estar vazio");
        } else if (serviceName.length() > MAX_SERVICE_NAME_LENGTH) {
            errors.add("Nome do serviço excede o tamanho máximo de " + MAX_SERVICE_NAME_LENGTH + " caracteres");
        } else if (!serviceName.matches("^[a-zA-Z0-9-_.]+$")) {
            errors.add("Nome do serviço deve conter apenas letras, números, hífens, sublinhados e pontos");
        }
    }
    
    private void validateBusinessRules(LogEntry logEntry, List<String> errors) {
        // Validar que logs de erro devem ter mais detalhes
        if (logEntry.getLevel().isError() || logEntry.getLevel().isFatal()) {
            if (logEntry.getException() == null && 
                (logEntry.getMessage().length() < 20)) {
                errors.add("Logs de erro devem conter mais detalhes ou informações de exceção");
            }
        }
        
        // Validar que transações financeiras devem ter amount
        if (isFinancialLog(logEntry) && logEntry.getAmount() == null) {
            errors.add("Logs de transações financeiras devem incluir o valor (amount)");
        }
        
        // Validar formato de RequestId para rastreabilidade
        if (logEntry.getRequestId() != null) {
            String requestIdValue = logEntry.getRequestId().getValue();
            if (!requestIdValue.matches("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")) {
                errors.add("RequestId deve seguir o formato UUID");
            }
        }
    }
    
    private boolean isFinancialLog(LogEntry logEntry) {
        String message = logEntry.getMessage().toLowerCase();
        return message.contains("payment") ||
               message.contains("transaction") ||
               message.contains("purchase") ||
               message.contains("refund");
    }
    
    private boolean isProductionEnvironment() {
        // Simulação - em ambiente real seria obtido de configuração
        return "production".equals(System.getProperty("environment", "development"));
    }
    
    private boolean isLogTooOld(LogEntry logEntry) {
        long currentTime = System.currentTimeMillis();
        long logTime = logEntry.getTimestamp().toEpochMilli();
        long twentyFourHours = 24 * 60 * 60 * 1000L;
        
        return (currentTime - logTime) > twentyFourHours;
    }
    
    private boolean isDuplicateLog(LogEntry logEntry) {
        // Simulação - em ambiente real seria verificado em cache/storage
        // Por exemplo, Redis com TTL para armazenar hashes recentes
        String hash = calculateLogHash(logEntry);
        
        // Aqui seria consultado um cache/storage de duplicatas
        // return duplicateCache.exists(hash);
        return false; // Simulação
    }
}
