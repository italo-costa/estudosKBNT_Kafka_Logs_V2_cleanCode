package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;

/**
 * Modular implementation for ReserveStockCommand used by REST adapter
 */
public class ReserveStockCommandImpl implements StockManagementUseCase.ReserveStockCommand {
    private final Stock.StockId stockId;
    private final Integer quantityToReserve;
    private final String reservedBy;
    private final String reason;

    public ReserveStockCommandImpl(String stockId, ReserveStockRequest request) {
        this.stockId = Stock.StockId.builder().value(stockId).build();
        this.quantityToReserve = request.getQuantityToReserve();
        this.reservedBy = request.getReservedBy();
        this.reason = request.getReason();
    }

    @Override
    public Stock.StockId getStockId() { return stockId; }
    @Override
    public Integer getQuantityToReserve() { return quantityToReserve; }
    @Override
    public String getReservedBy() { return reservedBy; }
    @Override
    public String getReason() { return reason; }
}
