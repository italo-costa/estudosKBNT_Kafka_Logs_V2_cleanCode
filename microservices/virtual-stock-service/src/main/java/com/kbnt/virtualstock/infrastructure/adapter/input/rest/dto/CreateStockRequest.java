package com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto;

import com.kbnt.virtualstock.domain.model.Stock;
import java.math.BigDecimal;
import javax.validation.constraints.*;

public class CreateStockRequest {
	@NotBlank(message = "Product ID is required")
	private String productId;
	@NotBlank(message = "Symbol is required")
	@Size(min = 1, max = 10, message = "Symbol must be between 1 and 10 characters")
	private String symbol;
	@NotBlank(message = "Product name is required")
	@Size(min = 1, max = 100, message = "Product name must be between 1 and 100 characters")
	private String productName;
	@NotNull(message = "Initial quantity is required")
	@Min(value = 0, message = "Initial quantity must be non-negative")
	private Integer quantity;
	@NotNull(message = "Unit price is required")
	@DecimalMin(value = "0.0", inclusive = false, message = "Unit price must be positive")
	private BigDecimal unitPrice;
	@NotBlank(message = "Created by is required")
	private String createdBy;

	public Stock.ProductId getProductId() { return new Stock.ProductId(productId); }
	public String getSymbol() { return symbol; }
	public String getProductName() { return productName; }
	public Integer getQuantity() { return quantity; }
	public BigDecimal getUnitPrice() { return unitPrice; }
	public String getCreatedBy() { return createdBy; }

	public void setProductId(String productId) { this.productId = productId; }
	public void setSymbol(String symbol) { this.symbol = symbol; }
	public void setProductName(String productName) { this.productName = productName; }
	public void setQuantity(Integer quantity) { this.quantity = quantity; }
	public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
	public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
}
