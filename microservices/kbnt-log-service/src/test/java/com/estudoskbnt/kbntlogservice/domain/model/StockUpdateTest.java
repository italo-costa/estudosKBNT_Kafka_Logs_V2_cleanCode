package com.estudoskbnt.kbntlogservice.domain.model;

import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit Tests for Stock Update Domain Model
 * Tests the domain layer business logic and rules
 */
@DisplayName("Stock Update Domain Model Tests")
class StockUpdateTest {

    @Test
    @DisplayName("Should create stock update with valid data")
    void shouldCreateStockUpdateWithValidData() {
        // Given
        ProductId productId = ProductId.of("PROD-001");
        DistributionCenter distributionCenter = DistributionCenter.of("DC-SAO-PAULO");
        Branch branch = Branch.of("BRANCH-001");
        Quantity quantity = Quantity.of(100);
        Operation operation = Operation.of("ADD");
        CorrelationId correlationId = CorrelationId.of("test-correlation-123");
        ReasonCode reasonCode = ReasonCode.of("PURCHASE");
        ReferenceDocument referenceDocument = ReferenceDocument.of("PO-12345");

        // When
        StockUpdate stockUpdate = StockUpdate.create(
                productId, distributionCenter, branch, quantity, operation,
                correlationId, reasonCode, referenceDocument);

        // Then
        assertNotNull(stockUpdate);
        assertNotNull(stockUpdate.getId());
        assertEquals(productId, stockUpdate.getProductId());
        assertEquals(distributionCenter, stockUpdate.getDistributionCenter());
        assertEquals(branch, stockUpdate.getBranch());
        assertEquals(quantity, stockUpdate.getQuantity());
        assertEquals(operation, stockUpdate.getOperation());
        assertEquals(correlationId, stockUpdate.getCorrelationId());
        assertEquals(reasonCode, stockUpdate.getReasonCode());
        assertEquals(referenceDocument, stockUpdate.getReferenceDocument());
        assertNotNull(stockUpdate.getCreatedAt());
        assertNotNull(stockUpdate.getUpdatedAt());
        assertEquals(StockUpdateStatus.PENDING, stockUpdate.getStatus());
    }

    @Test
    @DisplayName("Should validate stock update with valid data")
    void shouldValidateStockUpdateWithValidData() {
        // Given
        StockUpdate stockUpdate = createValidStockUpdate();

        // When
        ValidationResult result = stockUpdate.validate();

        // Then
        assertNotNull(result);
        assertTrue(result.isValid());
        assertNull(result.getErrorCode());
        assertNull(result.getErrorMessage());
    }

    @Test
    @DisplayName("Should fail validation with negative quantity")
    void shouldFailValidationWithNegativeQuantity() {
        // Given
        StockUpdate stockUpdate = StockUpdate.create(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"),
                Quantity.of(-10), // Invalid negative quantity
                Operation.of("ADD"),
                CorrelationId.of("test-correlation-123"),
                ReasonCode.of("PURCHASE"),
                ReferenceDocument.of("PO-12345"));

        // When
        ValidationResult result = stockUpdate.validate();

        // Then
        assertNotNull(result);
        assertFalse(result.isValid());
        assertEquals("INVALID_QUANTITY", result.getErrorCode());
        assertEquals("Quantity must be positive", result.getErrorMessage());
    }

    @Test
    @DisplayName("Should process stock update and generate event")
    void shouldProcessStockUpdateAndGenerateEvent() {
        // Given
        StockUpdate stockUpdate = createValidStockUpdate();

        // When
        StockUpdateEvent event = stockUpdate.process();

        // Then
        assertNotNull(event);
        assertEquals(stockUpdate.getId(), event.getEventId());
        assertEquals(stockUpdate.getProductId(), event.getProductId());
        assertEquals(stockUpdate.getDistributionCenter(), event.getDistributionCenter());
        assertEquals(stockUpdate.getBranch(), event.getBranch());
        assertEquals(stockUpdate.getQuantity(), event.getQuantity());
        assertEquals(stockUpdate.getOperation(), event.getOperation());
        assertEquals(stockUpdate.getCorrelationId(), event.getCorrelationId());
        assertEquals(StockUpdateStatus.PROCESSED, stockUpdate.getStatus());
        assertNotNull(event.getTimestamp());
        assertTrue(event.getTargetTopic().contains("kbnt-stock-updates") || event.getTargetTopic().contains("inventory-events"));
    }

    @Test
    @DisplayName("Should fail processing without validation")
    void shouldFailProcessingWithoutValidation() {
        // Given
        StockUpdate stockUpdate = StockUpdate.create(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"),
                Quantity.of(-10), // Invalid quantity
                Operation.of("ADD"),
                CorrelationId.of("test-correlation-123"),
                ReasonCode.of("PURCHASE"),
                ReferenceDocument.of("PO-12345"));

        // When & Then
        assertThrows(IllegalStateException.class, () -> {
            stockUpdate.process();
        });

        assertEquals(StockUpdateStatus.PENDING, stockUpdate.getStatus());
    }

    @Test
    @DisplayName("Should handle transfer operation correctly")
    void shouldHandleTransferOperationCorrectly() {
        // Given
        StockUpdate transferUpdate = StockUpdate.createTransfer(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"), // Target branch
                SourceBranch.of("BRANCH-002"), // Source branch
                Quantity.of(25),
                CorrelationId.of("test-transfer-123"),
                ReferenceDocument.of("TRANS-12345"));

        // When
        ValidationResult validation = transferUpdate.validate();
        StockUpdateEvent event = transferUpdate.process();

        // Then
        assertTrue(validation.isValid());
        assertNotNull(event);
        assertEquals("TRANSFER", event.getOperation().getType());
        assertEquals("BRANCH-002", event.getSourceBranch().getCode());
        assertEquals("BRANCH-001", event.getBranch().getCode());
    }

    @Test
    @DisplayName("Should handle reserve operation correctly")
    void shouldHandleReserveOperationCorrectly() {
        // Given
        StockUpdate reserveUpdate = StockUpdate.createReservation(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"),
                Quantity.of(10),
                CorrelationId.of("test-reserve-123"),
                ReasonCode.of("ORDER_RESERVATION"),
                ReferenceDocument.of("ORD-12345"));

        // When
        ValidationResult validation = reserveUpdate.validate();
        StockUpdateEvent event = reserveUpdate.process();

        // Then
        assertTrue(validation.isValid());
        assertNotNull(event);
        assertEquals("RESERVE", event.getOperation().getType());
        assertEquals("ORDER_RESERVATION", event.getReasonCode().getCode());
    }

    @Test
    @DisplayName("Should handle release operation correctly")
    void shouldHandleReleaseOperationCorrectly() {
        // Given
        StockUpdate releaseUpdate = StockUpdate.createRelease(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"),
                Quantity.of(5),
                CorrelationId.of("test-release-123"),
                ReasonCode.of("ORDER_CANCELLED"),
                ReferenceDocument.of("ORD-54321"));

        // When
        ValidationResult validation = releaseUpdate.validate();
        StockUpdateEvent event = releaseUpdate.process();

        // Then
        assertTrue(validation.isValid());
        assertNotNull(event);
        assertEquals("RELEASE", event.getOperation().getType());
        assertEquals("ORDER_CANCELLED", event.getReasonCode().getCode());
    }

    @Test
    @DisplayName("Should update status correctly")
    void shouldUpdateStatusCorrectly() {
        // Given
        StockUpdate stockUpdate = createValidStockUpdate();
        assertEquals(StockUpdateStatus.PENDING, stockUpdate.getStatus());

        // When
        stockUpdate.markAsProcessing();

        // Then
        assertEquals(StockUpdateStatus.PROCESSING, stockUpdate.getStatus());

        // When
        stockUpdate.markAsProcessed();

        // Then
        assertEquals(StockUpdateStatus.PROCESSED, stockUpdate.getStatus());
    }

    @Test
    @DisplayName("Should handle failure status correctly")
    void shouldHandleFailureStatusCorrectly() {
        // Given
        StockUpdate stockUpdate = createValidStockUpdate();
        String failureReason = "Database connection failed";

        // When
        stockUpdate.markAsFailed(failureReason);

        // Then
        assertEquals(StockUpdateStatus.FAILED, stockUpdate.getStatus());
        assertEquals(failureReason, stockUpdate.getFailureReason());
        assertNotNull(stockUpdate.getFailedAt());
    }

    @Test
    @DisplayName("Should generate unique IDs for different instances")
    void shouldGenerateUniqueIdsForDifferentInstances() {
        // Given & When
        StockUpdate stockUpdate1 = createValidStockUpdate();
        StockUpdate stockUpdate2 = createValidStockUpdate();

        // Then
        assertNotEquals(stockUpdate1.getId(), stockUpdate2.getId());
    }

    @Test
    @DisplayName("Should preserve immutability of value objects")
    void shouldPreserveImmutabilityOfValueObjects() {
        // Given
        StockUpdate stockUpdate = createValidStockUpdate();
        ProductId originalProductId = stockUpdate.getProductId();

        // When & Then - Value objects should be immutable
        assertEquals("PROD-001", originalProductId.getValue());
        
        // Creating a new ProductId should not affect the original
        ProductId newProductId = ProductId.of("PROD-002");
        assertNotEquals(originalProductId, newProductId);
        assertEquals("PROD-001", stockUpdate.getProductId().getValue());
    }

    // ==================== HELPER METHODS ====================

    private StockUpdate createValidStockUpdate() {
        return StockUpdate.create(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"),
                Quantity.of(100),
                Operation.of("ADD"),
                CorrelationId.of("test-correlation-123"),
                ReasonCode.of("PURCHASE"),
                ReferenceDocument.of("PO-12345"));
    }
}
