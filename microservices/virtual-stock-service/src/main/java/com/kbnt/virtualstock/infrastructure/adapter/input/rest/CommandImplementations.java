package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;

/**
 * Command Implementations for REST Adapter
 */

public class CreateStockCommandImpl implements StockManagementUseCase.CreateStockCommand {
    private final CreateStockRequest request;
    
    public CreateStockCommandImpl(CreateStockRequest request) {
        this.request = request;
    }
    
    @Override
    public Stock.ProductId getProductId() {
        return Stock.ProductId.of(request.getProductId());
    }
    
    @Override
    public String getSymbol() {
        return request.getSymbol();
    }
    
    @Override
    public String getProductName() {
        return request.getProductName();
    }
    
    @Override
    public Integer getInitialQuantity() {
        return request.getInitialQuantity();
    }
    
    @Override
    public java.math.BigDecimal getUnitPrice() {
        return request.getUnitPrice();
    }
    
    @Override
    public String getCreatedBy() {
        return request.getCreatedBy();
    }
}

public class UpdateStockQuantityCommandImpl implements StockManagementUseCase.UpdateStockQuantityCommand {
    private final String stockId;
    private final UpdateQuantityRequest request;
    
    public UpdateStockQuantityCommandImpl(String stockId, UpdateQuantityRequest request) {
        this.stockId = stockId;
        this.request = request;
    }
    
    @Override
    public Stock.StockId getStockId() {
        return Stock.StockId.builder().value(stockId).build();
    }
    
    @Override
    public Integer getNewQuantity() {
        return request.getNewQuantity();
    }
    
    @Override
    public String getUpdatedBy() {
        return request.getUpdatedBy();
    }
    
    @Override
    public String getReason() {
        return request.getReason();
    }
}

public class UpdateStockPriceCommandImpl implements StockManagementUseCase.UpdateStockPriceCommand {
    private final String stockId;
    private final UpdatePriceRequest request;
    
    public UpdateStockPriceCommandImpl(String stockId, UpdatePriceRequest request) {
        this.stockId = stockId;
        this.request = request;
    }
    
    @Override
    public Stock.StockId getStockId() {
        return Stock.StockId.builder().value(stockId).build();
    }
    
    @Override
    public java.math.BigDecimal getNewPrice() {
        return request.getNewPrice();
    }
    
    @Override
    public String getUpdatedBy() {
        return request.getUpdatedBy();
    }
    
    @Override
    public String getReason() {
        return request.getReason();
    }
}

public class ReserveStockCommandImpl implements StockManagementUseCase.ReserveStockCommand {
    private final String stockId;
    private final ReserveStockRequest request;
    
    public ReserveStockCommandImpl(String stockId, ReserveStockRequest request) {
        this.stockId = stockId;
        this.request = request;
    }
    
    @Override
    public Stock.StockId getStockId() {
        return Stock.StockId.builder().value(stockId).build();
    }
    
    @Override
    public Integer getQuantityToReserve() {
        return request.getQuantityToReserve();
    }
    
    @Override
    public String getReservedBy() {
        return request.getReservedBy();
    }
    
    @Override
    public String getReason() {
        return request.getReason();
    }
}
