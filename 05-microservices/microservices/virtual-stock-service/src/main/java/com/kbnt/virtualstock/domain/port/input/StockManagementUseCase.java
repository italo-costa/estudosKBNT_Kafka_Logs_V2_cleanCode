package com.kbnt.virtualstock.domain.port.input;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.model.StockUpdatedEvent;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Stock Management Use Case - Input Port.
 * 
 * <p>Defines the core business operations for stock management.
 * Application services will implement this interface.</p>
 */
public interface StockManagementUseCase {

  /**
   * Create new stock item.
   * 
   * <p>Creates a new stock entry in the system.</p>
   */
  StockCreationResult createStock(CreateStockCommand command);

  /**
   * Update stock quantity.
   * 
   * <p>Updates the quantity of an existing stock item.</p>
   */
  StockUpdateResult updateStockQuantity(UpdateStockQuantityCommand command);

  /**
   * Update stock price.
   * 
   * <p>Updates the unit price of an existing stock item.</p>
   */
  StockUpdateResult updateStockPrice(UpdateStockPriceCommand command);

  /**
   * Reserve stock.
   * 
   * <p>Reserves a specified quantity of stock for future use.</p>
   */
  StockReservationResult reserveStock(ReserveStockCommand command);

  /**
   * Get stock by ID.
   * 
   * <p>Retrieves a stock item by its unique identifier.</p>
   */
  Optional<Stock> getStockById(Stock.StockId stockId);

  /**
   * Get stock by product ID.
   * 
   * <p>Retrieves a stock item by its product identifier.</p>
   */
  Optional<Stock> getStockByProductId(Stock.ProductId productId);

  /**
   * Get stock by symbol.
   * 
   * <p>Retrieves a stock item by its symbol.</p>
   */
  Optional<Stock> getStockBySymbol(String symbol);

  /**
   * Get all stocks.
   * 
   * <p>Retrieves all stock items in the system.</p>
   */
  List<Stock> getAllStocks();

  /**
   * Get stocks by status.
   * 
   * <p>Retrieves all stock items with a specific status.</p>
   */
  List<Stock> getStocksByStatus(Stock.StockStatus status);

  /**
   * Get low stock items.
   * 
   * <p>Retrieves all stock items that are below the minimum threshold.</p>
   */
  List<Stock> getLowStockItems();
  // Command objects

  interface CreateStockCommand {
    Stock.ProductId getProductId();
    
    String getSymbol();
    
    String getProductName();
    
    Integer getInitialQuantity();
    
    BigDecimal getUnitPrice();
    
    String getCreatedBy();
  }

  interface UpdateStockQuantityCommand {
    Stock.StockId getStockId();
    
    Integer getNewQuantity();
    
    String getUpdatedBy();
    
    String getReason();
  }

  interface UpdateStockPriceCommand {
    Stock.StockId getStockId();
    
    BigDecimal getNewPrice();
    
    String getUpdatedBy();
    
    String getReason();
  }

  interface ReserveStockCommand {
    Stock.StockId getStockId();
    
    Integer getQuantityToReserve();
    
    String getReservedBy();
    
    String getReason();
  }
  // Result objects

  interface StockCreationResult {
    boolean isSuccess();
    
    Stock getStock();
    
    StockUpdatedEvent getEvent();
    
    String getErrorMessage();

    static StockCreationResult success(Stock stock, StockUpdatedEvent event) {
      return new SuccessfulStockCreationResult(stock, event);
    }

    static StockCreationResult failure(String errorMessage) {
      return new FailedStockCreationResult(errorMessage);
    }
  }

  interface StockUpdateResult {
    boolean isSuccess();
    
    Stock getUpdatedStock();
    
    StockUpdatedEvent getEvent();
    
    String getErrorMessage();

    static StockUpdateResult success(Stock stock, StockUpdatedEvent event) {
      return new SuccessfulStockUpdateResult(stock, event);
    }

    static StockUpdateResult failure(String errorMessage) {
      return new FailedStockUpdateResult(errorMessage);
    }
  }

  interface StockReservationResult {
    boolean isSuccess();
    
    Stock getUpdatedStock();
    
    StockUpdatedEvent getEvent();
    
    Integer getReservedQuantity();
    
    String getErrorMessage();

    static StockReservationResult success(Stock stock, StockUpdatedEvent event, 
        Integer reservedQuantity) {
      return new SuccessfulStockReservationResult(stock, event, reservedQuantity);
    }

    static StockReservationResult failure(String errorMessage) {
      return new FailedStockReservationResult(errorMessage);
    }
  }
  // Implementation classes for results

  class SuccessfulStockCreationResult implements StockCreationResult {
    private final Stock stock;
    private final StockUpdatedEvent event;

    public SuccessfulStockCreationResult(Stock stock, StockUpdatedEvent event) {
      this.stock = stock;
      this.event = event;
    }

    @Override 
    public boolean isSuccess() { 
      return true; 
    }
    
    @Override 
    public Stock getStock() { 
      return stock; 
    }
    
    @Override 
    public StockUpdatedEvent getEvent() { 
      return event; 
    }
    
    @Override 
    public String getErrorMessage() { 
      return null; 
    }
  }

  class FailedStockCreationResult implements StockCreationResult {
    private final String errorMessage;

    public FailedStockCreationResult(String errorMessage) {
      this.errorMessage = errorMessage;
    }

    @Override 
    public boolean isSuccess() { 
      return false; 
    }
    
    @Override 
    public Stock getStock() { 
      return null; 
    }
    
    @Override 
    public StockUpdatedEvent getEvent() { 
      return null; 
    }
    
    @Override 
    public String getErrorMessage() { 
      return errorMessage; 
    }
  }
  class SuccessfulStockUpdateResult implements StockUpdateResult {
    private final Stock stock;
    private final StockUpdatedEvent event;

    public SuccessfulStockUpdateResult(Stock stock, StockUpdatedEvent event) {
      this.stock = stock;
      this.event = event;
    }

    @Override 
    public boolean isSuccess() { 
      return true; 
    }
    
    @Override 
    public Stock getUpdatedStock() { 
      return stock; 
    }
    
    @Override 
    public StockUpdatedEvent getEvent() { 
      return event; 
    }
    
    @Override 
    public String getErrorMessage() { 
      return null; 
    }
  }

  class FailedStockUpdateResult implements StockUpdateResult {
    private final String errorMessage;

    public FailedStockUpdateResult(String errorMessage) {
      this.errorMessage = errorMessage;
    }

    @Override 
    public boolean isSuccess() { 
      return false; 
    }
    
    @Override 
    public Stock getUpdatedStock() { 
      return null; 
    }
    
    @Override 
    public StockUpdatedEvent getEvent() { 
      return null; 
    }
    
    @Override 
    public String getErrorMessage() { 
      return errorMessage; 
    }
  }
  class SuccessfulStockReservationResult implements StockReservationResult {
    private final Stock stock;
    private final StockUpdatedEvent event;
    private final Integer reservedQuantity;

    public SuccessfulStockReservationResult(Stock stock, StockUpdatedEvent event, 
        Integer reservedQuantity) {
      this.stock = stock;
      this.event = event;
      this.reservedQuantity = reservedQuantity;
    }

    @Override 
    public boolean isSuccess() { 
      return true; 
    }
    
    @Override 
    public Stock getUpdatedStock() { 
      return stock; 
    }
    
    @Override 
    public StockUpdatedEvent getEvent() { 
      return event; 
    }
    
    @Override 
    public Integer getReservedQuantity() { 
      return reservedQuantity; 
    }
    
    @Override 
    public String getErrorMessage() { 
      return null; 
    }
  }

  class FailedStockReservationResult implements StockReservationResult {
    private final String errorMessage;

    public FailedStockReservationResult(String errorMessage) {
      this.errorMessage = errorMessage;
    }

    @Override 
    public boolean isSuccess() { 
      return false; 
    }
    
    @Override 
    public Stock getUpdatedStock() { 
      return null; 
    }
    
    @Override 
    public StockUpdatedEvent getEvent() { 
      return null; 
    }
    
    @Override 
    public Integer getReservedQuantity() { 
      return null; 
    }
    
    @Override 
    public String getErrorMessage() { 
      return errorMessage; 
    }
  }
}
