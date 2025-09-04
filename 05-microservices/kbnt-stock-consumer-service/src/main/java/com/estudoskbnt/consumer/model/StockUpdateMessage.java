package com.estudoskbnt.consumer.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.validation.constraints.*;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

public class StockUpdateMessage {
    // ...existing code...
    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }
    private String messageHash;
    public String getMessageHash() { return messageHash; }
    public void setMessageHash(String messageHash) { this.messageHash = messageHash; }
    public String getLocation() { return null; } // TODO: Implement if location field exists
    private String correlationId;
    private String productId;
    private Integer quantity;
    private java.math.BigDecimal price;
    private String operation;
    private String category;
    private String supplier;
    private LocalDateTime deadline;
    private String priority;
    public StockUpdateMessage() {}
    public StockUpdateMessage(String correlationId, String productId, Integer quantity, java.math.BigDecimal price, String operation, String category, String supplier) {
        this.correlationId = correlationId;
        this.productId = productId;
        this.quantity = quantity;
        this.price = price;
        this.operation = operation;
        this.category = category;
        this.supplier = supplier;
    }
    public static Builder builder() { return new Builder(); }
    public static class Builder {
    private String priority;
    public Builder priority(String priority) { this.priority = priority; return this; }
        private String correlationId;
        private String productId;
        private Integer quantity;
        private java.math.BigDecimal price;
        private String operation;
        private String category;
        private String supplier;
        private String location;
        private LocalDateTime publishedAt;
        private LocalDateTime deadline;
        private String hash;
        public Builder correlationId(String correlationId) { this.correlationId = correlationId; return this; }
        public Builder productId(String productId) { this.productId = productId; return this; }
        public Builder quantity(Integer quantity) { this.quantity = quantity; return this; }
        public Builder price(java.math.BigDecimal price) { this.price = price; return this; }
        public Builder operation(String operation) { this.operation = operation; return this; }
        public Builder category(String category) { this.category = category; return this; }
        public Builder supplier(String supplier) { this.supplier = supplier; return this; }
        public Builder location(String location) { this.location = location; return this; }
        public Builder publishedAt(LocalDateTime publishedAt) { this.publishedAt = publishedAt; return this; }
        public Builder deadline(LocalDateTime deadline) { this.deadline = deadline; return this; }
        public Builder hash(String hash) { this.hash = hash; return this; }
        public StockUpdateMessage build() {
            StockUpdateMessage msg = new StockUpdateMessage(correlationId, productId, quantity, price, operation, category, supplier);
            msg.location = this.location;
            msg.deadline = this.deadline;
            msg.publishedAt = this.publishedAt;
            msg.hash = this.hash;
            msg.priority = this.priority;
            return msg;
        }
    }
    private String location;
    private LocalDateTime publishedAt;
    private String hash;
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(LocalDateTime publishedAt) { this.publishedAt = publishedAt; }
    public LocalDateTime getDeadline() { return deadline; }
    public void setDeadline(LocalDateTime deadline) { this.deadline = deadline; }
    public String getHash() { return hash; }
    public void setHash(String hash) { this.hash = hash; }
    // Getters e setters para todos os campos
    public String getCorrelationId() { return correlationId; }
    public void setCorrelationId(String correlationId) { this.correlationId = correlationId; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public java.math.BigDecimal getPrice() { return price; }
    public void setPrice(java.math.BigDecimal price) { this.price = price; }
    public String getOperation() { return operation; }
    public void setOperation(String operation) { this.operation = operation; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getSupplier() { return supplier; }
    public void setSupplier(String supplier) { this.supplier = supplier; }
    public BigDecimal getTotalValue() {
        if (quantity != null && price != null) {
            return price.multiply(BigDecimal.valueOf(quantity));
        }
        return BigDecimal.ZERO;
    }
    /**
     * Check if the message has expired based on deadline
     * @return true if the message has expired
     */
    public boolean isExpired() {
        if (deadline == null) {
            return false;
        }
        return LocalDateTime.now().isAfter(deadline);
    }
    
    /**
     * Get priority as enum for easier comparison
     */
    public Priority getPriorityEnum() {
        try {
            return Priority.valueOf(priority != null ? priority.toUpperCase() : "NORMAL");
        } catch (IllegalArgumentException e) {
            return Priority.NORMAL;
        }
    }
    
    /**
     * Priority enumeration
     */
    public enum Priority {
        LOW(1),
        NORMAL(2), 
        HIGH(3),
        CRITICAL(4);
        
        private final int level;
        
        Priority(int level) {
            this.level = level;
        }
        
        public int getLevel() {
            return level;
        }
    }
}
