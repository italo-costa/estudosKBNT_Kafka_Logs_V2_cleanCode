package com.kbnt.virtualstock.infrastructure.adapter.output.kafka;

import com.kbnt.virtualstock.domain.port.output.StockEventPublisherPort;
import com.kbnt.virtualstock.domain.model.StockUpdatedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * No-operation implementation of StockEventPublisher for development/debugging.
 * This implementation logs events but doesn't actually publish to Kafka.
 */
@Component
@Profile("!production")
public class NoOpStockEventPublisherAdapter implements StockEventPublisherPort {
    
    private static final Logger logger = LoggerFactory.getLogger(NoOpStockEventPublisherAdapter.class);

    @Override
    public EventPublicationResult publishStockUpdated(StockUpdatedEvent event) {
        logger.info("NO-OP: Would publish stock updated event: {}", event);
        return EventPublicationResult.success("no-op-msg-id", "no-op-partition", 0L);
    }

    @Override
    public void publishStockUpdatedAsync(StockUpdatedEvent event) {
        logger.info("NO-OP: Would publish stock updated event async: {}", event);
    }
}
