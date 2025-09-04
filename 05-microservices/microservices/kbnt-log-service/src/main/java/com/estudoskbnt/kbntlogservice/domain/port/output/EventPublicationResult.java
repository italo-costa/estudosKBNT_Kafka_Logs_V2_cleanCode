package com.estudoskbnt.kbntlogservice.domain.port.output;

/**
 * Event Publication Result Interface
 * 
 * Hexagonal Architecture - Domain Port for Event Publication Results
 * Following DDD principles and aligned with virtual-stock-service architecture
 * 
 * This interface defines the contract for event publication results,
 * providing both success and failure scenarios with complete Kafka metadata.
 */
public interface EventPublicationResult {
    boolean isSuccess();
    String getMessageId();
    String getPartition();
    Long getOffset();
    String getTopic();
    String getErrorMessage();
    Exception getException();
    
    static EventPublicationResult success(String messageId, String topic, String partition, Long offset) {
        return new SuccessResult(messageId, topic, partition, offset);
    }
    
    static EventPublicationResult failure(String errorMessage, Exception exception) {
        return new FailureResult(errorMessage, exception);
    }
    
    /**
     * Success Result Implementation
     */
    class SuccessResult implements EventPublicationResult {
        private final String messageId;
        private final String topic;
        private final String partition;
        private final Long offset;
        
        public SuccessResult(String messageId, String topic, String partition, Long offset) {
            this.messageId = messageId;
            this.topic = topic;
            this.partition = partition;
            this.offset = offset;
        }
        
        @Override
        public boolean isSuccess() { return true; }
        
        @Override
        public String getMessageId() { return messageId; }
        
        @Override
        public String getTopic() { return topic; }
        
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
        public String getTopic() { return null; }
        
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
