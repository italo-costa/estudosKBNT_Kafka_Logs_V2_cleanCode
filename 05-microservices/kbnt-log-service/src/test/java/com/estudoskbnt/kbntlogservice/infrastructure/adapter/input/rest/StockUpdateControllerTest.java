package com.estudoskbnt.kbntlogservice.infrastructure.adapter.input.rest;

import java.util.concurrent.CompletableFuture;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import com.estudoskbnt.kbntlogservice.domain.model.*;
import com.estudoskbnt.kbntlogservice.domain.port.input.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class StockUpdateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private StockUpdateUseCase stockUpdateUseCase;

    @Autowired
    private ObjectMapper objectMapper;

    private static final String BASE_URL = "/api/v1/stock";
    private StockUpdateResult successResult;
    private ValidationResult validValidation;
    private ValidationResult invalidValidation;

    @BeforeEach
    void setUp() {
        // Create mock domain objects
        StockUpdateEvent mockEvent = createMockStockUpdateEvent();
        
        successResult = StockUpdateResult.success(mockEvent, "Stock update processed successfully");
        validValidation = ValidationResult.valid();
        invalidValidation = ValidationResult.invalid("INVALID_QUANTITY", "Quantity must be positive");
    }

    @Test
    @DisplayName("Should process generic stock update successfully")
    void shouldProcessGenericStockUpdate() throws Exception {
        // Given
        StockUpdateRequest request = createValidStockUpdateRequest();
        when(stockUpdateUseCase.processStockUpdate(any(StockUpdateCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(successResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.correlationId").value("test-correlation-123"))
                .andExpect(jsonPath("$.operation").value("ADD"))
                .andExpect(jsonPath("$.productId").value("PROD-001"))
                .andExpect(jsonPath("$.distributionCenter").value("DC-SAO-PAULO"))
                .andExpect(jsonPath("$.branch").value("BRANCH-001"));
    }

    @Test
    @DisplayName("Should add stock successfully")
    void shouldAddStockSuccessfully() throws Exception {
        // Given
        when(stockUpdateUseCase.addStock(any(AddStockCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(successResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/add")
                .param("productId", "PROD-001")
                .param("distributionCenter", "DC-SAO-PAULO")
                .param("branch", "BRANCH-001")
                .param("quantity", "100")
                .param("reasonCode", "PURCHASE")
                .param("referenceDocument", "PO-12345")
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpected(jsonPath("$.correlationId").value("test-correlation-123"));
    }

    @Test
    @DisplayName("Should remove stock successfully")
    void shouldRemoveStockSuccessfully() throws Exception {
        // Given
        when(stockUpdateUseCase.removeStock(any(RemoveStockCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(successResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/remove")
                .param("productId", "PROD-001")
                .param("distributionCenter", "DC-SAO-PAULO")
                .param("branch", "BRANCH-001")
                .param("quantity", "50")
                .param("reasonCode", "SALE")
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpected(status().isOk())
                .andExpected(jsonPath("$.status").value("success"));
    }

    @Test
    @DisplayName("Should transfer stock successfully")
    void shouldTransferStockSuccessfully() throws Exception {
        // Given
        when(stockUpdateUseCase.transferStock(any(TransferStockCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(successResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/transfer")
                .param("productId", "PROD-001")
                .param("distributionCenter", "DC-SAO-PAULO")
                .param("sourceBranch", "BRANCH-001")
                .param("targetBranch", "BRANCH-002")
                .param("quantity", "25")
                .param("referenceDocument", "TRANS-12345")
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpect(status().isOk())
                .andExpected(jsonPath("$.status").value("success"));
    }

    @Test
    @DisplayName("Should reserve stock successfully")
    void shouldReserveStockSuccessfully() throws Exception {
        // Given
        when(stockUpdateUseCase.reserveStock(any(ReserveStockCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(successResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/reserve")
                .param("productId", "PROD-001")
                .param("distributionCenter", "DC-SAO-PAULO")
                .param("branch", "BRANCH-001")
                .param("quantity", "10")
                .param("reasonCode", "ORDER_RESERVATION")
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpect(status().isOk())
                .andExpected(jsonPath("$.status").value("success"));
    }

    @Test
    @DisplayName("Should release stock successfully")
    void shouldReleaseStockSuccessfully() throws Exception {
        // Given
        when(stockUpdateUseCase.releaseStock(any(ReleaseStockCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(successResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/release")
                .param("productId", "PROD-001")
                .param("distributionCenter", "DC-SAO-PAULO")
                .param("branch", "BRANCH-001")
                .param("quantity", "10")
                .param("reasonCode", "ORDER_CANCELLED")
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpect(status().isOk())
                .andExpected(jsonPath("$.status").value("success"));
    }

    @Test
    @DisplayName("Should validate stock update successfully")
    void shouldValidateStockUpdateSuccessfully() throws Exception {
        // Given
        StockUpdateRequest request = createValidStockUpdateRequest();
        when(stockUpdateUseCase.validateStockUpdate(any(StockUpdateCommand.class)))
                .thenReturn(validValidation);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/validate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpected(jsonPath("$.status").value("valid"))
                .andExpected(jsonPath("$.productId").value("PROD-001"))
                .andExpected(jsonPath("$.operation").value("ADD"));
    }

    @Test
    @DisplayName("Should return invalid validation result")
    void shouldReturnInvalidValidationResult() throws Exception {
        // Given
        StockUpdateRequest request = createInvalidStockUpdateRequest();
        when(stockUpdateUseCase.validateStockUpdate(any(StockUpdateCommand.class)))
                .thenReturn(invalidValidation);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/validate")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpected(status().isBadRequest())
                .andExpected(jsonPath("$.status").value("invalid"))
                .andExpected(jsonPath("$.errorCode").value("INVALID_QUANTITY"))
                .andExpected(jsonPath("$.message").value("Quantity must be positive"));
    }

    @Test
    @DisplayName("Should handle validation errors for invalid request")
    void shouldHandleValidationErrors() throws Exception {
        // Given - Invalid request with missing fields
        StockUpdateRequest invalidRequest = StockUpdateRequest.builder().build();

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Should handle use case processing failures")
    void shouldHandleUseCaseProcessingFailures() throws Exception {
        // Given
        StockUpdateRequest request = createValidStockUpdateRequest();
        StockUpdateResult failureResult = StockUpdateResult.failure(
                invalidValidation, "Failed to process stock update");
        
        when(stockUpdateUseCase.processStockUpdate(any(StockUpdateCommand.class)))
                .thenReturn(CompletableFuture.completedFuture(failureResult));

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpected(status().isBadRequest())
                .andExpected(jsonPath("$.status").value("failed"))
                .andExpected(jsonPath("$.message").value("Failed to process stock update"));
    }

    @Test
    @DisplayName("Should handle async processing exceptions")
    void shouldHandleAsyncProcessingExceptions() throws Exception {
        // Given
        StockUpdateRequest request = createValidStockUpdateRequest();
        CompletableFuture<StockUpdateResult> failedFuture = new CompletableFuture<>();
        failedFuture.completeExceptionally(new RuntimeException("Processing failed"));
        
        when(stockUpdateUseCase.processStockUpdate(any(StockUpdateCommand.class)))
                .thenReturn(failedFuture);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpected(status().isInternalServerError())
                .andExpected(jsonPath("$.status").value("error"))
                .andExpected(jsonPath("$.message").value("Processing failed"));
    }

    @Test
    @DisplayName("Should return health check information")
    void shouldReturnHealthCheckInformation() throws Exception {
        // When & Then
        mockMvc.perform(get(BASE_URL + "/health"))
                .andExpected(status().isOk())
                .andExpected(jsonPath("$.status").value("UP"))
                .andExpected(jsonPath("$.service").value("Stock Update Service"))
                .andExpected(jsonPath("$.operations").isArray());
    }

    // ==================== HELPER METHODS ====================

    private StockUpdateRequest createValidStockUpdateRequest() {
        return StockUpdateRequest.builder()
                .productId("PROD-001")
                .distributionCenter("DC-SAO-PAULO")
                .branch("BRANCH-001")
                .quantity(100)
                .operation("ADD")
                .reasonCode("PURCHASE")
                .referenceDocument("PO-12345")
                .build();
    }

    private StockUpdateRequest createInvalidStockUpdateRequest() {
        return StockUpdateRequest.builder()
                .productId("PROD-001")
                .distributionCenter("DC-SAO-PAULO")
                .branch("BRANCH-001")
                .quantity(-10) // Invalid negative quantity
                .operation("ADD")
                .build();
    }

    private StockUpdateEvent createMockStockUpdateEvent() {
        return StockUpdateEvent.builder()
                .eventId("event-123")
                .productId(ProductId.of("PROD-001"))
                .distributionCenter(DistributionCenter.of("DC-SAO-PAULO"))
                .branch(Branch.of("BRANCH-001"))
                .quantity(Quantity.of(100))
                .operation(Operation.of("ADD"))
                .correlationId(CorrelationId.of("test-correlation-123"))
                .reasonCode(ReasonCode.of("PURCHASE"))
                .referenceDocument(ReferenceDocument.of("PO-12345"))
                .build();
    }
}
