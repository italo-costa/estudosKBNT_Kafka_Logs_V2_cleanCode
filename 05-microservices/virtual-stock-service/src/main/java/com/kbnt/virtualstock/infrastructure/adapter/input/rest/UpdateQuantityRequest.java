package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

import javax.validation.constraints.*;

public class UpdateQuantityRequest {
	@NotNull(message = "New quantity is required")
	@Min(value = 0, message = "New quantity must be non-negative")
	private Integer newQuantity;
	@NotBlank(message = "Updated by is required")
	private String updatedBy;
	private String reason;

	public Integer getNewQuantity() { return newQuantity; }
	public String getUpdatedBy() { return updatedBy; }
	public String getReason() { return reason; }

	public void setNewQuantity(Integer newQuantity) { this.newQuantity = newQuantity; }
	public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }
	public void setReason(String reason) { this.reason = reason; }
}
