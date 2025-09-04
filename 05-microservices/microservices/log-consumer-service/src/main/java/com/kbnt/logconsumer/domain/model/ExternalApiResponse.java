package com.kbnt.logconsumer.domain.model;

import java.util.Objects;

/**
 * Value Object representando a resposta de uma API externa
 */
public class ExternalApiResponse {
    
    private final boolean success;
    private final int statusCode;
    private final String responseBody;
    private final String errorMessage;
    private final long responseTimeMs;
    
    private ExternalApiResponse(boolean success, 
                              int statusCode, 
                              String responseBody, 
                              String errorMessage, 
                              long responseTimeMs) {
        this.success = success;
        this.statusCode = statusCode;
        this.responseBody = responseBody;
        this.errorMessage = errorMessage;
        this.responseTimeMs = responseTimeMs;
    }
    
    /**
     * Cria uma resposta de sucesso
     */
    public static ExternalApiResponse success(int statusCode, String responseBody, long responseTimeMs) {
        return new ExternalApiResponse(true, statusCode, responseBody, null, responseTimeMs);
    }
    
    /**
     * Cria uma resposta de erro
     */
    public static ExternalApiResponse error(int statusCode, String errorMessage, long responseTimeMs) {
        return new ExternalApiResponse(false, statusCode, null, errorMessage, responseTimeMs);
    }
    
    /**
     * Cria uma resposta de exceção (erro de conexão, timeout, etc.)
     */
    public static ExternalApiResponse exception(String errorMessage, long responseTimeMs) {
        return new ExternalApiResponse(false, 0, null, errorMessage, responseTimeMs);
    }
    
    // Métodos de negócio
    
    /**
     * Verifica se a resposta indica sucesso
     */
    public boolean isSuccess() {
        return success && statusCode >= 200 && statusCode < 300;
    }
    
    /**
     * Verifica se é um erro de client (4xx)
     */
    public boolean isClientError() {
        return statusCode >= 400 && statusCode < 500;
    }
    
    /**
     * Verifica se é um erro de servidor (5xx)
     */
    public boolean isServerError() {
        return statusCode >= 500 && statusCode < 600;
    }
    
    /**
     * Verifica se deve fazer retry baseado no status
     */
    public boolean shouldRetry() {
        // Retry para erros de servidor ou problemas de conectividade
        return isServerError() || 
               statusCode == 429 || // Too Many Requests
               statusCode == 408 || // Request Timeout
               statusCode == 0;     // Erro de conexão
    }
    
    /**
     * Verifica se a resposta foi rápida (< 1s)
     */
    public boolean isFastResponse() {
        return responseTimeMs < 1000;
    }
    
    /**
     * Verifica se a resposta foi lenta (> 5s)
     */
    public boolean isSlowResponse() {
        return responseTimeMs > 5000;
    }
    
    // Getters
    
    public boolean wasSuccessful() {
        return success;
    }
    
    public int getStatusCode() {
        return statusCode;
    }
    
    public String getResponseBody() {
        return responseBody;
    }
    
    public String getErrorMessage() {
        return errorMessage;
    }
    
    public long getResponseTimeMs() {
        return responseTimeMs;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ExternalApiResponse)) return false;
        ExternalApiResponse that = (ExternalApiResponse) o;
        return success == that.success &&
               statusCode == that.statusCode &&
               responseTimeMs == that.responseTimeMs &&
               Objects.equals(responseBody, that.responseBody) &&
               Objects.equals(errorMessage, that.errorMessage);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(success, statusCode, responseBody, errorMessage, responseTimeMs);
    }
    
    @Override
    public String toString() {
        return String.format("ExternalApiResponse{success=%s, statusCode=%d, responseTime=%dms, error='%s'}",
            success, statusCode, responseTimeMs, errorMessage);
    }
}
