package com.kbnt.logproducer.infrastructure.adapter.input.rest;

import com.kbnt.logproducer.application.usecase.LogValidationUseCaseImpl;
import com.kbnt.logproducer.domain.model.LogEntry;
import com.kbnt.logproducer.domain.model.LogLevel;
import com.kbnt.logproducer.domain.model.RequestId;
import com.kbnt.logproducer.domain.model.ServiceName;
import com.kbnt.logproducer.domain.port.input.LogProductionUseCase;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Controller REST para recebimento e produção de logs
 */
@RestController
@RequestMapping("/api/v1/logs")
public class LogController {
    
    private final LogProductionUseCase logProductionUseCase;
    
    public LogController(LogProductionUseCase logProductionUseCase) {
        this.logProductionUseCase = logProductionUseCase;
    }
    
    /**
     * Endpoint para produzir um log individual
     */
    @PostMapping
    public ResponseEntity<?> produceLog(@Valid @RequestBody LogRequest request) {
        try {
            LogEntry logEntry = convertToLogEntry(request);
            logProductionUseCase.produceLog(logEntry);
            return ResponseEntity.ok(Map.of("message", "Log produzido com sucesso"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Erro interno do servidor"));
        }
    }
    
    /**
     * Endpoint para produzir um batch de logs
     */
    @PostMapping("/batch")
    public ResponseEntity<?> produceBatch(@Valid @RequestBody List<LogRequest> requests) {
        try {
            if (requests == null || requests.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Batch não pode estar vazio"));
            }
            
            List<LogEntry> logEntries = requests.stream()
                    .map(this::convertToLogEntry)
                    .collect(Collectors.toList());
                    
            logProductionUseCase.produceBatch(logEntries);
            return ResponseEntity.ok(Map.of(
                "message", "Batch processado com sucesso",
                "count", logEntries.size()
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Erro ao processar batch"));
        }
    }
    
    /**
     * Endpoint para validar um log sem produzir
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateLog(@Valid @RequestBody LogRequest request) {
        try {
            LogEntry logEntry = convertToLogEntry(request);
            // Aqui poderíamos usar o LogValidationUseCase se necessário
            return ResponseEntity.ok(Map.of("message", "Log válido"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    /**
     * Endpoint de health check
     */
    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "log-producer-service",
            "timestamp", Instant.now().toString()
        ));
    }
    
    private LogEntry convertToLogEntry(LogRequest request) {
        // Validar campos obrigatórios
        if (request.level == null || request.level.trim().isEmpty()) {
            throw new IllegalArgumentException("Nível do log é obrigatório");
        }
        if (request.message == null || request.message.trim().isEmpty()) {
            throw new IllegalArgumentException("Mensagem é obrigatória");
        }
        if (request.service == null || request.service.trim().isEmpty()) {
            throw new IllegalArgumentException("Nome do serviço é obrigatório");
        }
        if (request.requestId == null || request.requestId.trim().isEmpty()) {
            throw new IllegalArgumentException("RequestId é obrigatório");
        }
        
        // Converter timestamp ou usar atual
        Instant timestamp = request.timestamp != null ? 
            Instant.parse(request.timestamp) : Instant.now();
        
        return new LogEntry(
            timestamp,
            LogLevel.fromString(request.level),
            request.message,
            new ServiceName(request.service),
            new RequestId(request.requestId),
            request.exception,
            request.amount,
            request.metadata
        );
    }
    
    /**
     * DTO para recebimento de logs via REST
     */
    public static class LogRequest {
        public String timestamp;
        public String level;
        public String message;
        public String service;
        public String requestId;
        public String exception;
        public Double amount;
        public Map<String, Object> metadata;
    }
}
