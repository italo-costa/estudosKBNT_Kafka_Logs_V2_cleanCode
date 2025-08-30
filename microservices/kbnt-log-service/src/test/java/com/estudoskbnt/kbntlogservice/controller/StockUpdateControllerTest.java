package com.estudoskbnt.kbntlogservice.controller;

import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import com.estudoskbnt.kbntlogservice.producer.StockUpdateProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.kafka.core.ProducerRecord;
import org.springframework.kafka.support.SendResult;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.concurrent.CompletableFuture;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit Tests for StockUpdateController
 * Tests REST API endpoints, validation, and integration with producer
 */
@WebMvcTest(StockUpdateController.class)
@TestPropertySource(properties = {
    "app.processing.modes=producer"
})
@DisplayName("StockUpdateController Unit Tests")
class StockUpdateControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private StockUpdateProducer stockUpdateProducer;

    @Autowired
    private ObjectMapper objectMapper;

    private static final String BASE_URL = "/api/v1/stock";

    @BeforeEach
    void setUp() {
        // Setup default mock behavior
        CompletableFuture<SendResult<String, StockUpdateMessage>> mockFuture = createMockSuccessResult();
        when(stockUpdateProducer.processStockUpdate(any(StockUpdateMessage.class)))
            .thenReturn(mockFuture);
    }

    @Test
    @DisplayName("Should accept valid stock update request")
    void shouldAcceptValidStockUpdateRequest() throws Exception {
        // Given
        StockUpdateMessage validMessage = createValidStockMessage("ADD");
        String jsonPayload = objectMapper.writeValueAsString(validMessage);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload)
                .header("X-Correlation-ID", "test-correlation-123"))
                .andExpect(status().isOk())
                .andExpected(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.correlationId").value("test-correlation-123"));
    }

    @Test
    @DisplayName("Should reject request with missing required fields")
    void shouldRejectRequestWithMissingFields() throws Exception {
        // Given - Message missing productId
        StockUpdateMessage invalidMessage = StockUpdateMessage.builder()
            .distributionCenter("DC-SP01")
            .branch("FIL-SP001")
            .quantity(10)
            .operation("ADD")
            .build();
        
        String jsonPayload = objectMapper.writeValueAsString(invalidMessage);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").exists())
                .andExpect(jsonPath("$.message").value(containsString("Product ID is required")));
    }

    @Test
    @DisplayName("Should reject request with negative quantity")
    void shouldRejectRequestWithNegativeQuantity() throws Exception {
        // Given
        StockUpdateMessage invalidMessage = createValidStockMessage("REMOVE");
        invalidMessage.setQuantity(-5); // Invalid negative quantity

        String jsonPayload = objectMapper.writeValueAsString(invalidMessage);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").exists())
                .andExpect(jsonPath("$.message").value(containsString("must be positive or zero")));
    }

    @Test
    @DisplayName("Should handle ADD operation through dedicated endpoint")
    void shouldHandleAddOperationThroughDedicatedEndpoint() throws Exception {
        // Given
        StockUpdateMessage addMessage = createValidStockMessage("ADD");
        String jsonPayload = objectMapper.writeValueAsString(addMessage);

        when(stockUpdateProducer.addStock(any(), any(), any(), any(), any(), any()))
            .thenReturn(createMockSuccessResult());

        // When & Then
        mockMvc.perform(post(BASE_URL + "/add")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.operation").value("ADD"))
                .andExpected(jsonPath("$.kafka.topic").value("kbnt-stock-updates"));
    }

    @Test
    @DisplayName("Should handle REMOVE operation through dedicated endpoint")
    void shouldHandleRemoveOperationThroughDedicatedEndpoint() throws Exception {
        // Given
        StockUpdateMessage removeMessage = createValidStockMessage("REMOVE");
        String jsonPayload = objectMapper.writeValueAsString(removeMessage);

        when(stockUpdateProducer.removeStock(any(), any(), any(), any(), any(), any()))
            .thenReturn(createMockSuccessResult());

        // When & Then
        mockMvc.perform(post(BASE_URL + "/remove")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.operation").value("REMOVE"));
    }

    @Test
    @DisplayName("Should handle TRANSFER operation through dedicated endpoint")
    void shouldHandleTransferOperationThroughDedicatedEndpoint() throws Exception {
        // Given
        StockUpdateMessage transferMessage = createValidStockMessage("TRANSFER");
        transferMessage.setSourceBranch("FIL-SP001");
        transferMessage.setBranch("FIL-SP002");
        
        String jsonPayload = objectMapper.writeValueAsString(transferMessage);

        when(stockUpdateProducer.transferStock(any(), any(), any(), any(), any(), any()))
            .thenReturn(createMockSuccessResult());

        // When & Then
        mockMvc.perform(post(BASE_URL + "/transfer")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.operation").value("TRANSFER"))
                .andExpect(jsonPath("$.kafka.topic").value("kbnt-stock-transfers"));
    }

    @Test
    @DisplayName("Should handle batch operations")
    void shouldHandleBatchOperations() throws Exception {
        // Given
        StockUpdateMessage[] batchMessages = {
            createValidStockMessage("ADD"),
            createValidStockMessage("REMOVE"),
            createValidStockMessage("TRANSFER")
        };
        
        String jsonPayload = objectMapper.writeValueAsString(batchMessages);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/batch")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.batchSize").value(3))
                .andExpect(jsonPath("$.results").isArray())
                .andExpect(jsonPath("$.results.length()").value(3));
    }

    @Test
    @DisplayName("Should set correlation ID from header")
    void shouldSetCorrelationIdFromHeader() throws Exception {
        // Given
        StockUpdateMessage message = createValidStockMessage("ADD");
        message.setCorrelationId(null); // Initially null
        
        String jsonPayload = objectMapper.writeValueAsString(message);
        String expectedCorrelationId = "custom-correlation-456";

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload)
                .header("X-Correlation-ID", expectedCorrelationId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.correlationId").value(expectedCorrelationId));
    }

    @Test
    @DisplayName("Should generate correlation ID if not provided")
    void shouldGenerateCorrelationIdIfNotProvided() throws Exception {
        // Given
        StockUpdateMessage message = createValidStockMessage("ADD");
        message.setCorrelationId(null);
        
        String jsonPayload = objectMapper.writeValueAsString(message);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.correlationId").exists())
                .andExpect(jsonPath("$.correlationId").isNotEmpty());
    }

    @Test
    @DisplayName("Should return error for malformed JSON")
    void shouldReturnErrorForMalformedJson() throws Exception {
        // Given
        String malformedJson = "{ \"productId\": \"TEST\", \"quantity\": }"; // Missing value

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(malformedJson))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Should return error when producer fails")
    void shouldReturnErrorWhenProducerFails() throws Exception {
        // Given
        StockUpdateMessage message = createValidStockMessage("ADD");
        String jsonPayload = objectMapper.writeValueAsString(message);

        CompletableFuture<SendResult<String, StockUpdateMessage>> failedFuture = new CompletableFuture<>();
        failedFuture.completeExceptionally(new RuntimeException("Kafka broker unavailable"));
        
        when(stockUpdateProducer.processStockUpdate(any(StockUpdateMessage.class)))
            .thenReturn(failedFuture);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value(containsString("Kafka broker unavailable")));
    }

    @Test
    @DisplayName("Should include processing metrics in response")
    void shouldIncludeProcessingMetricsInResponse() throws Exception {
        // Given
        StockUpdateMessage message = createValidStockMessage("ADD");
        String jsonPayload = objectMapper.writeValueAsString(message);

        // When & Then
        mockMvc.perform(post(BASE_URL + "/update")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.kafka.topic").exists())
                .andExpect(jsonPath("$.kafka.partition").exists())
                .andExpect(jsonPath("$.kafka.offset").exists())
                .andExpect(jsonPath("$.processingTime").exists())
                .andExpect(jsonPath("$.timestamp").exists());
    }

    // ===================== HELPER METHODS =====================

    private StockUpdateMessage createValidStockMessage(String operation) {
        return StockUpdateMessage.builder()
            .productId("TEST-PRODUCT-" + System.currentTimeMillis())
            .distributionCenter("DC-SP01")
            .branch("FIL-SP001")
            .quantity(operation.equals("REMOVE") ? 5 : 100)
            .operation(operation)
            .reasonCode(getReasonForOperation(operation))
            .referenceDocument("TEST-DOC-001")
            .correlationId("test-correlation")
            .build();
    }

    private String getReasonForOperation(String operation) {
        switch (operation) {
            case "ADD": return "PURCHASE";
            case "REMOVE": return "SALE";
            case "TRANSFER": return "REBALANCE";
            case "SET": return "ADJUSTMENT";
            default: return "UNKNOWN";
        }
    }

    private CompletableFuture<SendResult<String, StockUpdateMessage>> createMockSuccessResult() {
        CompletableFuture<SendResult<String, StockUpdateMessage>> future = new CompletableFuture<>();
        
        RecordMetadata metadata = new RecordMetadata(
            new TopicPartition("kbnt-stock-updates", 3),
            0L,
            7823L,
            System.currentTimeMillis(),
            0L,
            256,
            512
        );
        
        ProducerRecord<String, StockUpdateMessage> record = 
            new ProducerRecord<>("kbnt-stock-updates", "test-key", createValidStockMessage("ADD"));
        
        SendResult<String, StockUpdateMessage> sendResult = new SendResult<>(record, metadata);
        future.complete(sendResult);
        
        return future;
    }
}
