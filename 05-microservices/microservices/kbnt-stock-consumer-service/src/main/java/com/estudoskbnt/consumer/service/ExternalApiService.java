package com.estudoskbnt.consumer.service;

import com.estudoskbnt.consumer.model.StockUpdateMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;

/**
 * External API Service
 * 
 * Handles integration with external APIs for stock processing.
 * Includes retry logic, timeout handling, and error management.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@Service
public class ExternalApiService {
        private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(ExternalApiService.class);
    
    private final WebClient webClient;
    
    @Value("${app.external-api.stock-service.base-url:http://localhost:8080}")
    private String stockServiceBaseUrl;
    
    @Value("${app.external-api.stock-service.timeout:10}")
    private int timeoutSeconds;
    
    @Value("${app.external-api.stock-service.max-retries:3}")
    private int maxRetries;
    
    @Value("${app.external-api.stock-service.retry-delay:2}")
    private int retryDelaySeconds;
    
    public ExternalApiService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.build();
    }
    
    /**
     * Process stock update by calling external stock service
     * 
     * @param message Stock update message to process
     * @return API response containing processing result
     */
    public Mono<ApiResponse> processStockUpdate(StockUpdateMessage message) {
        log.info("Processing stock update for product {} with correlation ID {}", 
                message.getProductId(), message.getCorrelationId());
        
        String endpoint = stockServiceBaseUrl + "/api/stock/process";
        
        StockProcessingRequest request = StockProcessingRequest.builder()
                .correlationId(message.getCorrelationId())
                .productId(message.getProductId())
                .quantity(message.getQuantity())
                .price(message.getPrice())
                .operation(message.getOperation())
                .category(message.getCategory())
                .supplier(message.getSupplier())
                .location(message.getLocation())
                .priority(message.getPriority())
                .processedAt(LocalDateTime.now())
                .build();
        
        return webClient
                .post()
                .uri(endpoint)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .retrieve()
                .bodyToMono(Map.class)
                .map(this::mapToApiResponse)
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .retryWhen(Retry.fixedDelay(maxRetries, Duration.ofSeconds(retryDelaySeconds))
                        .filter(this::isRetryableError))
                .onErrorResume(this::handleError)
                .doOnSuccess(response -> log.info("Successfully processed stock update for product {} - Status: {}", 
                        message.getProductId(), response.getStatus()))
                .doOnError(error -> log.error("Failed to process stock update for product {}: {}", 
                        message.getProductId(), error.getMessage()));
    }
    
    /**
     * Validate product information by calling external validation service
     * 
     * @param productId Product ID to validate
     * @return Validation response
     */
    public Mono<ValidationResponse> validateProduct(String productId) {
        log.debug("Validating product: {}", productId);
        
        String endpoint = stockServiceBaseUrl + "/api/products/validate/" + productId;
        
        return webClient
                .get()
                .uri(endpoint)
                .retrieve()
                .bodyToMono(Map.class)
                .map(this::mapToValidationResponse)
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .retryWhen(Retry.fixedDelay(2, Duration.ofSeconds(1))
                        .filter(this::isRetryableError))
                .onErrorResume(error -> {
                    log.warn("Product validation failed for {}: {}", productId, error.getMessage());
                    return Mono.just(ValidationResponse.builder()
                            .valid(false)
                            .message("Validation service unavailable")
                            .build());
                });
    }
    
    /**
     * Get current stock level from external service
     * 
     * @param productId Product ID
     * @param location Warehouse location
     * @return Current stock information
     */
    public Mono<StockInfo> getCurrentStock(String productId, String location) {
        log.debug("Getting current stock for product {} at location {}", productId, location);
        
        String endpoint = stockServiceBaseUrl + "/api/stock/current";
        
        return webClient
                .get()
                .uri(uriBuilder -> uriBuilder
                        .path(endpoint)
                        .queryParam("productId", productId)
                        .queryParam("location", location)
                        .build())
                .retrieve()
                .bodyToMono(Map.class)
                .map(this::mapToStockInfo)
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .retryWhen(Retry.fixedDelay(2, Duration.ofSeconds(1))
                        .filter(this::isRetryableError))
                .onErrorResume(error -> {
                    log.warn("Failed to get current stock for {} at {}: {}", 
                            productId, location, error.getMessage());
                    return Mono.just(StockInfo.builder()
                            .productId(productId)
                            .location(location)
                            .available(false)
                            .build());
                });
    }
    
    /**
     * Send notification about stock processing result
     * 
     * @param correlationId Correlation ID
     * @param productId Product ID
     * @param success Processing success status
     * @param message Processing message
     * @return Notification response
     */
    public Mono<Void> sendNotification(String correlationId, String productId, 
                                     boolean success, String message) {
        log.debug("Sending notification for correlation ID {}: success={}, message={}", 
                correlationId, success, message);
        
        String endpoint = stockServiceBaseUrl + "/api/notifications/stock-processed";
        
        NotificationRequest request = NotificationRequest.builder()
                .correlationId(correlationId)
                .productId(productId)
                .success(success)
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
        
        return webClient
                .post()
                .uri(endpoint)
                .contentType(MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .retrieve()
                .bodyToMono(Void.class)
                .timeout(Duration.ofSeconds(5))
                .onErrorResume(error -> {
                    log.warn("Failed to send notification for correlation ID {}: {}", 
                            correlationId, error.getMessage());
                    return Mono.empty();
                });
    }
    
    /**
     * Map response to ApiResponse object
     */
    private ApiResponse mapToApiResponse(Map<String, Object> response) {
        return ApiResponse.builder()
                .status(response.get("status").toString())
                .message(response.get("message").toString())
                .success("SUCCESS".equalsIgnoreCase(response.get("status").toString()))
                .data(response.get("data"))
                .timestamp(LocalDateTime.now())
                .build();
    }
    
    /**
     * Map response to ValidationResponse object
     */
    private ValidationResponse mapToValidationResponse(Map<String, Object> response) {
        return ValidationResponse.builder()
                .valid(Boolean.parseBoolean(response.get("valid").toString()))
                .message(response.getOrDefault("message", "").toString())
                .productExists(Boolean.parseBoolean(
                        response.getOrDefault("productExists", "false").toString()))
                .build();
    }
    
    /**
     * Map response to StockInfo object
     */
    private StockInfo mapToStockInfo(Map<String, Object> response) {
        return StockInfo.builder()
                .productId(response.get("productId").toString())
                .location(response.getOrDefault("location", "").toString())
                .currentQuantity(Integer.parseInt(
                        response.getOrDefault("quantity", "0").toString()))
                .available(Boolean.parseBoolean(
                        response.getOrDefault("available", "false").toString()))
                .lastUpdated(LocalDateTime.now())
                .build();
    }
    
    /**
     * Check if error is retryable
     */
    private boolean isRetryableError(Throwable error) {
        if (error instanceof WebClientResponseException) {
            WebClientResponseException webError = (WebClientResponseException) error;
            HttpStatus status = HttpStatus.resolve(webError.getStatusCode().value());
            
            // Retry on server errors (5xx) and specific client errors
            return status != null && (
                    status.is5xxServerError() || 
                    status == HttpStatus.REQUEST_TIMEOUT ||
                    status == HttpStatus.TOO_MANY_REQUESTS
            );
        }
        
        // Retry on network errors, timeouts, etc.
        return error instanceof java.net.ConnectException ||
               error instanceof java.util.concurrent.TimeoutException ||
               error.getCause() instanceof java.net.SocketTimeoutException;
    }
    
    /**
     * Handle errors and convert to ApiResponse
     */
    private Mono<ApiResponse> handleError(Throwable error) {
        log.error("External API call failed", error);
        
        String errorMessage = error.getMessage();
        HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
        
        if (error instanceof WebClientResponseException) {
            WebClientResponseException webError = (WebClientResponseException) error;
            status = HttpStatus.resolve(webError.getStatusCode().value());
            errorMessage = webError.getResponseBodyAsString();
        }
        
        return Mono.just(ApiResponse.builder()
                .status("ERROR")
                .message(errorMessage)
                .success(false)
                .httpStatus(status != null ? status.value() : 500)
                .timestamp(LocalDateTime.now())
                .build());
    }
    
    // Inner classes for request/response objects
    
        public static class ApiResponse {
                private String status;
                private String message;
                private boolean success;
                private Object data;
                private Integer httpStatus;
                private LocalDateTime timestamp;
                public ApiResponse() {}
                public ApiResponse(String status, String message, boolean success, Object data, Integer httpStatus, LocalDateTime timestamp) {
                        this.status = status;
                        this.message = message;
                        this.success = success;
                        this.data = data;
                        this.httpStatus = httpStatus;
                        this.timestamp = timestamp;
                }
                public static Builder builder() { return new Builder(); }
                public static class Builder {
                        private String status;
                        private String message;
                        private boolean success;
                        private Object data;
                        private Integer httpStatus;
                        private LocalDateTime timestamp;
                        public Builder status(String status) { this.status = status; return this; }
                        public Builder message(String message) { this.message = message; return this; }
                        public Builder success(boolean success) { this.success = success; return this; }
                        public Builder data(Object data) { this.data = data; return this; }
                        public Builder httpStatus(Integer httpStatus) { this.httpStatus = httpStatus; return this; }
                        public Builder timestamp(LocalDateTime timestamp) { this.timestamp = timestamp; return this; }
                        public ApiResponse build() { return new ApiResponse(status, message, success, data, httpStatus, timestamp); }
                }
                public String getStatus() { return status; }
                public void setStatus(String status) { this.status = status; }
                public String getMessage() { return message; }
                public void setMessage(String message) { this.message = message; }
                public boolean isSuccess() { return success; }
                public void setSuccess(boolean success) { this.success = success; }
                public Object getData() { return data; }
                public void setData(Object data) { this.data = data; }
                public Integer getHttpStatus() { return httpStatus; }
                public void setHttpStatus(Integer httpStatus) { this.httpStatus = httpStatus; }
                public LocalDateTime getTimestamp() { return timestamp; }
                public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
        }
    
        public static class ValidationResponse {
                private boolean valid;
                private String message;
                private boolean productExists;
                public ValidationResponse() {}
                public ValidationResponse(boolean valid, String message, boolean productExists) {
                        this.valid = valid;
                        this.message = message;
                        this.productExists = productExists;
                }
                public static Builder builder() { return new Builder(); }
                public static class Builder {
                        private boolean valid;
                        private String message;
                        private boolean productExists;
                        public Builder valid(boolean valid) { this.valid = valid; return this; }
                        public Builder message(String message) { this.message = message; return this; }
                        public Builder productExists(boolean productExists) { this.productExists = productExists; return this; }
                        public ValidationResponse build() { return new ValidationResponse(valid, message, productExists); }
                }
                public boolean isValid() { return valid; }
                public void setValid(boolean valid) { this.valid = valid; }
                public String getMessage() { return message; }
                public void setMessage(String message) { this.message = message; }
                public boolean isProductExists() { return productExists; }
                public void setProductExists(boolean productExists) { this.productExists = productExists; }
        }
    
        public static class StockInfo {
                private String productId;
                private String location;
                private Integer currentQuantity;
                private boolean available;
                private LocalDateTime lastUpdated;
                public StockInfo() {}
                public StockInfo(String productId, String location, Integer currentQuantity, boolean available, LocalDateTime lastUpdated) {
                        this.productId = productId;
                        this.location = location;
                        this.currentQuantity = currentQuantity;
                        this.available = available;
                        this.lastUpdated = lastUpdated;
                }
                public static Builder builder() { return new Builder(); }
                public static class Builder {
                        private String productId;
                        private String location;
                        private Integer currentQuantity;
                        private boolean available;
                        private LocalDateTime lastUpdated;
                        public Builder productId(String productId) { this.productId = productId; return this; }
                        public Builder location(String location) { this.location = location; return this; }
                        public Builder currentQuantity(Integer currentQuantity) { this.currentQuantity = currentQuantity; return this; }
                        public Builder available(boolean available) { this.available = available; return this; }
                        public Builder lastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; return this; }
                        public StockInfo build() { return new StockInfo(productId, location, currentQuantity, available, lastUpdated); }
                }
                public String getProductId() { return productId; }
                public void setProductId(String productId) { this.productId = productId; }
                public String getLocation() { return location; }
                public void setLocation(String location) { this.location = location; }
                public Integer getCurrentQuantity() { return currentQuantity; }
                public void setCurrentQuantity(Integer currentQuantity) { this.currentQuantity = currentQuantity; }
                public boolean isAvailable() { return available; }
                public void setAvailable(boolean available) { this.available = available; }
                public LocalDateTime getLastUpdated() { return lastUpdated; }
                public void setLastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; }
        }
    
        public static class StockProcessingRequest {
                private String correlationId;
                private String productId;
                private Integer quantity;
                private java.math.BigDecimal price;
                private String operation;
                private String category;
                private String supplier;
                private String location;
                private String priority;
                private LocalDateTime processedAt;
                public StockProcessingRequest() {}
                public StockProcessingRequest(String correlationId, String productId, Integer quantity, java.math.BigDecimal price, String operation, String category, String supplier, String location, String priority, LocalDateTime processedAt) {
                        this.correlationId = correlationId;
                        this.productId = productId;
                        this.quantity = quantity;
                        this.price = price;
                        this.operation = operation;
                        this.category = category;
                        this.supplier = supplier;
                        this.location = location;
                        this.priority = priority;
                        this.processedAt = processedAt;
                }
                public static Builder builder() { return new Builder(); }
                public static class Builder {
                        private String correlationId;
                        private String productId;
                        private Integer quantity;
                        private java.math.BigDecimal price;
                        private String operation;
                        private String category;
                        private String supplier;
                        private String location;
                        private String priority;
                        private LocalDateTime processedAt;
                        public Builder correlationId(String correlationId) { this.correlationId = correlationId; return this; }
                        public Builder productId(String productId) { this.productId = productId; return this; }
                        public Builder quantity(Integer quantity) { this.quantity = quantity; return this; }
                        public Builder price(java.math.BigDecimal price) { this.price = price; return this; }
                        public Builder operation(String operation) { this.operation = operation; return this; }
                        public Builder category(String category) { this.category = category; return this; }
                        public Builder supplier(String supplier) { this.supplier = supplier; return this; }
                        public Builder location(String location) { this.location = location; return this; }
                        public Builder priority(String priority) { this.priority = priority; return this; }
                        public Builder processedAt(LocalDateTime processedAt) { this.processedAt = processedAt; return this; }
                        public StockProcessingRequest build() { return new StockProcessingRequest(correlationId, productId, quantity, price, operation, category, supplier, location, priority, processedAt); }
                }
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
                public String getLocation() { return location; }
                public void setLocation(String location) { this.location = location; }
                public String getPriority() { return priority; }
                public void setPriority(String priority) { this.priority = priority; }
                public LocalDateTime getProcessedAt() { return processedAt; }
                public void setProcessedAt(LocalDateTime processedAt) { this.processedAt = processedAt; }
        }
    
        public static class NotificationRequest {
                private String correlationId;
                private String productId;
                private boolean success;
                private String message;
                private LocalDateTime timestamp;
                public NotificationRequest() {}
                public NotificationRequest(String correlationId, String productId, boolean success, String message, LocalDateTime timestamp) {
                        this.correlationId = correlationId;
                        this.productId = productId;
                        this.success = success;
                        this.message = message;
                        this.timestamp = timestamp;
                }
                public static Builder builder() { return new Builder(); }
                public static class Builder {
                        private String correlationId;
                        private String productId;
                        private boolean success;
                        private String message;
                        private LocalDateTime timestamp;
                        public Builder correlationId(String correlationId) { this.correlationId = correlationId; return this; }
                        public Builder productId(String productId) { this.productId = productId; return this; }
                        public Builder success(boolean success) { this.success = success; return this; }
                        public Builder message(String message) { this.message = message; return this; }
                        public Builder timestamp(LocalDateTime timestamp) { this.timestamp = timestamp; return this; }
                        public NotificationRequest build() { return new NotificationRequest(correlationId, productId, success, message, timestamp); }
                }
                public String getCorrelationId() { return correlationId; }
                public void setCorrelationId(String correlationId) { this.correlationId = correlationId; }
                public String getProductId() { return productId; }
                public void setProductId(String productId) { this.productId = productId; }
                public boolean isSuccess() { return success; }
                public void setSuccess(boolean success) { this.success = success; }
                public String getMessage() { return message; }
                public void setMessage(String message) { this.message = message; }
                public LocalDateTime getTimestamp() { return timestamp; }
                public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
        }
}
