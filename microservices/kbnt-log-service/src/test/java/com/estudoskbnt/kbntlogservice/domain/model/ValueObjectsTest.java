package com.estudoskbnt.kbntlogservice.domain.model;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit Tests for Value Objects
 * Tests the domain value objects validation and behavior
 */
@DisplayName("Value Objects Tests")
class ValueObjectsTest {

    @Test
    @DisplayName("ProductId should validate correctly")
    void productIdShouldValidateCorrectly() {
        // Valid product IDs
        assertTrue(ProductId.of("PROD-001").isValid());
        assertTrue(ProductId.of("PROD_001").isValid());
        assertTrue(ProductId.of("PRODUCT123").isValid());

        // Invalid product IDs
        assertFalse(ProductId.of("").isValid());
        assertFalse(ProductId.of(" ").isValid());
        assertFalse(ProductId.of("prod-001").isValid()); // lowercase not allowed
        assertFalse(ProductId.of("PROD-001-VERY-LONG-NAME-EXCEEDING-LIMIT").isValid());
    }

    @Test
    @DisplayName("DistributionCenter should validate correctly")
    void distributionCenterShouldValidateCorrectly() {
        // Valid distribution centers
        assertTrue(DistributionCenter.of("DC_SP").isValid());
        assertTrue(DistributionCenter.of("DC-SAO-PAULO").isValid());

        // Invalid distribution centers
        assertFalse(DistributionCenter.of("").isValid());
        assertFalse(DistributionCenter.of("D").isValid()); // too short
        assertFalse(DistributionCenter.of("dc-sp").isValid()); // lowercase not allowed
    }

    @Test
    @DisplayName("Branch should validate correctly")
    void branchShouldValidateCorrectly() {
        // Valid branches
        assertTrue(Branch.of("BR001").isValid());
        assertTrue(Branch.of("BRANCH_001").isValid());

        // Invalid branches
        assertFalse(Branch.of("").isValid());
        assertFalse(Branch.of("B").isValid()); // too short
        assertFalse(Branch.of("br001").isValid()); // lowercase not allowed
    }

    @Test
    @DisplayName("Quantity should validate correctly")
    void quantityShouldValidateCorrectly() {
        // Valid quantities
        assertTrue(Quantity.of(1).isPositive());
        assertTrue(Quantity.of(100).isPositive());
        assertTrue(Quantity.of(1000000).isPositive());

        // Invalid quantities
        assertFalse(Quantity.of(0).isPositive());
        assertFalse(Quantity.of(-1).isPositive());
        assertFalse(Quantity.of(-100).isPositive());
    }

    @Test
    @DisplayName("Operation should validate correctly")
    void operationShouldValidateCorrectly() {
        // Valid operations
        assertTrue(Operation.of("ADD").isValid());
        assertTrue(Operation.of("REMOVE").isValid());
        assertTrue(Operation.of("TRANSFER").isValid());
        assertTrue(Operation.of("RESERVE").isValid());
        assertTrue(Operation.of("RELEASE").isValid());

        // Test specific operation types
        assertTrue(Operation.of("ADD").isAdd());
        assertTrue(Operation.of("REMOVE").isRemove());
        assertTrue(Operation.of("TRANSFER").isTransfer());
        assertTrue(Operation.of("RESERVE").isReserve());
        assertTrue(Operation.of("RELEASE").isRelease());

        // Invalid operations
        assertFalse(Operation.of("INVALID").isValid());
        assertFalse(Operation.of("add").isValid()); // lowercase not allowed
        assertFalse(Operation.of("").isValid());
    }

    @Test
    @DisplayName("CorrelationId should handle generation correctly")
    void correlationIdShouldHandleGenerationCorrectly() {
        // Generated correlation IDs should be unique
        CorrelationId id1 = CorrelationId.generate();
        CorrelationId id2 = CorrelationId.generate();
        
        assertNotNull(id1.getValue());
        assertNotNull(id2.getValue());
        assertNotEquals(id1.getValue(), id2.getValue());

        // Should handle null values by generating new ID
        CorrelationId idFromNull = CorrelationId.of(null);
        assertNotNull(idFromNull.getValue());

        // Should preserve provided value
        CorrelationId idFromValue = CorrelationId.of("test-correlation-123");
        assertEquals("test-correlation-123", idFromValue.getValue());
    }

    @Test
    @DisplayName("SourceBranch should validate correctly")
    void sourceBranchShouldValidateCorrectly() {
        // Valid source branches
        assertTrue(SourceBranch.of("BR001").isValid());
        assertTrue(SourceBranch.of("BRANCH_001").isValid());

        // Display name should format correctly
        assertEquals("BRANCH 001", SourceBranch.of("BRANCH_001").getDisplayName());
        assertEquals("BR001", SourceBranch.of("BR001").getDisplayName());

        // Invalid source branches
        assertFalse(SourceBranch.of("").isValid());
        assertFalse(SourceBranch.of("br001").isValid()); // lowercase not allowed
    }

    @Test
    @DisplayName("ReasonCode should handle creation correctly")
    void reasonCodeShouldHandleCreationCorrectly() {
        // With code only
        ReasonCode reasonCode1 = ReasonCode.of("PURCHASE");
        assertEquals("PURCHASE", reasonCode1.getCode());
        assertNull(reasonCode1.getDescription());

        // With code and description
        ReasonCode reasonCode2 = ReasonCode.of("PURCHASE", "Product purchase from supplier");
        assertEquals("PURCHASE", reasonCode2.getCode());
        assertEquals("Product purchase from supplier", reasonCode2.getDescription());
    }

    @Test
    @DisplayName("ReferenceDocument should handle creation correctly")
    void referenceDocumentShouldHandleCreationCorrectly() {
        // With number only
        ReferenceDocument doc1 = ReferenceDocument.of("PO-12345");
        assertEquals("PO-12345", doc1.getNumber());
        assertEquals("PO-12345", doc1.getValue()); // getValue should return number
        assertNull(doc1.getType());

        // With number and type
        ReferenceDocument doc2 = ReferenceDocument.of("PO-12345", "PURCHASE_ORDER");
        assertEquals("PO-12345", doc2.getNumber());
        assertEquals("PURCHASE_ORDER", doc2.getType());
        assertEquals("PO-12345", doc2.getValue());
    }

    @Test
    @DisplayName("Value objects should implement equality correctly")
    void valueObjectsShouldImplementEqualityCorrectly() {
        // ProductId equality
        ProductId prod1a = ProductId.of("PROD-001");
        ProductId prod1b = ProductId.of("PROD-001");
        ProductId prod2 = ProductId.of("PROD-002");

        assertEquals(prod1a, prod1b);
        assertNotEquals(prod1a, prod2);

        // Quantity equality
        Quantity qty1a = Quantity.of(100);
        Quantity qty1b = Quantity.of(100);
        Quantity qty2 = Quantity.of(200);

        assertEquals(qty1a, qty1b);
        assertNotEquals(qty1a, qty2);

        // Operation equality
        Operation op1a = Operation.of("ADD");
        Operation op1b = Operation.of("ADD");
        Operation op2 = Operation.of("REMOVE");

        assertEquals(op1a, op1b);
        assertNotEquals(op1a, op2);
    }

    @Test
    @DisplayName("Value objects should be immutable")
    void valueObjectsShouldBeImmutable() {
        // Create value objects
        ProductId productId = ProductId.of("PROD-001");
        Quantity quantity = Quantity.of(100);
        Operation operation = Operation.of("ADD");

        // Values should not change
        assertEquals("PROD-001", productId.getValue());
        assertEquals(100, quantity.getValue());
        assertEquals("ADD", operation.getType());

        // Creating new instances should not affect original ones
        ProductId newProductId = ProductId.of("PROD-002");
        assertEquals("PROD-001", productId.getValue()); // Original unchanged
        assertEquals("PROD-002", newProductId.getValue());
    }

    @Test
    @DisplayName("Should handle edge cases gracefully")
    void shouldHandleEdgeCasesGracefully() {
        // ProductId with special characters
        assertFalse(ProductId.of("PROD@001").isValid());
        assertFalse(ProductId.of("PROD 001").isValid());

        // Quantity boundary values
        assertTrue(Quantity.of(1).isPositive());
        assertFalse(Quantity.of(0).isPositive());
        assertTrue(Quantity.of(Integer.MAX_VALUE).isPositive());

        // Operation case sensitivity
        assertFalse(Operation.of("Add").isValid());
        assertFalse(Operation.of("INVALID_OPERATION").isValid());

        // Empty strings
        assertFalse(ProductId.of("").isValid());
        assertFalse(DistributionCenter.of("").isValid());
        assertFalse(Branch.of("").isValid());
        assertFalse(Operation.of("").isValid());
    }
}
