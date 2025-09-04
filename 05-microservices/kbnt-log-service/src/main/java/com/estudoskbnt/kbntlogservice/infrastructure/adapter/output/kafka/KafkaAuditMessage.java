package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Kafka Audit Message
 * 
 * Message format for audit events published to Kafka audit topics.
 * Used for compliance and traceability of business operations.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaAuditMessage {

    @JsonProperty("auditId")
    private String auditId;

    @JsonProperty("eventId")
    private String eventId;

    @JsonProperty("eventType")
    private String eventType;

    @JsonProperty("entityType")
    private String entityType;

    @JsonProperty("entityId")
    private String entityId;

    @JsonProperty("operation")
    private String operation;

    @JsonProperty("correlationId")
    private String correlationId;

    @JsonProperty("userId")
    private String userId;

    @JsonProperty("timestamp")
    private LocalDateTime timestamp;

    @JsonProperty("details")
    private Map<String, Object> details;
}
