package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import java.math.BigDecimal;
import com.kbnt.virtualstock.domain.model.Stock;

public class StockResponse {
	private String stockId;
	private String productId;
	private String symbol;
	private String productName;
	private Integer quantity;
	private BigDecimal unitPrice;
	private String status;
	private String lastUpdatedBy;
	private String lastUpdated;
	private BigDecimal totalValue;
	private boolean isLowStock;
	private boolean isAvailable;

	public StockResponse() {}
	public StockResponse(String stockId, String productId, String symbol, String productName, Integer quantity, BigDecimal unitPrice, String status, String lastUpdatedBy, String lastUpdated, BigDecimal totalValue, boolean isLowStock, boolean isAvailable) {
		this.stockId = stockId;
		this.productId = productId;
		this.symbol = symbol;
		this.productName = productName;
		this.quantity = quantity;
		this.unitPrice = unitPrice;
		this.status = status;
		this.lastUpdatedBy = lastUpdatedBy;
		this.lastUpdated = lastUpdated;
		this.totalValue = totalValue;
		this.isLowStock = isLowStock;
		this.isAvailable = isAvailable;
	}
	public String getStockId() { return stockId; }
	public String getProductId() { return productId; }
	public String getSymbol() { return symbol; }
	public String getProductName() { return productName; }
	public Integer getQuantity() { return quantity; }
	public BigDecimal getUnitPrice() { return unitPrice; }
	public String getStatus() { return status; }
	public String getLastUpdatedBy() { return lastUpdatedBy; }
	public String getLastUpdated() { return lastUpdated; }
	public BigDecimal getTotalValue() { return totalValue; }
	public boolean isLowStock() { return isLowStock; }
	public boolean isAvailable() { return isAvailable; }
	public void setStockId(String stockId) { this.stockId = stockId; }
	public void setProductId(String productId) { this.productId = productId; }
	public void setSymbol(String symbol) { this.symbol = symbol; }
	public void setProductName(String productName) { this.productName = productName; }
	public void setQuantity(Integer quantity) { this.quantity = quantity; }
	public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
	public void setStatus(String status) { this.status = status; }
	public void setLastUpdatedBy(String lastUpdatedBy) { this.lastUpdatedBy = lastUpdatedBy; }
	public void setLastUpdated(String lastUpdated) { this.lastUpdated = lastUpdated; }
	public void setTotalValue(BigDecimal totalValue) { this.totalValue = totalValue; }
	public void setLowStock(boolean isLowStock) { this.isLowStock = isLowStock; }
	public void setAvailable(boolean isAvailable) { this.isAvailable = isAvailable; }
	public static StockResponse fromDomain(com.kbnt.virtualstock.domain.model.Stock stock) {
		if (stock == null) return null;
		return new StockResponse(
			stock.getStockId() != null ? stock.getStockId().getValue() : null,
			stock.getProductId() != null ? stock.getProductId().getValue() : null,
			stock.getSymbol(),
			stock.getProductName(),
			stock.getQuantity(),
			stock.getUnitPrice(),
			stock.getStatus() != null ? stock.getStatus().name() : null,
			stock.getLastUpdatedBy(),
			stock.getLastUpdated() != null ? stock.getLastUpdated().toString() : null,
			stock.getUnitPrice() != null && stock.getQuantity() != null ? stock.getUnitPrice().multiply(new java.math.BigDecimal(stock.getQuantity())) : null,
			stock.getQuantity() != null && stock.getQuantity() < 10,
			stock.getStatus() != null && stock.getStatus().name().equalsIgnoreCase("AVAILABLE")
		);
	}
}
