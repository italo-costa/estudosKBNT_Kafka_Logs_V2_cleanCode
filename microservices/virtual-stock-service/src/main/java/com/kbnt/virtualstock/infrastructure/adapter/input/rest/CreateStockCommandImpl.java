package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;

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
