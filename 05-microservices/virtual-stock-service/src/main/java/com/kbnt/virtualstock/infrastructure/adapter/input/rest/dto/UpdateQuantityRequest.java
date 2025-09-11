package com.kbnt.virtualstock.infrastructure.adapter.input.rest.dto;

import javax.validation.constraints.*;

public class UpdateQuantityRequest {
	@NotNull(message = "New quantity is required")
	@Min(value = 0, message = "New quantity must be non-negative")
	private Integer quantity;
	@NotBlank(message = "Updated by is required")
	private String updatedBy;
	private String reason;

	public Integer getQuantity() { return quantity; }
	public String getUpdatedBy() { return updatedBy; }
	public String getReason() { return reason; }

	public void setQuantity(Integer quantity) { this.quantity = quantity; }
	public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }
	public void setReason(String reason) { this.reason = reason; }
}
