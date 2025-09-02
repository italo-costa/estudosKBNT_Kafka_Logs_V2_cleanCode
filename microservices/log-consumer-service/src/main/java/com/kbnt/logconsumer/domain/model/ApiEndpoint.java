package com.kbnt.logconsumer.domain.model;

import java.util.Objects;

/**
 * Value Object representando uma URL da API externa
 */
public class ApiEndpoint {
    
    private final String baseUrl;
    private final String path;
    private final HttpMethod method;
    
    public ApiEndpoint(String baseUrl, String path, HttpMethod method) {
        if (baseUrl == null || baseUrl.trim().isEmpty()) {
            throw new IllegalArgumentException("Base URL não pode ser nula ou vazia");
        }
        if (path == null) {
            throw new IllegalArgumentException("Path não pode ser nulo");
        }
        if (method == null) {
            throw new IllegalArgumentException("HTTP Method não pode ser nulo");
        }
        
        this.baseUrl = baseUrl.endsWith("/") ? baseUrl.substring(0, baseUrl.length() - 1) : baseUrl;
        this.path = path.startsWith("/") ? path : "/" + path;
        this.method = method;
    }
    
    /**
     * Constrói a URL completa
     */
    public String getFullUrl() {
        return baseUrl + path;
    }
    
    /**
     * Verifica se é um endpoint de notificação
     */
    public boolean isNotificationEndpoint() {
        return path.toLowerCase().contains("notification") ||
               path.toLowerCase().contains("notify");
    }
    
    /**
     * Verifica se é um endpoint de auditoria
     */
    public boolean isAuditEndpoint() {
        return path.toLowerCase().contains("audit") ||
               path.toLowerCase().contains("log");
    }
    
    /**
     * Verifica se é um endpoint crítico
     */
    public boolean isCriticalEndpoint() {
        return path.toLowerCase().contains("alert") ||
               path.toLowerCase().contains("critical") ||
               path.toLowerCase().contains("emergency");
    }
    
    // Getters
    
    public String getBaseUrl() {
        return baseUrl;
    }
    
    public String getPath() {
        return path;
    }
    
    public HttpMethod getMethod() {
        return method;
    }
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ApiEndpoint)) return false;
        ApiEndpoint that = (ApiEndpoint) o;
        return Objects.equals(baseUrl, that.baseUrl) &&
               Objects.equals(path, that.path) &&
               method == that.method;
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(baseUrl, path, method);
    }
    
    @Override
    public String toString() {
        return String.format("%s %s", method, getFullUrl());
    }
    
    /**
     * Enumeration para métodos HTTP
     */
    public enum HttpMethod {
        GET, POST, PUT, DELETE, PATCH
    }
}
