package com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto;

import java.math.BigDecimal;
import javax.validation.constraints.*;

public class UpdatePriceRequest {
	@NotNull(message = "New price is required")
	@DecimalMin(value = "0.0", inclusive = false, message = "New price must be positive")
	private BigDecimal price;
	@NotBlank(message = "Updated by is required")
	private String updatedBy;
	private String reason;

	public BigDecimal getPrice() { return price; }
	public String getUpdatedBy() { return updatedBy; }
	public String getReason() { return reason; }

	public void setPrice(BigDecimal price) { this.price = price; }
	public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }
	public void setReason(String reason) { this.reason = reason; }
}
