package com.kbnt.virtualstock.infrastructure.adapter.output.repository;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.output.StockRepositoryPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * JPA Stock Repository Adapter - IMPLEMENTAÇÃO CORRIGIDA
 * Implements the output port for stock persistence using Spring Data JPA
 */
@Slf4j
@Repository
@RequiredArgsConstructor
public class JpaStockRepositoryAdapter implements StockRepositoryPort {
    
    private final SpringDataStockRepository springDataRepository;
    
    @Override
    public Optional<Stock> findByStockId(String stockId) {
        log.debug("Finding stock by stockId: {}", stockId);
        return springDataRepository.findByStockId(stockId)
                .map(this::mapToDomainModel);
    }
    
    @Override
    public Optional<Stock> findByProductId(String productId) {
        log.debug("Finding stock by productId: {}", productId);
        return springDataRepository.findByProductId(productId)
                .map(this::mapToDomainModel);
    }
    
    @Override
    public List<Stock> findByProductIdIn(List<String> productIds) {
        log.debug("Finding stocks by productIds: {}", productIds);
        return springDataRepository.findByProductIdIn(productIds)
                .stream()
                .map(this::mapToDomainModel)
                .toList();
    }
    
    @Override
    public List<Stock> findAll() {
        log.debug("Finding all stocks");
        return springDataRepository.findAll()
                .stream()
                .map(this::mapToDomainModel)
                .toList();
    }
    
    @Override
    public Stock save(Stock stock) {
        log.debug("Saving stock: {}", stock.getStockId());
        StockEntity entity = mapToEntity(stock);
        StockEntity savedEntity = springDataRepository.save(entity);
        return mapToDomainModel(savedEntity);
    }
    
    @Override
    public void delete(String stockId) {
        log.debug("Deleting stock: {}", stockId);
        springDataRepository.findByStockId(stockId)
                .ifPresent(springDataRepository::delete);
    }
    
    @Override
    public boolean existsByProductId(String productId) {
        log.debug("Checking if stock exists for productId: {}", productId);
        return springDataRepository.existsByProductId(productId);
    }
    
    // Mapping methods
    private Stock mapToDomainModel(StockEntity entity) {
        return Stock.builder()
                .stockId(entity.getStockId())
                .productId(entity.getProductId())
                .quantity(entity.getQuantity())
                .reservedQuantity(entity.getReservedQuantity())
                .lastUpdated(entity.getLastUpdated())
                .version(entity.getVersion())
                .build();
    }
    
    private StockEntity mapToEntity(Stock domain) {
        StockEntity entity = new StockEntity();
        entity.setStockId(domain.getStockId());
        entity.setProductId(domain.getProductId());
        entity.setQuantity(domain.getQuantity());
        entity.setReservedQuantity(domain.getReservedQuantity());
        entity.setLastUpdated(domain.getLastUpdated());
        entity.setVersion(domain.getVersion());
        return entity;
    }
}
