package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;

/**
 * Modular implementation for UpdateStockQuantityCommand used by REST adapter
 */
public class UpdateStockQuantityCommandImpl implements StockManagementUseCase.UpdateStockQuantityCommand {
    private final Stock.StockId stockId;
    private final Integer newQuantity;
    private final String updatedBy;
    private final String reason;

    public UpdateStockQuantityCommandImpl(String stockId, UpdateQuantityRequest request) {
        this.stockId = Stock.StockId.builder().value(stockId).build();
        this.newQuantity = request.getNewQuantity();
        this.updatedBy = request.getUpdatedBy();
        this.reason = request.getReason();
    }

    @Override
    public Stock.StockId getStockId() { return stockId; }
    @Override
    public Integer getNewQuantity() { return newQuantity; }
    @Override
    public String getUpdatedBy() { return updatedBy; }
    @Override
    public String getReason() { return reason; }
}
