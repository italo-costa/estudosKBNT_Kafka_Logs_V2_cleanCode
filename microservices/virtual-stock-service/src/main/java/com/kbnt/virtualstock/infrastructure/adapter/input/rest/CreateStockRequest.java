package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

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
	private Integer initialQuantity;
	@NotNull(message = "Unit price is required")
	@DecimalMin(value = "0.0", inclusive = false, message = "Unit price must be positive")
	private BigDecimal unitPrice;
	@NotBlank(message = "Created by is required")
	private String createdBy;

	public String getProductId() { return productId; }
	public String getSymbol() { return symbol; }
	public String getProductName() { return productName; }
	public Integer getInitialQuantity() { return initialQuantity; }
	public BigDecimal getUnitPrice() { return unitPrice; }
	public String getCreatedBy() { return createdBy; }

	public void setProductId(String productId) { this.productId = productId; }
	public void setSymbol(String symbol) { this.symbol = symbol; }
	public void setProductName(String productName) { this.productName = productName; }
	public void setInitialQuantity(Integer initialQuantity) { this.initialQuantity = initialQuantity; }
	public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
	public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
}
