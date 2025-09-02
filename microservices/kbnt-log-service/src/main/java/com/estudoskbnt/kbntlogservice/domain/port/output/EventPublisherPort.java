package com.estudoskbnt.kbntlogservice.domain.port.output;

import com.estudoskbnt.kbntlogservice.domain.model.StockUpdateEvent;

import java.util.concurrent.CompletableFuture;

/**
 * Event Publisher Port - Output Port
 * 
 * Defines event publication operations for stock update events.
 * Infrastructure adapters will implement this interface.
 */
public interface EventPublisherPort {
    
    /**
     * Publish a stock update event
     */
    CompletableFuture<EventPublicationResult> publishEvent(StockUpdateEvent event);
    
    /**
     * Publish event to specific topic
     */
    CompletableFuture<EventPublicationResult> publishEvent(StockUpdateEvent event, String topic);
    
    /**
     * Publish high-priority event
     */
    CompletableFuture<EventPublicationResult> publishHighPriorityEvent(StockUpdateEvent event);
}

/**
 * Event Publication Result
 */
interface EventPublicationResult {
    boolean isSuccess();
    String getTopic();
    String getPartition();
    Long getOffset();
    String getErrorMessage();
    
    static EventPublicationResult success(String topic, String partition, Long offset) {
        return new EventPublicationResult() {
            @Override
            public boolean isSuccess() { return true; }
            
            @Override
            public String getTopic() { return topic; }
            
            @Override
            public String getPartition() { return partition; }
            
            @Override
            public Long getOffset() { return offset; }
            
            @Override
            public String getErrorMessage() { return null; }
        };
    }
    
    static EventPublicationResult failure(String errorMessage) {
        return new EventPublicationResult() {
            @Override
            public boolean isSuccess() { return false; }
            
            @Override
            public String getTopic() { return null; }
            
            @Override
            public String getPartition() { return null; }
            
            @Override
            public Long getOffset() { return null; }
            
            @Override
            public String getErrorMessage() { return errorMessage; }
        };
    }
}
