package com.kbnt.virtualstock.application.service;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.model.StockUpdatedEvent;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;
import com.kbnt.virtualstock.domain.port.output.StockEventPublisherPort;
import com.kbnt.virtualstock.domain.port.output.StockRepositoryPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Stock Management Application Service
 * 
 * Implements the core business use cases for stock management.
 * Coordinates between domain logic and infrastructure adapters.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class StockManagementApplicationService implements StockManagementUseCase {
    
    private final StockRepositoryPort stockRepository;
    private final StockEventPublisherPort eventPublisher;
    
    @Override
    public StockCreationResult createStock(CreateStockCommand command) {
        try {
            log.info("Creating stock for product: {}", command.getProductId().getValue());
            
            // Check if stock already exists
            if (stockRepository.existsByProductId(command.getProductId())) {
                return StockCreationResult.failure(
                    "Stock already exists for product: " + command.getProductId().getValue());
            }
            
            // Create stock domain entity
            Stock stock = Stock.builder()
                    .stockId(Stock.StockId.generate())
                    .productId(command.getProductId())
                    .symbol(command.getSymbol())
                    .productName(command.getProductName())
                    .quantity(command.getInitialQuantity())
                    .unitPrice(command.getUnitPrice())
                    .status(determineInitialStatus(command.getInitialQuantity()))
                    .lastUpdated(LocalDateTime.now())
                    .lastUpdatedBy(command.getCreatedBy())
                    .build();
            
            // Save to repository
            Stock savedStock = stockRepository.save(stock);
            
            // Create domain event
            StockUpdatedEvent event = StockUpdatedEvent.forCreation(savedStock, command.getCreatedBy());
            
            // Publish event asynchronously
            eventPublisher.publishStockUpdatedAsync(event);
            
            log.info("Stock created successfully for product: {} with ID: {}", 
                    command.getProductId().getValue(), savedStock.getStockId().getValue());
            
            return StockCreationResult.success(savedStock, event);
            
        } catch (Exception e) {
            log.error("Error creating stock for product: {}", command.getProductId().getValue(), e);
            return StockCreationResult.failure("Failed to create stock: " + e.getMessage());
        }
    }
    
    @Override
    public StockUpdateResult updateStockQuantity(UpdateStockQuantityCommand command) {
        try {
            log.info("Updating stock quantity for stock ID: {}", command.getStockId().getValue());
            
            Optional<Stock> stockOpt = stockRepository.findById(command.getStockId());
            if (stockOpt.isEmpty()) {
                return StockUpdateResult.failure("Stock not found: " + command.getStockId().getValue());
            }
            
            Stock currentStock = stockOpt.get();
            Stock updatedStock = currentStock.updateQuantity(command.getNewQuantity(), command.getUpdatedBy());
            
            // Save updated stock
            Stock savedStock = stockRepository.save(updatedStock);
            
            // Create domain event
            StockUpdatedEvent event = StockUpdatedEvent.forQuantityUpdate(
                    currentStock, savedStock, command.getUpdatedBy(), command.getReason());
            
            // Publish event asynchronously
            eventPublisher.publishStockUpdatedAsync(event);
            
            log.info("Stock quantity updated successfully for stock ID: {} from {} to {}", 
                    command.getStockId().getValue(), currentStock.getQuantity(), savedStock.getQuantity());
            
            return StockUpdateResult.success(savedStock, event);
            
        } catch (Exception e) {
            log.error("Error updating stock quantity for stock ID: {}", command.getStockId().getValue(), e);
            return StockUpdateResult.failure("Failed to update stock quantity: " + e.getMessage());
        }
    }
    
    @Override
    public StockUpdateResult updateStockPrice(UpdateStockPriceCommand command) {
        try {
            log.info("Updating stock price for stock ID: {}", command.getStockId().getValue());
            
            Optional<Stock> stockOpt = stockRepository.findById(command.getStockId());
            if (stockOpt.isEmpty()) {
                return StockUpdateResult.failure("Stock not found: " + command.getStockId().getValue());
            }
            
            Stock currentStock = stockOpt.get();
            Stock updatedStock = currentStock.updatePrice(command.getNewPrice(), command.getUpdatedBy());
            
            // Save updated stock
            Stock savedStock = stockRepository.save(updatedStock);
            
            // Create domain event
            StockUpdatedEvent event = StockUpdatedEvent.forPriceUpdate(
                    currentStock, savedStock, command.getUpdatedBy(), command.getReason());
            
            // Publish event asynchronously
            eventPublisher.publishStockUpdatedAsync(event);
            
            log.info("Stock price updated successfully for stock ID: {} from {} to {}", 
                    command.getStockId().getValue(), currentStock.getUnitPrice(), savedStock.getUnitPrice());
            
            return StockUpdateResult.success(savedStock, event);
            
        } catch (Exception e) {
            log.error("Error updating stock price for stock ID: {}", command.getStockId().getValue(), e);
            return StockUpdateResult.failure("Failed to update stock price: " + e.getMessage());
        }
    }
    
    @Override
    public StockReservationResult reserveStock(ReserveStockCommand command) {
        try {
            log.info("Reserving {} units of stock ID: {}", 
                    command.getQuantityToReserve(), command.getStockId().getValue());
            
            Optional<Stock> stockOpt = stockRepository.findById(command.getStockId());
            if (stockOpt.isEmpty()) {
                return StockReservationResult.failure("Stock not found: " + command.getStockId().getValue());
            }
            
            Stock currentStock = stockOpt.get();
            
            if (!currentStock.canReserve(command.getQuantityToReserve())) {
                return StockReservationResult.failure(
                        String.format("Cannot reserve %d units. Available: %d, Status: %s", 
                                command.getQuantityToReserve(), currentStock.getQuantity(), currentStock.getStatus()));
            }
            
            Stock updatedStock = currentStock.reserve(command.getQuantityToReserve(), command.getReservedBy());
            
            // Save updated stock
            Stock savedStock = stockRepository.save(updatedStock);
            
            // Create domain event
            StockUpdatedEvent event = StockUpdatedEvent.forReservation(
                    currentStock, savedStock, command.getReservedBy(), command.getReason());
            
            // Publish event asynchronously
            eventPublisher.publishStockUpdatedAsync(event);
            
            log.info("Stock reserved successfully - {} units of stock ID: {} reserved, remaining: {}", 
                    command.getQuantityToReserve(), command.getStockId().getValue(), savedStock.getQuantity());
            
            return StockReservationResult.success(savedStock, event, command.getQuantityToReserve());
            
        } catch (Exception e) {
            log.error("Error reserving stock for stock ID: {}", command.getStockId().getValue(), e);
            return StockReservationResult.failure("Failed to reserve stock: " + e.getMessage());
        }
    }
    
    @Override
    @Transactional(readOnly = true)
    public Optional<Stock> getStockById(Stock.StockId stockId) {
        log.debug("Retrieving stock by ID: {}", stockId.getValue());
        return stockRepository.findById(stockId);
    }
    
    @Override
    @Transactional(readOnly = true)
    public Optional<Stock> getStockByProductId(Stock.ProductId productId) {
        log.debug("Retrieving stock by product ID: {}", productId.getValue());
        return stockRepository.findByProductId(productId);
    }
    
    @Override
    @Transactional(readOnly = true)
    public Optional<Stock> getStockBySymbol(String symbol) {
        log.debug("Retrieving stock by symbol: {}", symbol);
        return stockRepository.findBySymbol(symbol);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<Stock> getAllStocks() {
        log.debug("Retrieving all stocks");
        return stockRepository.findAll();
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<Stock> getStocksByStatus(Stock.StockStatus status) {
        log.debug("Retrieving stocks by status: {}", status);
        return stockRepository.findByStatus(status);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<Stock> getLowStockItems() {
        log.debug("Retrieving low stock items");
        return stockRepository.findLowStock(10);
    }
    
    private Stock.StockStatus determineInitialStatus(Integer quantity) {
        if (quantity == null || quantity == 0) {
            return Stock.StockStatus.OUT_OF_STOCK;
        } else if (quantity < 10) {
            return Stock.StockStatus.PENDING_RESTOCK;
        } else {
            return Stock.StockStatus.AVAILABLE;
        }
    }
}
