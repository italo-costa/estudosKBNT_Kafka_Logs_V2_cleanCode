package com.estudoskbnt.kbntlogservice.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Kafka Publication Log Model
 * Tracks detailed information about message publications to Kafka topics
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaPublicationLog {

    /**
     * Unique publication ID
     */
    private String publicationId;

    /**
     * Hash of the message timestamp for tracking
     */
    private String messageHash;

    /**
     * Target Kafka topic name
     */
    private String topicName;

    /**
     * Kafka partition assigned
     */
    private Integer partition;

    /**
     * Kafka offset received
     */
    private Long offset;

    /**
     * Message correlation ID
     */
    private String correlationId;

    /**
     * Product ID from the message
     */
    private String productId;

    /**
     * Operation type (ADD, REMOVE, TRANSFER, SET)
     */
    private String operation;

    /**
     * Message size in bytes
     */
    private Integer messageSizeBytes;

    /**
     * Time when message was sent
     */
    private LocalDateTime sentAt;

    /**
     * Time when ack was received from Kafka
     */
    private LocalDateTime acknowledgedAt;

    /**
     * Total processing time in milliseconds
     */
    private Long processingTimeMs;

    /**
     * Publication status (SENT, ACKNOWLEDGED, FAILED)
     */
    private PublicationStatus status;

    /**
     * Error message if publication failed
     */
    private String errorMessage;

    /**
     * Kafka broker response details
     */
    private String brokerResponse;

    /**
     * Producer instance ID
     */
    private String producerId;

    /**
     * Serialized message content for audit
     */
    private String messageContent;

    /**
     * Retry count if applicable
     */
    private Integer retryCount;

    public enum PublicationStatus {
        SENT,
        ACKNOWLEDGED,
        FAILED,
        RETRYING
    }
}
