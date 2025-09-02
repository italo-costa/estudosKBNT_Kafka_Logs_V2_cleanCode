package com.kbnt.virtualstock.application.service;

import com.kbnt.virtualstock.domain.model.Stock;
import com.kbnt.virtualstock.domain.port.input.StockManagementUseCase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Simple unit tests for StockManagementApplicationService.
 */
@ExtendWith(MockitoExtension.class)
class StockManagementApplicationServiceTestSimple {

    @InjectMocks
    private StockManagementApplicationService stockManagementApplicationService;

    private Stock testStock;
    private Stock.StockId testStockId;
    private Stock.ProductId testProductId;

    @BeforeEach
    void setUp() {
        testStockId = new Stock.StockId("TEST001");
        testProductId = new Stock.ProductId("PROD001");
        
        testStock = Stock.builder()
            .stockId(testStockId)
            .productId(testProductId)
            .symbol("TEST")
            .productName("Test Product")
            .quantity(100)
            .unitPrice(new BigDecimal("50.00"))
            .status(Stock.StockStatus.AVAILABLE)
            .lastUpdated(LocalDateTime.now())
            .lastUpdatedBy("testuser")
            .build();
    }

    @Test
    void shouldInstantiateService() {
        // Given
        // When
        // Then
        assertNotNull(stockManagementApplicationService);
    }

    @Test
    void shouldCreateStockId() {
        // Given
        String stockIdString = "TEST001";
        
        // When
        Stock.StockId stockId = new Stock.StockId(stockIdString);
        
        // Then
        assertNotNull(stockId);
        assertEquals(stockIdString, stockId.getValue());
    }

    @Test
    void shouldCreateProductId() {
        // Given
        String productIdString = "PROD001";
        
        // When
        Stock.ProductId productId = new Stock.ProductId(productIdString);
        
        // Then
        assertNotNull(productId);
        assertEquals(productIdString, productId.getValue());
    }

    @Test
    void shouldBuildStock() {
        // Given
        Stock.StockId stockId = new Stock.StockId("TEST002");
        Stock.ProductId productId = new Stock.ProductId("PROD002");
        
        // When
        Stock stock = Stock.builder()
            .stockId(stockId)
            .productId(productId)
            .symbol("TST")
            .productName("Test Stock 2")
            .quantity(50)
            .unitPrice(new BigDecimal("25.00"))
            .status(Stock.StockStatus.AVAILABLE)
            .lastUpdated(LocalDateTime.now())
            .lastUpdatedBy("testuser2")
            .build();
        
        // Then
        assertNotNull(stock);
        assertEquals(stockId, stock.getStockId());
        assertEquals(productId, stock.getProductId());
        assertEquals("TST", stock.getSymbol());
        assertEquals("Test Stock 2", stock.getProductName());
        assertEquals(50, stock.getQuantity());
        assertEquals(new BigDecimal("25.00"), stock.getUnitPrice());
        assertEquals(Stock.StockStatus.AVAILABLE, stock.getStatus());
        assertEquals("testuser2", stock.getLastUpdatedBy());
    }
}
