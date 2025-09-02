package com.estudoskbnt.kbntlogservice.controller;

import com.estudoskbnt.kbntlogservice.model.LogMessage;
import com.estudoskbnt.kbntlogservice.producer.UnifiedLogProducer;
import io.micrometer.core.annotation.Timed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.support.SendResult;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * Unified Log API Controller for AMQ Streams
 * Handles REST API requests when producer mode is enabled
 */
@RestController
@RequestMapping("/api/v1/logs")
@ConditionalOnExpression("'${app.processing.modes}'.contains('producer')")
@Validated
public class UnifiedLogController {

    private static final Logger log = LoggerFactory.getLogger(UnifiedLogController.class);
    private final UnifiedLogProducer logProducer;

    public UnifiedLogController(UnifiedLogProducer logProducer) {
        this.logProducer = logProducer;
    }

    /**
     * Generic log endpoint - routes to appropriate topic based on content
     */
    @PostMapping
    @Timed(value = "log.produce", description = "Time taken to produce log messages")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> produceLog(
            @Valid @RequestBody LogMessage logMessage,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        // Set correlation ID from header if provided
        if (correlationId != null && !correlationId.isEmpty()) {
            logMessage.setCorrelationId(correlationId);
        }
        
        log.debug("📥 Received log message: level={}, category={}, service={}", 
            logMessage.getLevel(), logMessage.getCategory(), logMessage.getServiceName());

        return logProducer.produceLogMessage(logMessage)
            .thenApply(result -> {
                var response = Map.<String, Object>of(
                    "status", "accepted",
                    "correlationId", (Object) logMessage.getCorrelationId(),
                    "topic", (Object) result.getRecordMetadata().topic(),
                    "partition", (Object) result.getRecordMetadata().partition(),
                    "offset", (Object) result.getRecordMetadata().offset()
                );
                return ResponseEntity.accepted().body(response);
            })
            .exceptionally(throwable -> {
                log.error("Failed to produce log message", throwable);
                    var errorResponse = Map.<String, Object>of(
                        "status", "error",
                        "message", throwable.getMessage(),
                        "correlationId", logMessage.getCorrelationId()
                    );
                return ResponseEntity.internalServerError().body(errorResponse);
            });
    }

    /**
     * Application logs endpoint
     */
    @PostMapping("/application")
    @Timed(value = "log.produce.application", description = "Time taken to produce application logs")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> produceApplicationLog(
            @Valid @RequestBody LogMessage logMessage,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        if (correlationId != null) {
            logMessage.setCorrelationId(correlationId);
        }
        
        return logProducer.produceApplicationLog(logMessage)
            .thenApply(this::createSuccessResponse)
            .exceptionally(this::createErrorResponse);
    }

    /**
     * Error logs endpoint
     */
    @PostMapping("/error")
    @Timed(value = "log.produce.error", description = "Time taken to produce error logs")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> produceErrorLog(
            @Valid @RequestBody LogMessage logMessage,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        if (correlationId != null) {
            logMessage.setCorrelationId(correlationId);
        }
        
        return logProducer.produceErrorLog(logMessage)
            .thenApply(this::createSuccessResponse)
            .exceptionally(this::createErrorResponse);
    }

    /**
     * Audit logs endpoint
     */
    @PostMapping("/audit")
    @Timed(value = "log.produce.audit", description = "Time taken to produce audit logs")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> produceAuditLog(
            @Valid @RequestBody LogMessage logMessage,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        if (correlationId != null) {
            logMessage.setCorrelationId(correlationId);
        }
        
        return logProducer.produceAuditLog(logMessage)
            .thenApply(this::createSuccessResponse)
            .exceptionally(this::createErrorResponse);
    }

    /**
     * Financial logs endpoint
     */
    @PostMapping("/financial")
    @Timed(value = "log.produce.financial", description = "Time taken to produce financial logs")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> produceFinancialLog(
            @Valid @RequestBody LogMessage logMessage,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        if (correlationId != null) {
            logMessage.setCorrelationId(correlationId);
        }
        
        return logProducer.produceFinancialLog(logMessage)
            .thenApply(this::createSuccessResponse)
            .exceptionally(this::createErrorResponse);
    }

    /**
     * Batch logs endpoint for high-throughput scenarios
     */
    @PostMapping("/batch")
    @Timed(value = "log.produce.batch", description = "Time taken to produce batch logs")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> produceBatchLogs(
            @Valid @RequestBody LogMessage[] logMessages,
            @RequestHeader(value = "X-Correlation-ID", required = false) String correlationId) {
        
        log.debug("📥 Received batch of {} log messages", logMessages.length);
        
        var futures = new CompletableFuture[logMessages.length];
        
        for (int i = 0; i < logMessages.length; i++) {
            if (correlationId != null) {
                logMessages[i].setCorrelationId(correlationId + "-" + i);
            }
            futures[i] = logProducer.produceLogMessage(logMessages[i]);
        }
        
        return CompletableFuture.allOf(futures)
            .thenApply(v -> {
                var response = Map.<String, Object>of(
                    "status", "accepted",
                    "batchSize", (Object) logMessages.length,
                    "correlationId", (Object) (correlationId != null ? correlationId : "batch-" + System.currentTimeMillis())
                );
                return ResponseEntity.accepted().body(response);
            })
            .exceptionally(throwable -> {
                log.error("Failed to produce batch logs", throwable);
                var errorResponse = Map.<String, Object>of(
                    "status", "error", 
                    "message", throwable.getMessage(),
                    "batchSize", (Object) logMessages.length
                );
                return ResponseEntity.internalServerError().body(errorResponse);
            });
    }

    private ResponseEntity<Map<String, Object>> createSuccessResponse(SendResult<String, LogMessage> result) {
        var response = Map.<String, Object>of(
            "status", "accepted",
            "correlationId", (Object) result.getProducerRecord().value().getCorrelationId(),
            "topic", (Object) result.getRecordMetadata().topic(),
            "partition", (Object) result.getRecordMetadata().partition(),
            "offset", (Object) result.getRecordMetadata().offset()
        );
        return ResponseEntity.accepted().body(response);
    }

    private ResponseEntity<Map<String, Object>> createErrorResponse(Throwable throwable) {
        log.error("Failed to produce log message", throwable);
        var errorResponse = Map.<String, Object>of(
            "status", "error",
            "message", throwable.getMessage()
        );
        return ResponseEntity.internalServerError().body(errorResponse);
    }
}
