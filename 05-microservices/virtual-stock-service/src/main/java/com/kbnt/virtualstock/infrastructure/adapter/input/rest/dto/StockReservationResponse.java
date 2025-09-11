package com.kbnt.virtualstock.infrastructure.adapter.input.rest;

public class StockReservationResponse {
	private StockResponse stock;
	private Integer reservedQuantity;
	private String reservedAt;

	public StockReservationResponse() {}
	public StockReservationResponse(StockResponse stock, Integer reservedQuantity, String reservedAt) {
		this.stock = stock;
		this.reservedQuantity = reservedQuantity;
		this.reservedAt = reservedAt;
	}
	public StockResponse getStock() { return stock; }
	public Integer getReservedQuantity() { return reservedQuantity; }
	public String getReservedAt() { return reservedAt; }
	public void setStock(StockResponse stock) { this.stock = stock; }
	public void setReservedQuantity(Integer reservedQuantity) { this.reservedQuantity = reservedQuantity; }
	public void setReservedAt(String reservedAt) { this.reservedAt = reservedAt; }
	public static Builder builder() { return new Builder(); }
	public static class Builder {
		private StockResponse stock;
		private Integer reservedQuantity;
		private String reservedAt;
		public Builder stock(StockResponse stock) { this.stock = stock; return this; }
		public Builder reservedQuantity(Integer reservedQuantity) { this.reservedQuantity = reservedQuantity; return this; }
		public Builder reservedAt(java.time.LocalDateTime reservedAt) { this.reservedAt = reservedAt != null ? reservedAt.toString() : null; return this; }
		public StockReservationResponse build() {
			return new StockReservationResponse(stock, reservedQuantity, reservedAt);
		}
	}
}
