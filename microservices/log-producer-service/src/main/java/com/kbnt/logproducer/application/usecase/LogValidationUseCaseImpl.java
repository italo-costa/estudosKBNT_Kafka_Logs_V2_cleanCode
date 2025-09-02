package com.kbnt.logproducer.application.usecase;

import com.kbnt.logproducer.domain.model.LogEntry;
import com.kbnt.logproducer.domain.port.input.LogValidationUseCase;
import com.kbnt.logproducer.domain.service.LogValidationService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Implementação do caso de uso de validação de logs
 */
@Service
public class LogValidationUseCaseImpl implements LogValidationUseCase {
    
    private final LogValidationService validationService;
    
    public LogValidationUseCaseImpl(LogValidationService validationService) {
        this.validationService = validationService;
    }
    
    @Override
    public ValidationResult validate(LogEntry logEntry) {
    List<String> errors = validationService.validateLogEntry(logEntry);
    boolean isValid = errors.isEmpty();
    String message = isValid ? "Valid log entry" : "Invalid log entry";
    return new ValidationResult(isValid, message, errors);
    }

    @Override
    public LogEntry enrich(LogEntry logEntry) {
        // Implementação de enriquecimento, se necessário
        return logEntry;
    }
    
    /**
     * Resultado da validação de um log individual
     */
    
    /**
     * Resultado da validação de um batch de logs
     */
    public static class BatchValidationResult {
        private final int validCount;
        private final int invalidCount;
        private final List<ValidationResult> results;
        
        public BatchValidationResult(int validCount, int invalidCount, List<ValidationResult> results) {
            this.validCount = validCount;
            this.invalidCount = invalidCount;
            this.results = results;
        }
        
        public int getValidCount() {
            return validCount;
        }
        
        public int getInvalidCount() {
            return invalidCount;
        }
        
        public int getTotalCount() {
            return validCount + invalidCount;
        }
        
        public List<ValidationResult> getResults() {
            return results;
        }
        
        public double getValidationRate() {
            if (getTotalCount() == 0) return 0.0;
            return (double) validCount / getTotalCount();
        }
    }
}
