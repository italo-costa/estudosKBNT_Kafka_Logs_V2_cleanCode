package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Kafka Application Log Message
 * 
 * Message format for application log events published to Kafka logging topics.
 * Used for centralized logging and monitoring.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaApplicationLogMessage {

    @JsonProperty("logId")
    private String logId;

    @JsonProperty("level")
    private String level;

    @JsonProperty("message")
    private String message;

    @JsonProperty("service")
    private String service;

    @JsonProperty("component")
    private String component;

    @JsonProperty("timestamp")
    private LocalDateTime timestamp;

    @JsonProperty("context")
    private Map<String, Object> context;
}
