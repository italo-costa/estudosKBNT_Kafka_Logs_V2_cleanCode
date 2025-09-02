package com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.persistence;

import com.estudoskbnt.kbntlogservice.domain.model.*;
import com.estudoskbnt.kbntlogservice.domain.port.output.StockUpdateRepositoryPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-Memory Stock Update Repository Adapter
 * 
 * Infrastructure adapter that provides persistence capabilities for stock updates.
 * Currently uses in-memory storage for demonstration purposes.
 * 
 * In production, this would typically connect to a database like PostgreSQL,
 * MongoDB, or another persistent storage system.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class InMemoryStockUpdateRepositoryAdapter implements StockUpdateRepositoryPort {

    // In-memory storage - in production this would be replaced with actual database
    private final Map<String, StockUpdate> stockUpdates = new ConcurrentHashMap<>();
    private final Map<String, List<StockUpdate>> stockUpdatesByProduct = new ConcurrentHashMap<>();
    private final Map<String, List<StockUpdate>> stockUpdatesByLocation = new ConcurrentHashMap<>();

    @Override
    public CompletableFuture<StockUpdate> save(StockUpdate stockUpdate) {
        log.debug("💾 Saving stock update: {} for product {} at {}-{}", 
                stockUpdate.getId(), 
                stockUpdate.getProductId().getValue(),
                stockUpdate.getDistributionCenter().getCode(),
                stockUpdate.getBranch().getCode());

        return CompletableFuture.supplyAsync(() -> {
            try {
                // Store by ID
                stockUpdates.put(stockUpdate.getId(), stockUpdate);
                
                // Index by product ID for fast lookups
                String productId = stockUpdate.getProductId().getValue();
                stockUpdatesByProduct.computeIfAbsent(productId, k -> new ArrayList<>()).add(stockUpdate);
                
                // Index by location for queries
                String locationKey = createLocationKey(stockUpdate.getDistributionCenter(), stockUpdate.getBranch());
                stockUpdatesByLocation.computeIfAbsent(locationKey, k -> new ArrayList<>()).add(stockUpdate);
                
                log.debug("✅ Successfully saved stock update: {}", stockUpdate.getId());
                return stockUpdate;
                
            } catch (Exception e) {
                log.error("❌ Failed to save stock update: {}", stockUpdate.getId(), e);
                throw new PersistenceException("Failed to save stock update: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<Optional<StockUpdate>> findById(String id) {
        log.debug("🔍 Finding stock update by ID: {}", id);
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                Optional<StockUpdate> result = Optional.ofNullable(stockUpdates.get(id));
                log.debug("🔍 Found stock update by ID {}: {}", id, result.isPresent());
                return result;
                
            } catch (Exception e) {
                log.error("❌ Failed to find stock update by ID: {}", id, e);
                throw new PersistenceException("Failed to find stock update: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<List<StockUpdate>> findByProductId(ProductId productId) {
        log.debug("🔍 Finding stock updates by product ID: {}", productId.getValue());
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                List<StockUpdate> result = stockUpdatesByProduct.getOrDefault(productId.getValue(), new ArrayList<>());
                log.debug("🔍 Found {} stock updates for product: {}", result.size(), productId.getValue());
                return new ArrayList<>(result); // Return defensive copy
                
            } catch (Exception e) {
                log.error("❌ Failed to find stock updates by product ID: {}", productId.getValue(), e);
                throw new PersistenceException("Failed to find stock updates by product: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<List<StockUpdate>> findByLocation(DistributionCenter distributionCenter, Branch branch) {
        log.debug("🔍 Finding stock updates by location: {}-{}", 
                distributionCenter.getCode(), branch.getCode());
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                String locationKey = createLocationKey(distributionCenter, branch);
                List<StockUpdate> result = stockUpdatesByLocation.getOrDefault(locationKey, new ArrayList<>());
                log.debug("🔍 Found {} stock updates for location: {}-{}", 
                        result.size(), distributionCenter.getCode(), branch.getCode());
                return new ArrayList<>(result); // Return defensive copy
                
            } catch (Exception e) {
                log.error("❌ Failed to find stock updates by location: {}-{}", 
                        distributionCenter.getCode(), branch.getCode(), e);
                throw new PersistenceException("Failed to find stock updates by location: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<List<StockUpdate>> findByCorrelationId(CorrelationId correlationId) {
        log.debug("🔍 Finding stock updates by correlation ID: {}", correlationId.getValue());
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                List<StockUpdate> result = stockUpdates.values().stream()
                        .filter(update -> update.getCorrelationId().equals(correlationId))
                        .toList();
                        
                log.debug("🔍 Found {} stock updates for correlation ID: {}", result.size(), correlationId.getValue());
                return new ArrayList<>(result); // Return defensive copy
                
            } catch (Exception e) {
                log.error("❌ Failed to find stock updates by correlation ID: {}", correlationId.getValue(), e);
                throw new PersistenceException("Failed to find stock updates by correlation ID: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<List<StockUpdate>> findByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        log.debug("🔍 Finding stock updates by date range: {} to {}", startDate, endDate);
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                List<StockUpdate> result = stockUpdates.values().stream()
                        .filter(update -> {
                            LocalDateTime updateTime = update.getCreatedAt();
                            return !updateTime.isBefore(startDate) && !updateTime.isAfter(endDate);
                        })
                        .sorted(Comparator.comparing(StockUpdate::getCreatedAt).reversed())
                        .toList();
                        
                log.debug("🔍 Found {} stock updates in date range: {} to {}", 
                        result.size(), startDate, endDate);
                return new ArrayList<>(result); // Return defensive copy
                
            } catch (Exception e) {
                log.error("❌ Failed to find stock updates by date range: {} to {}", 
                        startDate, endDate, e);
                throw new PersistenceException("Failed to find stock updates by date range: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<Boolean> existsById(String id) {
        log.debug("🔍 Checking if stock update exists by ID: {}", id);
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                boolean exists = stockUpdates.containsKey(id);
                log.debug("🔍 Stock update exists by ID {}: {}", id, exists);
                return exists;
                
            } catch (Exception e) {
                log.error("❌ Failed to check existence of stock update by ID: {}", id, e);
                throw new PersistenceException("Failed to check stock update existence: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<Long> countByProductId(ProductId productId) {
        log.debug("🔍 Counting stock updates by product ID: {}", productId.getValue());
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                long count = stockUpdatesByProduct.getOrDefault(productId.getValue(), new ArrayList<>()).size();
                log.debug("🔍 Found {} stock updates for product: {}", count, productId.getValue());
                return count;
                
            } catch (Exception e) {
                log.error("❌ Failed to count stock updates by product ID: {}", productId.getValue(), e);
                throw new PersistenceException("Failed to count stock updates by product: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<Void> deleteById(String id) {
        log.debug("🗑️ Deleting stock update by ID: {}", id);
        
        return CompletableFuture.runAsync(() -> {
            try {
                StockUpdate removed = stockUpdates.remove(id);
                if (removed != null) {
                    // Remove from product index
                    String productId = removed.getProductId().getValue();
                    List<StockUpdate> productUpdates = stockUpdatesByProduct.get(productId);
                    if (productUpdates != null) {
                        productUpdates.removeIf(update -> update.getId().equals(id));
                        if (productUpdates.isEmpty()) {
                            stockUpdatesByProduct.remove(productId);
                        }
                    }
                    
                    // Remove from location index
                    String locationKey = createLocationKey(removed.getDistributionCenter(), removed.getBranch());
                    List<StockUpdate> locationUpdates = stockUpdatesByLocation.get(locationKey);
                    if (locationUpdates != null) {
                        locationUpdates.removeIf(update -> update.getId().equals(id));
                        if (locationUpdates.isEmpty()) {
                            stockUpdatesByLocation.remove(locationKey);
                        }
                    }
                    
                    log.debug("✅ Successfully deleted stock update: {}", id);
                } else {
                    log.debug("⚠️ Stock update not found for deletion: {}", id);
                }
                
            } catch (Exception e) {
                log.error("❌ Failed to delete stock update by ID: {}", id, e);
                throw new PersistenceException("Failed to delete stock update: " + e.getMessage(), e);
            }
        });
    }

    @Override
    public CompletableFuture<Void> deleteAll() {
        log.debug("🗑️ Deleting all stock updates");
        
        return CompletableFuture.runAsync(() -> {
            try {
                stockUpdates.clear();
                stockUpdatesByProduct.clear();
                stockUpdatesByLocation.clear();
                log.debug("✅ Successfully deleted all stock updates");
                
            } catch (Exception e) {
                log.error("❌ Failed to delete all stock updates", e);
                throw new PersistenceException("Failed to delete all stock updates: " + e.getMessage(), e);
            }
        });
    }

    // ==================== HELPER METHODS ====================

    private String createLocationKey(DistributionCenter distributionCenter, Branch branch) {
        return distributionCenter.getCode() + "-" + branch.getCode();
    }

    /**
     * Get storage statistics for monitoring
     */
    public Map<String, Object> getStorageStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalStockUpdates", stockUpdates.size());
        stats.put("uniqueProducts", stockUpdatesByProduct.size());
        stats.put("uniqueLocations", stockUpdatesByLocation.size());
        stats.put("memoryUsageEstimate", estimateMemoryUsage());
        return stats;
    }

    private long estimateMemoryUsage() {
        // Rough estimate - in production you'd use more sophisticated memory profiling
        return stockUpdates.size() * 1024; // Estimate 1KB per stock update
    }

    /**
     * Exception thrown when persistence operations fail
     */
    public static class PersistenceException extends RuntimeException {
        public PersistenceException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
