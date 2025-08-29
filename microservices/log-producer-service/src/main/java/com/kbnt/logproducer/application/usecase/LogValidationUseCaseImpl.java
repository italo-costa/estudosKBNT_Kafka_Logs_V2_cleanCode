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
    public ValidationResult validateLog(LogEntry logEntry) {
        List<String> errors = validationService.validateLogEntry(logEntry);
        boolean isValid = errors.isEmpty();
        String hash = isValid ? validationService.calculateLogHash(logEntry) : null;
        boolean shouldProcess = isValid && validationService.shouldProcessLog(logEntry);
        
        return new ValidationResult(isValid, errors, hash, shouldProcess);
    }
    
    @Override
    public BatchValidationResult validateBatch(List<LogEntry> logEntries) {
        if (logEntries == null || logEntries.isEmpty()) {
            return new BatchValidationResult(0, 0, List.of());
        }
        
        int validCount = 0;
        int invalidCount = 0;
        List<ValidationResult> results = new java.util.ArrayList<>();
        
        for (LogEntry logEntry : logEntries) {
            ValidationResult result = validateLog(logEntry);
            results.add(result);
            
            if (result.isValid()) {
                validCount++;
            } else {
                invalidCount++;
            }
        }
        
        return new BatchValidationResult(validCount, invalidCount, results);
    }
    
    /**
     * Resultado da validação de um log individual
     */
    public static class ValidationResult {
        private final boolean valid;
        private final List<String> errors;
        private final String hash;
        private final boolean shouldProcess;
        
        public ValidationResult(boolean valid, List<String> errors, String hash, boolean shouldProcess) {
            this.valid = valid;
            this.errors = errors;
            this.hash = hash;
            this.shouldProcess = shouldProcess;
        }
        
        public boolean isValid() {
            return valid;
        }
        
        public List<String> getErrors() {
            return errors;
        }
        
        public String getHash() {
            return hash;
        }
        
        public boolean shouldProcess() {
            return shouldProcess;
        }
    }
    
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
