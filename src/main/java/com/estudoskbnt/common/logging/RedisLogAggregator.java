package com.estudoskbnt.common.logging;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * Substituto simples para kbnt-log-service usando Redis
 */
@Service
public class RedisLogAggregator {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    public void logEvent(String service, String level, String message, String correlationId) {
        try {
            Map<String, Object> logEntry = new HashMap<>();
            logEntry.put("service", service);
            logEntry.put("level", level);
            logEntry.put("message", message);
            logEntry.put("correlationId", correlationId);
            logEntry.put("timestamp", LocalDateTime.now());
            logEntry.put("hostname", System.getenv("HOSTNAME"));
            
            String key = generateRedisKey(service);
            String jsonLog = objectMapper.writeValueAsString(logEntry);
            
            // Store in Redis list for real-time processing
            redisTemplate.opsForList().rightPush(key, jsonLog);
            
            // Set TTL for automatic cleanup (7 days)
            redisTemplate.expire(key, java.time.Duration.ofDays(7));
            
        } catch (Exception e) {
            System.err.println("Failed to log to Redis: " + e.getMessage());
        }
    }
    
    private String generateRedisKey(String service) {
        String dateHour = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd-HH"));
        return String.format("logs:%s:%s", service, dateHour);
    }
}
