package com.kbnt.virtualstock.infrastructure.adapter.output.repository;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.output.StockRepositoryPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * JPA Stock Repository Adapter - IMPLEMENTAÇÃO COMPLETA
 * Implements the output port for stock persistence using Spring Data JPA
 * Follows hexagonal architecture principles with proper domain isolation
 */
@Slf4j
@Repository
@RequiredArgsConstructor
public class JpaStockRepositoryAdapter implements StockRepositoryPort {
    
    private final SpringDataStockRepository springDataRepository;
    
    @Override
    public Stock save(Stock stock) {
        log.debug("Saving stock: {}", stock.getStockId().getValue());
        StockEntity entity = mapToEntity(stock);
        StockEntity savedEntity = springDataRepository.save(entity);
        Stock savedStock = mapToDomainModel(savedEntity);
        log.debug("Stock saved successfully: {}", savedStock.getStockId().getValue());
        return savedStock;
    }
    
    @Override
    public Optional<Stock> findById(Stock.StockId stockId) {
        log.debug("Finding stock by stockId: {}", stockId.getValue());
        return springDataRepository.findByStockId(stockId.getValue())
                .map(this::mapToDomainModel);
    }
    
    @Override
    public Optional<Stock> findByProductId(Stock.ProductId productId) {
        log.debug("Finding stock by productId: {}", productId.getValue());
        return springDataRepository.findByProductId(productId.getValue())
                .map(this::mapToDomainModel);
    }
    
    @Override
    public Optional<Stock> findBySymbol(String symbol) {
        log.debug("Finding stock by symbol: {}", symbol);
        return springDataRepository.findBySymbol(symbol)
                .map(this::mapToDomainModel);
    }
    
    @Override
    public List<Stock> findAll() {
        log.debug("Finding all stocks");
        return springDataRepository.findAll()
                .stream()
                .map(this::mapToDomainModel)
                .collect(Collectors.toList());
    }
    
    @Override
    public List<Stock> findByStatus(Stock.StockStatus status) {
        log.debug("Finding stocks by status: {}", status);
        StockEntity.StockStatus entityStatus = mapToEntityStatus(status);
        return springDataRepository.findByStatus(entityStatus)
                .stream()
                .map(this::mapToDomainModel)
                .collect(Collectors.toList());
    }
    
    @Override
    public List<Stock> findLowStock(Integer threshold) {
        log.debug("Finding low stock items with threshold: {}", threshold);
        return springDataRepository.findByQuantityLessThanEqual(threshold)
                .stream()
                .map(this::mapToDomainModel)
                .collect(Collectors.toList());
    }
    
    @Override
    public void deleteById(Stock.StockId stockId) {
        log.debug("Deleting stock: {}", stockId.getValue());
        springDataRepository.findByStockId(stockId.getValue())
                .ifPresentOrElse(
                    entity -> {
                        springDataRepository.delete(entity);
                        log.debug("Stock deleted successfully: {}", stockId.getValue());
                    },
                    () -> log.warn("Stock not found for deletion: {}", stockId.getValue())
                );
    }
    
    @Override
    public boolean existsByProductId(Stock.ProductId productId) {
        log.debug("Checking if stock exists for productId: {}", productId.getValue());
        boolean exists = springDataRepository.existsByProductId(productId.getValue());
        log.debug("Stock exists for productId {}: {}", productId.getValue(), exists);
        return exists;
    }
    
    @Override
    public long count() {
        long total = springDataRepository.count();
        log.debug("Total stocks count: {}", total);
        return total;
    }
    
    @Override
    public long countByStatus(Stock.StockStatus status) {
        StockEntity.StockStatus entityStatus = mapToEntityStatus(status);
        long count = springDataRepository.countByStatus(entityStatus);
        log.debug("Stocks count for status {}: {}", status, count);
        return count;
    }
    
    /**
     * Additional method to find stocks with available quantity
     */
    public List<Stock> findAllWithAvailableStock() {
        log.debug("Finding all stocks with available quantity");
        return springDataRepository.findAllWithAvailableStock()
                .stream()
                .map(this::mapToDomainModel)
                .collect(Collectors.toList());
    }
    
    /**
     * Additional method to find stock by product with available quantity
     */
    public Optional<Stock> findByProductIdWithAvailableStock(String productId) {
        log.debug("Finding stock by productId with available quantity: {}", productId);
        return springDataRepository.findByProductIdWithAvailableStock(productId)
                .map(this::mapToDomainModel);
    }
    
    // ==================== MAPPING METHODS ====================
    
    /**
     * Maps JPA entity to domain model
     * Ensures proper separation between persistence and domain layers
     */
    private Stock mapToDomainModel(StockEntity entity) {
        if (entity == null) {
            return null;
        }
        
        return Stock.builder()
                .stockId(Stock.StockId.builder().value(entity.getStockId()).build())
                .productId(Stock.ProductId.builder().value(entity.getProductId()).build())
                .symbol(entity.getSymbol())
                .productName(entity.getProductName())
                .quantity(entity.getQuantity())
                .unitPrice(entity.getUnitPrice())
                .status(mapTodomainStatus(entity.getStatus()))
                .lastUpdated(entity.getLastUpdated())
                .lastUpdatedBy(entity.getLastUpdatedBy())
                .build();
    }
    
    /**
     * Maps domain model to JPA entity
     * Handles both new entities and updates to existing ones
     */
    private StockEntity mapToEntity(Stock domain) {
        if (domain == null) {
            return null;
        }
        
        // For updates, try to find existing entity to preserve JPA ID
        StockEntity entity = springDataRepository.findByStockId(domain.getStockId().getValue())
                .orElse(new StockEntity());
        
        entity.setStockId(domain.getStockId().getValue());
        entity.setProductId(domain.getProductId().getValue());
        entity.setSymbol(domain.getSymbol());
        entity.setProductName(domain.getProductName());
        entity.setQuantity(domain.getQuantity());
        entity.setUnitPrice(domain.getUnitPrice());
        entity.setStatus(mapToEntityStatus(domain.getStatus()));
        entity.setLastUpdated(domain.getLastUpdated());
        entity.setLastUpdatedBy(domain.getLastUpdatedBy());
        
        return entity;
    }
    
    /**
     * Maps entity status to domain status
     */
    private Stock.StockStatus mapTodomainStatus(StockEntity.StockStatus entityStatus) {
        if (entityStatus == null) {
            return Stock.StockStatus.AVAILABLE;
        }
        return Stock.StockStatus.valueOf(entityStatus.name());
    }
    
    /**
     * Maps domain status to entity status  
     */
    private StockEntity.StockStatus mapToEntityStatus(Stock.StockStatus domainStatus) {
        if (domainStatus == null) {
            return StockEntity.StockStatus.AVAILABLE;
        }
        return StockEntity.StockStatus.valueOf(domainStatus.name());
    }
}
