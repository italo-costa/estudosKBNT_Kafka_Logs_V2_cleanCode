package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Kafka Stock Update Message
 * 
 * Message format for stock update events published to Kafka topics.
 * This represents the infrastructure layer's view of stock events.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaStockUpdateMessage {

    @JsonProperty("eventId")
    private String eventId;

    @JsonProperty("eventType")
    private String eventType;

    @JsonProperty("productId")
    private String productId;

    @JsonProperty("distributionCenter")
    private String distributionCenter;

    @JsonProperty("branch")
    private String branch;

    @JsonProperty("quantity")
    private Integer quantity;

    @JsonProperty("operation")
    private String operation;

    @JsonProperty("correlationId")
    private String correlationId;

    @JsonProperty("reasonCode")
    private String reasonCode;

    @JsonProperty("referenceDocument")
    private String referenceDocument;

    @JsonProperty("sourceBranch")
    private String sourceBranch;

    @JsonProperty("timestamp")
    private LocalDateTime timestamp;

    @JsonProperty("version")
    private Integer version;
}
