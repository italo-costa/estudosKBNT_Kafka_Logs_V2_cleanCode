package com.estudoskbnt.consumer.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.estudoskbnt.consumer.entity.ConsumptionLog;
import com.estudoskbnt.consumer.repository.ConsumptionLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

public class MonitoringController {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(MonitoringController.class);
    
    private final ConsumptionLogRepository consumptionLogRepository;
    
    /**
     * Get processing statistics for the last period
     */
    @GetMapping("/statistics")
    public ResponseEntity<Map<String, Object>> getProcessingStatistics(
            @RequestParam(defaultValue = "24") int hours) {
        
        LocalDateTime since = LocalDateTime.now().minusHours(hours);
        
        long totalMessages = consumptionLogRepository.countSuccessfulProcessingsSince(since) +
                            consumptionLogRepository.countFailedProcessingsSince(since);
        
        long successfulMessages = consumptionLogRepository.countSuccessfulProcessingsSince(since);
        long failedMessages = consumptionLogRepository.countFailedProcessingsSince(since);
        
        Double averageProcessingTime = consumptionLogRepository.getAverageProcessingTimeSince(since);
        
        double successRate = totalMessages > 0 ? (double) successfulMessages / totalMessages * 100 : 0;
        
        Map<String, Object> statistics = new HashMap<>();
        statistics.put("period_hours", hours);
        statistics.put("total_messages", totalMessages);
        statistics.put("successful_messages", successfulMessages);
        statistics.put("failed_messages", failedMessages);
        statistics.put("success_rate_percent", Math.round(successRate * 100.0) / 100.0);
        statistics.put("average_processing_time_ms", averageProcessingTime);
        statistics.put("generated_at", LocalDateTime.now());
        
        return ResponseEntity.ok(statistics);
    }
    
    /**
     * Get consumption logs with pagination and filtering
     */
    @GetMapping("/logs")
    public ResponseEntity<Page<ConsumptionLog>> getConsumptionLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String productId,
            @RequestParam(required = false) String topic) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<ConsumptionLog> logs;
        
        if (topic != null) {
            LocalDateTime since = LocalDateTime.now().minusHours(24);
            logs = consumptionLogRepository.findRecentLogsByTopic(topic, since, pageable);
        } else if (status != null) {
            try {
                ConsumptionLog.ProcessingStatus statusEnum = 
                        ConsumptionLog.ProcessingStatus.valueOf(status.toUpperCase());
                List<ConsumptionLog> statusLogs = consumptionLogRepository
                        .findByStatusOrderByConsumedAtDesc(statusEnum);
                // Convert to page (simplified for demo)
                logs = Page.empty();
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().build();
            }
        } else if (productId != null) {
            List<ConsumptionLog> productLogs = consumptionLogRepository
                    .findByProductIdOrderByConsumedAtDesc(productId);
            // Convert to page (simplified for demo)
            logs = Page.empty();
        } else {
            logs = consumptionLogRepository.findAll(pageable);
        }
        
        return ResponseEntity.ok(logs);
    }
    
    /**
     * Get consumption log by correlation ID
     */
    @GetMapping("/logs/correlation/{correlationId}")
    public ResponseEntity<ConsumptionLog> getLogByCorrelationId(
            @PathVariable String correlationId) {
        
        return consumptionLogRepository.findByCorrelationId(correlationId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    /**
     * Get slowest processing operations
     */
    @GetMapping("/performance/slowest")
    public ResponseEntity<List<ConsumptionLog>> getSlowestProcessing(
            @RequestParam(defaultValue = "24") int hours,
            @RequestParam(defaultValue = "10") int limit) {
        
        LocalDateTime since = LocalDateTime.now().minusHours(hours);
        Pageable pageable = PageRequest.of(0, limit);
        
        Page<ConsumptionLog> slowestLogs = consumptionLogRepository
                .findSlowestProcessingsSince(since, pageable);
        
        return ResponseEntity.ok(slowestLogs.getContent());
    }
    
    /**
     * Get API errors in the last period
     */
    @GetMapping("/errors/api")
    public ResponseEntity<List<ConsumptionLog>> getApiErrors(
            @RequestParam(defaultValue = "24") int hours) {
        
        LocalDateTime since = LocalDateTime.now().minusHours(hours);
        List<ConsumptionLog> apiErrors = consumptionLogRepository.findApiErrorsSince(since);
        
        return ResponseEntity.ok(apiErrors);
    }
    
    /**
     * Get message distribution by product
     */
    @GetMapping("/distribution/products")
    public ResponseEntity<Map<String, Object>> getProductDistribution(
            @RequestParam(defaultValue = "24") int hours) {
        
        LocalDateTime since = LocalDateTime.now().minusHours(hours);
        List<Object[]> productCounts = consumptionLogRepository
                .countMessagesByProductSince(since);
        
        Map<String, Object> distribution = new HashMap<>();
        distribution.put("period_hours", hours);
        
        Map<String, Long> productData = new HashMap<>();
        for (Object[] row : productCounts) {
            String productId = (String) row[0];
            Long count = (Long) row[1];
            productData.put(productId, count);
        }
        distribution.put("products", productData);
        distribution.put("generated_at", LocalDateTime.now());
        
        return ResponseEntity.ok(distribution);
    }
    
    /**
     * Get health status of the consumer
     */
    @GetMapping("/health/detailed")
    public ResponseEntity<Map<String, Object>> getDetailedHealth() {
        Map<String, Object> health = new HashMap<>();
        
        try {
            // Check database connectivity
            long totalLogs = consumptionLogRepository.count();
            health.put("database_status", "UP");
            health.put("total_logs_in_db", totalLogs);
            
            // Check recent processing activity
            LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
            long recentActivity = consumptionLogRepository.countSuccessfulProcessingsSince(oneHourAgo) +
                                 consumptionLogRepository.countFailedProcessingsSince(oneHourAgo);
            
            health.put("recent_activity_1h", recentActivity);
            health.put("consumer_status", recentActivity > 0 ? "ACTIVE" : "INACTIVE");
            
            // Overall status
            health.put("overall_status", "UP");
            health.put("timestamp", LocalDateTime.now());
            
        } catch (Exception e) {
            log.error("Health check failed", e);
            health.put("overall_status", "DOWN");
            health.put("error", e.getMessage());
            health.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(503).body(health);
        }
        
        return ResponseEntity.ok(health);
    }
    
    /**
     * Get logs that require retry
     */
    @GetMapping("/retry/pending")
    public ResponseEntity<List<ConsumptionLog>> getPendingRetries(
            @RequestParam(defaultValue = "5") int maxRetries) {
        
        List<ConsumptionLog> pendingRetries = consumptionLogRepository
                .findLogsRequiringRetry(maxRetries);
        
        return ResponseEntity.ok(pendingRetries);
    }
    
    /**
     * Manual retry trigger for specific correlation ID
     */
    @PostMapping("/retry/{correlationId}")
    public ResponseEntity<Map<String, String>> triggerManualRetry(
            @PathVariable String correlationId) {
        
        return consumptionLogRepository.findByCorrelationId(correlationId)
                .map(log -> {
                    if (log.getRetryCount() < 5) { // Max retry limit
                        log.setStatus(ConsumptionLog.ProcessingStatus.RETRY_SCHEDULED);
                        log.setRetryCount(log.getRetryCount() + 1);
                        consumptionLogRepository.save(log);
                        
                        Map<String, String> response = new HashMap<>();
                        response.put("status", "scheduled");
                        response.put("correlation_id", correlationId);
                        response.put("retry_count", String.valueOf(log.getRetryCount()));
                        response.put("message", "Retry scheduled successfully");
                        
                        return ResponseEntity.ok(response);
                    } else {
                        Map<String, String> response = new HashMap<>();
                        response.put("status", "rejected");
                        response.put("correlation_id", correlationId);
                        response.put("message", "Maximum retry attempts reached");
                        
                        return ResponseEntity.badRequest().body(response);
                    }
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
