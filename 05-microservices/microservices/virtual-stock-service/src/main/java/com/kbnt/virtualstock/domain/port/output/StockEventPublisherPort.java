package com.kbnt.virtualstock.domain.port.output;

import com.kbnt.virtualstock.domain.model.StockUpdatedEvent;

/**
 * Stock Event Publisher Port - Output Port for Event Publishing
 * 
 * Domain interface for publishing stock events to external systems.
 * Kafka adapters will implement this interface.
 */
public interface StockEventPublisherPort {
    
    /**
     * Publish stock updated event
     * 
     * @param event The stock updated event to publish
     * @return Event publication result
     */
    EventPublicationResult publishStockUpdated(StockUpdatedEvent event);
    
    /**
     * Publish stock updated event asynchronously
     * 
     * @param event The stock updated event to publish
     */
    void publishStockUpdatedAsync(StockUpdatedEvent event);
    
    /**
     * Event Publication Result
     */
    interface EventPublicationResult {
        boolean isSuccess();
        String getMessageId();
        String getPartition();
        Long getOffset();
        String getErrorMessage();
        Exception getException();
        
        static EventPublicationResult success(String messageId, String partition, Long offset) {
            return new SuccessResult(messageId, partition, offset);
        }
        
        static EventPublicationResult failure(String errorMessage, Exception exception) {
            return new FailureResult(errorMessage, exception);
        }
    }
    
    /**
     * Success Result Implementation
     */
    class SuccessResult implements EventPublicationResult {
        private final String messageId;
        private final String partition;
        private final Long offset;
        
        public SuccessResult(String messageId, String partition, Long offset) {
            this.messageId = messageId;
            this.partition = partition;
            this.offset = offset;
        }
        
        @Override
        public boolean isSuccess() { return true; }
        
        @Override
        public String getMessageId() { return messageId; }
        
        @Override
        public String getPartition() { return partition; }
        
        @Override
        public Long getOffset() { return offset; }
        
        @Override
        public String getErrorMessage() { return null; }
        
        @Override
        public Exception getException() { return null; }
    }
    
    /**
     * Failure Result Implementation
     */
    class FailureResult implements EventPublicationResult {
        private final String errorMessage;
        private final Exception exception;
        
        public FailureResult(String errorMessage, Exception exception) {
            this.errorMessage = errorMessage;
            this.exception = exception;
        }
        
        @Override
        public boolean isSuccess() { return false; }
        
        @Override
        public String getMessageId() { return null; }
        
        @Override
        public String getPartition() { return null; }
        
        @Override
        public Long getOffset() { return null; }
        
        @Override
        public String getErrorMessage() { return errorMessage; }
        
        @Override
        public Exception getException() { return exception; }
    }
}
