package com.kbnt.virtualstock.domain.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

public class Stock {
  private StockId stockId;
  private ProductId productId;
  private String symbol;
  private String productName;
  private Integer quantity;
  private BigDecimal unitPrice;
  private StockStatus status;
  private LocalDateTime lastUpdated;
  private String lastUpdatedBy;

  public Stock() {
  }

  /**
   * Constructor for Stock.
   */
  public Stock(StockId stockId, ProductId productId, String symbol, String productName, 
      Integer quantity, BigDecimal unitPrice, StockStatus status, 
      LocalDateTime lastUpdated, String lastUpdatedBy) {
    this.stockId = stockId;
    this.productId = productId;
    this.symbol = symbol;
    this.productName = productName;
    this.quantity = quantity;
    this.unitPrice = unitPrice;
    this.status = status;
    this.lastUpdated = lastUpdated;
    this.lastUpdatedBy = lastUpdatedBy;
  }

  public StockId getStockId() { 
    return stockId; 
  }

  public ProductId getProductId() { 
    return productId; 
  }

  public String getSymbol() { 
    return symbol; 
  }

  public String getProductName() { 
    return productName; 
  }

  public Integer getQuantity() { 
    return quantity; 
  }

  public BigDecimal getUnitPrice() { 
    return unitPrice; 
  }

  public StockStatus getStatus() { 
    return status; 
  }

  public LocalDateTime getLastUpdated() { 
    return lastUpdated; 
  }

  public String getLastUpdatedBy() { 
    return lastUpdatedBy; 
  }

  public static StockBuilder builder() { 
    return new StockBuilder(); 
  }

  /**
   * Stock Builder.
   */
  public static class StockBuilder {
    private StockId stockId;
    private ProductId productId;
    private String symbol;
    private String productName;
    private Integer quantity;
    private BigDecimal unitPrice;
    private StockStatus status;
    private LocalDateTime lastUpdated;
    private String lastUpdatedBy;

    public StockBuilder stockId(StockId stockId) { 
      this.stockId = stockId; 
      return this; 
    }

    public StockBuilder productId(ProductId productId) { 
      this.productId = productId; 
      return this; 
    }

    public StockBuilder symbol(String symbol) { 
      this.symbol = symbol; 
      return this; 
    }

    public StockBuilder productName(String productName) { 
      this.productName = productName; 
      return this; 
    }

    public StockBuilder quantity(Integer quantity) { 
      this.quantity = quantity; 
      return this; 
    }

    public StockBuilder unitPrice(BigDecimal unitPrice) { 
      this.unitPrice = unitPrice; 
      return this; 
    }

    public StockBuilder status(StockStatus status) { 
      this.status = status; 
      return this; 
    }

    public StockBuilder lastUpdated(LocalDateTime lastUpdated) { 
      this.lastUpdated = lastUpdated; 
      return this; 
    }

    public StockBuilder lastUpdatedBy(String lastUpdatedBy) { 
      this.lastUpdatedBy = lastUpdatedBy; 
      return this; 
    }

    public Stock build() {
      return new Stock(stockId, productId, symbol, productName, quantity, 
          unitPrice, status, lastUpdated, lastUpdatedBy);
    }
  }
  /**
   * Stock Value Object - Unique identifier.
   */
  public static class StockId {
    private String value;

    public StockId() {
    }

    public StockId(String value) { 
      this.value = value; 
    }

    public String getValue() { 
      return value; 
    }

    public void setValue(String value) { 
      this.value = value; 
    }

    public static StockId generate() {
      return new StockId(java.util.UUID.randomUUID().toString());
    }

    public static StockId builder() { 
      return new StockId(); 
    }

    public StockId value(String value) { 
      this.value = value; 
      return this; 
    }

    public StockId build() { 
      return this; 
    }

    @Override
    public boolean equals(Object obj) {
      if (this == obj) {
        return true;
      }
      if (obj == null || getClass() != obj.getClass()) {
        return false;
      }
      StockId stockId = (StockId) obj;
      return Objects.equals(value, stockId.value);
    }

    @Override
    public int hashCode() {
      return Objects.hash(value);
    }

    @Override
    public String toString() { 
      return value; 
    }
  }
  /**
   * Product Value Object - Product identifier.
   */
  public static class ProductId {
    private String value;

    public ProductId() {
    }

    public ProductId(String value) { 
      this.value = value; 
    }

    public String getValue() { 
      return value; 
    }

    public void setValue(String value) { 
      this.value = value; 
    }

    public static ProductId of(String productId) {
      return new ProductId(productId);
    }

    public static ProductId builder() { 
      return new ProductId(); 
    }

    public ProductId value(String value) { 
      this.value = value; 
      return this; 
    }

    public ProductId build() { 
      return this; 
    }

    @Override
    public boolean equals(Object obj) {
      if (this == obj) {
        return true;
      }
      if (obj == null || getClass() != obj.getClass()) {
        return false;
      }
      ProductId productId = (ProductId) obj;
      return Objects.equals(value, productId.value);
    }

    @Override
    public int hashCode() {
      return Objects.hash(value);
    }

    @Override
    public String toString() { 
      return value; 
    }
  }
  /**
   * Stock Status Enumeration.
   */
  public enum StockStatus {
    AVAILABLE,
    RESERVED,
    OUT_OF_STOCK,
    DISCONTINUED,
    PENDING_RESTOCK
  }

  /**
   * Business method to update stock quantity.
   */
  public Stock updateQuantity(Integer newQuantity, String updatedBy) {
    validateQuantity(newQuantity);

    StockStatus newStatus = determineStatusByQuantity(newQuantity);

    return Stock.builder()
        .stockId(this.stockId)
        .productId(this.productId)
        .symbol(this.symbol)
        .productName(this.productName)
        .quantity(newQuantity)
        .unitPrice(this.unitPrice)
        .status(newStatus)
        .lastUpdated(LocalDateTime.now())
        .lastUpdatedBy(updatedBy)
        .build();
  }

  /**
   * Business method to update stock price.
   */
  public Stock updatePrice(BigDecimal newPrice, String updatedBy) {
    validatePrice(newPrice);

    return Stock.builder()
        .stockId(this.stockId)
        .productId(this.productId)
        .symbol(this.symbol)
        .productName(this.productName)
        .quantity(this.quantity)
        .unitPrice(newPrice)
        .status(this.status)
        .lastUpdated(LocalDateTime.now())
        .lastUpdatedBy(updatedBy)
        .build();
  }

  /**
   * Business method to reserve stock.
   */
  public Stock reserve(Integer quantityToReserve, String reservedBy) {
    if (!canReserve(quantityToReserve)) {
      throw new IllegalArgumentException("Cannot reserve " + quantityToReserve 
          + " units. Available: " + this.quantity);
    }

    Integer remainingQuantity = this.quantity - quantityToReserve;
    StockStatus newStatus;
    if (remainingQuantity == 0) {
      newStatus = StockStatus.OUT_OF_STOCK;
    } else if (remainingQuantity < 10) {
      newStatus = StockStatus.PENDING_RESTOCK;
    } else {
      newStatus = StockStatus.AVAILABLE;
    }

    return Stock.builder()
        .stockId(this.stockId)
        .productId(this.productId)
        .symbol(this.symbol)
        .productName(this.productName)
        .quantity(remainingQuantity)
        .unitPrice(this.unitPrice)
        .status(newStatus)
        .lastUpdated(LocalDateTime.now())
        .lastUpdatedBy(reservedBy)
        .build();
  }

  /**
   * Business rule validation.
   */
  public boolean canReserve(Integer quantityToReserve) {
    return this.status == StockStatus.AVAILABLE 
        && this.quantity >= quantityToReserve
        && quantityToReserve > 0;
  }

  /**
   * Calculate total value of stock.
   */
  public BigDecimal getTotalValue() {
    return this.unitPrice.multiply(BigDecimal.valueOf(this.quantity));
  }

  /**
   * Business rule - is stock low?
   */
  public boolean isLowStock() {
    return this.quantity != null && this.quantity < 10;
  }

  /**
   * Business rule - is stock available?
   */
  public boolean isAvailable() {
    return this.status == StockStatus.AVAILABLE && this.quantity > 0;
  }

  private void validateQuantity(Integer quantity) {
    if (quantity == null || quantity < 0) {
      throw new IllegalArgumentException("Quantity must be non-negative");
    }
  }

  private void validatePrice(BigDecimal price) {
    if (price == null || price.compareTo(BigDecimal.ZERO) < 0) {
      throw new IllegalArgumentException("Price must be non-negative");
    }
  }

  private StockStatus determineStatusByQuantity(Integer quantity) {
    if (quantity == 0) {
      return StockStatus.OUT_OF_STOCK;
    } else if (quantity < 10) {
      return StockStatus.PENDING_RESTOCK;
    } else {
      return StockStatus.AVAILABLE;
    }
  }
}
