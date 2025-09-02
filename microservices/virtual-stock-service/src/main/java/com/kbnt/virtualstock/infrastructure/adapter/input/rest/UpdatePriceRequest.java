package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import java.math.BigDecimal;
import javax.validation.constraints.*;

public class UpdatePriceRequest {
	@NotNull(message = "New price is required")
	@DecimalMin(value = "0.0", inclusive = false, message = "New price must be positive")
	private BigDecimal newPrice;
	@NotBlank(message = "Updated by is required")
	private String updatedBy;
	private String reason;

	public BigDecimal getNewPrice() { return newPrice; }
	public String getUpdatedBy() { return updatedBy; }
	public String getReason() { return reason; }

	public void setNewPrice(BigDecimal newPrice) { this.newPrice = newPrice; }
	public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }
	public void setReason(String reason) { this.reason = reason; }
}
