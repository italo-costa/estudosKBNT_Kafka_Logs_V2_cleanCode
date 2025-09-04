package com.estudoskbnt.kbntlogservice.domain.port.output;

import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;

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
