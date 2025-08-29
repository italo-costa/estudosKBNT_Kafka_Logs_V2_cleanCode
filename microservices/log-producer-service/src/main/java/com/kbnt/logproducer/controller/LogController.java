package com.kbnt.logproducer.controller;

import com.kbnt.logproducer.model.LogEntry;
import com.kbnt.logproducer.service.LogProducerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.support.SendResult;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/v1/logs")
@RequiredArgsConstructor
@Validated
@Slf4j
public class LogController {

    private final LogProducerService logProducerService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> sendLog(@Valid @RequestBody LogEntry logEntry) {
        log.info("Received log entry for service: {}, level: {}", 
                logEntry.getService(), logEntry.getLevel());
        
        // Define timestamp se não fornecido
        if (logEntry.getTimestamp() == null) {
            logEntry.setTimestamp(Instant.now());
        }
        
        try {
            CompletableFuture<SendResult<String, LogEntry>> future;
            
            // Roteamento baseado no nível do log
            switch (logEntry.getLevel().toUpperCase()) {
                case "ERROR", "FATAL":
                    future = logProducerService.sendErrorLog(logEntry);
                    break;
                case "WARN":
                    // Para warnings de segurança, enviar para audit
                    if (logEntry.getMessage().toLowerCase().contains("security") ||
                        logEntry.getMessage().toLowerCase().contains("login") ||
                        logEntry.getMessage().toLowerCase().contains("auth")) {
                        future = logProducerService.sendAuditLog(logEntry);
                    } else {
                        future = logProducerService.sendApplicationLog(logEntry);
                    }
                    break;
                default:
                    future = logProducerService.sendApplicationLog(logEntry);
                    break;
            }
            
            Map<String, Object> response = new HashMap<>();
            response.put("status", "accepted");
            response.put("message", "Log entry queued for processing");
            response.put("timestamp", Instant.now());
            response.put("logLevel", logEntry.getLevel());
            response.put("service", logEntry.getService());
            
            log.info("Log entry accepted and queued for service: {}", logEntry.getService());
            
            return ResponseEntity.accepted().body(response);
            
        } catch (Exception e) {
            log.error("Error processing log entry: {}", e.getMessage(), e);
            
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "error");
            errorResponse.put("message", "Failed to process log entry");
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", Instant.now());
            
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    @PostMapping("/topic/{topic}")
    public ResponseEntity<Map<String, Object>> sendLogToTopic(
            @PathVariable String topic,
            @Valid @RequestBody LogEntry logEntry) {
        
        log.info("Received log entry for topic: {}, service: {}", topic, logEntry.getService());
        
        if (logEntry.getTimestamp() == null) {
            logEntry.setTimestamp(Instant.now());
        }
        
        try {
            logProducerService.sendLogToTopic(topic, logEntry);
            
            Map<String, Object> response = new HashMap<>();
            response.put("status", "accepted");
            response.put("message", "Log entry sent to topic: " + topic);
            response.put("timestamp", Instant.now());
            response.put("topic", topic);
            
            return ResponseEntity.accepted().body(response);
            
        } catch (Exception e) {
            log.error("Error sending log to topic {}: {}", topic, e.getMessage(), e);
            
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "error");
            errorResponse.put("message", "Failed to send log to topic: " + topic);
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", Instant.now());
            
            return ResponseEntity.internalServerError().body(errorResponse);
        }
    }

    @PostMapping("/batch")
    public ResponseEntity<Map<String, Object>> sendBatchLogs(@Valid @RequestBody LogEntry[] logEntries) {
        log.info("Received batch of {} log entries", logEntries.length);
        
        int successCount = 0;
        int errorCount = 0;
        
        for (LogEntry logEntry : logEntries) {
            try {
                if (logEntry.getTimestamp() == null) {
                    logEntry.setTimestamp(Instant.now());
                }
                
                logProducerService.sendApplicationLog(logEntry);
                successCount++;
                
            } catch (Exception e) {
                log.error("Error processing log entry in batch: {}", e.getMessage());
                errorCount++;
            }
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("status", "processed");
        response.put("total", logEntries.length);
        response.put("successful", successCount);
        response.put("failed", errorCount);
        response.put("timestamp", Instant.now());
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "log-producer-service");
        response.put("timestamp", Instant.now());
        
        return ResponseEntity.ok(response);
    }
}
