package com.kbnt.logproducer.domain.port.input;

import com.kbnt.logproducer.domain.model.LogEntry;

/**
 * Porta de entrada para casos de uso de validação de logs
 */
public interface LogValidationUseCase {
    
    /**
     * Valida um log entry
     * @param logEntry o log a ser validado
     * @return resultado da validação
     */
    ValidationResult validate(LogEntry logEntry);
    
    /**
     * Enriquece um log entry com dados faltantes
     * @param logEntry o log a ser enriquecido
     * @return log entry enriquecido
     */
    LogEntry enrich(LogEntry logEntry);
    
    /**
     * Resultado da validação
     */
    record ValidationResult(
        boolean valid,
        String message,
        java.util.List<String> errors
    ) {
        public static ValidationResult validResult() {
            return new ValidationResult(true, "Valid log entry", java.util.List.of());
        }
        public static ValidationResult invalidResult(String message, java.util.List<String> errors) {
            return new ValidationResult(false, message, errors);
        }
    }
}
