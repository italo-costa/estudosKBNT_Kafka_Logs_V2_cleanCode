package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import javax.validation.constraints.*;

public class ReserveStockRequest {
	@NotNull(message = "Quantity to reserve is required")
	@Min(value = 1, message = "Quantity to reserve must be positive")
	private Integer quantityToReserve;
	@NotBlank(message = "Reserved by is required")
	private String reservedBy;
	private String reason;

	public Integer getQuantityToReserve() { return quantityToReserve; }
	public String getReservedBy() { return reservedBy; }
	public String getReason() { return reason; }

	public void setQuantityToReserve(Integer quantityToReserve) { this.quantityToReserve = quantityToReserve; }
	public void setReservedBy(String reservedBy) { this.reservedBy = reservedBy; }
	public void setReason(String reason) { this.reason = reason; }
}
