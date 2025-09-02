package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;

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
