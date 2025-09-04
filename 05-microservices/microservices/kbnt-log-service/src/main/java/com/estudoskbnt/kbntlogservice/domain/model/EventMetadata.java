package com.estudoskbnt.kbntlogservice.domain.model;

import java.time.LocalDateTime;

/**
 * Event Metadata Value Object
 * 
 * Contains metadata information for domain events.
 */
public class EventMetadata {
  private String eventId;
  private LocalDateTime timestamp;
  private String source;
  private String version;
  private CorrelationId correlationId;
  private String eventType;
  private String priority;

  // Constructors
  public EventMetadata() {
  }

  public EventMetadata(String eventId, LocalDateTime timestamp, String source, String version, 
                      CorrelationId correlationId, String eventType, String priority) {
    this.eventId = eventId;
    this.timestamp = timestamp;
    this.source = source;
    this.version = version;
    this.correlationId = correlationId;
    this.eventType = eventType;
    this.priority = priority;
  }

  // Getters
  public String getEventId() {
    return eventId;
  }

  public LocalDateTime getTimestamp() {
    return timestamp;
  }

  public String getSource() {
    return source;
  }

  public String getVersion() {
    return version;
  }

  public CorrelationId getCorrelationId() {
    return correlationId;
  }

  public String getEventType() {
    return eventType;
  }

  public String getPriority() {
    return priority;
  }

  // Static factory method following DDD patterns
  public static EventMetadata create(CorrelationId correlationId) {
    return new EventMetadata(
      java.util.UUID.randomUUID().toString(),
      LocalDateTime.now(),
      "kbnt-log-service",
      "1.0",
      correlationId,
      null,
      null
    );
  }

  // Builder pattern factory method
  public static EventMetadataBuilder builder() {
    return new EventMetadataBuilder();
  }

  public static class EventMetadataBuilder {
    private String eventId;
    private LocalDateTime timestamp;
    private String source;
    private String version;
    private CorrelationId correlationId;
    private String eventType;
    private String priority;

    public EventMetadataBuilder eventId(String eventId) {
      this.eventId = eventId;
      return this;
    }

    public EventMetadataBuilder timestamp(LocalDateTime timestamp) {
      this.timestamp = timestamp;
      return this;
    }

    public EventMetadataBuilder source(String source) {
      this.source = source;
      return this;
    }

    public EventMetadataBuilder version(String version) {
      this.version = version;
      return this;
    }

    public EventMetadataBuilder correlationId(CorrelationId correlationId) {
      this.correlationId = correlationId;
      return this;
    }

    public EventMetadataBuilder eventType(String eventType) {
      this.eventType = eventType;
      return this;
    }

    public EventMetadataBuilder priority(String priority) {
      this.priority = priority;
      return this;
    }

    public EventMetadata build() {
      return new EventMetadata(eventId, timestamp, source, version, correlationId, eventType, priority);
    }
  }
}
