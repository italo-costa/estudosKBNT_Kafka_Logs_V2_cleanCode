package com.estudoskbnt.kbntlogservice.application.service;

import java.util.Optional;
import java.util.concurrent.CompletableFuture;

import com.estudoskbnt.kbntlogservice.domain.event.StockUpdateEvent;
import com.estudoskbnt.kbntlogservice.domain.model.*;
import com.estudoskbnt.kbntlogservice.domain.port.input.*;
import com.estudoskbnt.kbntlogservice.domain.port.output.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class StockUpdateApplicationServiceTest {

    @Mock
    private StockUpdateRepositoryPort repositoryPort;

    @Mock
    private EventPublisherPort eventPublisherPort;

    @InjectMocks
    private StockUpdateApplicationService applicationService;

    private StockUpdateCommand validCommand;
    private AddStockCommand addStockCommand;
    private RemoveStockCommand removeStockCommand;
    private StockUpdate mockStockUpdate;

    @BeforeEach
    void setUp() {
        validCommand = createValidStockUpdateCommand();
        addStockCommand = createAddStockCommand();
        removeStockCommand = createRemoveStockCommand();
        mockStockUpdate = createMockStockUpdate();
    }

    @Test
    @DisplayName("Should process stock update successfully")
    void shouldProcessStockUpdateSuccessfully() {
        // Given
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(CompletableFuture.completedFuture(null));

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.processStockUpdate(validCommand);

        // Then
        assertNotNull(result);
        StockUpdateResult updateResult = result.join();
        
        assertTrue(updateResult.isSuccess());
        assertNotNull(updateResult.getEvent());
        assertEquals("PROD-001", updateResult.getEvent().getProductId().getValue());
        assertEquals("Stock update processed successfully", updateResult.getMessage());

        verify(repositoryPort, times(1)).save(any(StockUpdate.class));
        verify(eventPublisherPort, times(1)).publishStockUpdateEvent(any(StockUpdateEvent.class));
        verify(eventPublisherPort, times(1)).publishAuditEvent(any(StockUpdateEvent.class));
    }

    @Test
    @DisplayName("Should add stock successfully")
    void shouldAddStockSuccessfully() {
        // Given
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(CompletableFuture.completedFuture(null));

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.addStock(addStockCommand);

        // Then
        assertNotNull(result);
        StockUpdateResult updateResult = result.join();
        
        assertTrue(updateResult.isSuccess());
        assertNotNull(updateResult.getEvent());
        assertEquals("ADD", updateResult.getEvent().getOperation().getType());

        verify(repositoryPort, times(1)).save(any(StockUpdate.class));
        verify(eventPublisherPort, times(1)).publishStockUpdateEvent(any(StockUpdateEvent.class));
    }

    @Test
    @DisplayName("Should remove stock successfully")
    void shouldRemoveStockSuccessfully() {
        // Given
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(CompletableFuture.completedFuture(null));

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.removeStock(removeStockCommand);

        // Then
        assertNotNull(result);
        StockUpdateResult updateResult = result.join();
        
        assertTrue(updateResult.isSuccess());
        assertNotNull(updateResult.getEvent());
        assertEquals("REMOVE", updateResult.getEvent().getOperation().getType());

        verify(repositoryPort, times(1)).save(any(StockUpdate.class));
        verify(eventPublisherPort, times(1)).publishStockUpdateEvent(any(StockUpdateEvent.class));
    }

    @Test
    @DisplayName("Should validate stock update correctly")
    void shouldValidateStockUpdateCorrectly() {
        // When - Valid command
        ValidationResult validResult = applicationService.validateStockUpdate(validCommand);

        // Then
        assertNotNull(validResult);
        assertTrue(validResult.isValid());

        // When - Invalid command (negative quantity)
        StockUpdateCommand invalidCommand = createInvalidStockUpdateCommand();
        ValidationResult invalidResult = applicationService.validateStockUpdate(invalidCommand);

        // Then
        assertNotNull(invalidResult);
        assertFalse(invalidResult.isValid());
        assertEquals("INVALID_QUANTITY", invalidResult.getErrorCode());
    }

    @Test
    @DisplayName("Should handle repository save failures")
    void shouldHandleRepositorySaveFailures() {
        // Given
        CompletableFuture<StockUpdate> failedFuture = new CompletableFuture<>();
        failedFuture.completeExceptionally(new RuntimeException("Database connection failed"));
        
        when(repositoryPort.save(any(StockUpdate.class))).thenReturn(failedFuture);

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.processStockUpdate(validCommand);

        // Then
        assertNotNull(result);
        assertTrue(result.isCompletedExceptionally());

        verify(repositoryPort, times(1)).save(any(StockUpdate.class));
        verify(eventPublisherPort, never()).publishStockUpdateEvent(any(StockUpdateEvent.class));
    }

    @Test
    @DisplayName("Should handle event publishing failures")
    void shouldHandleEventPublishingFailures() {
        // Given
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        
        CompletableFuture<Void> failedEventFuture = new CompletableFuture<>();
        failedEventFuture.completeExceptionally(new RuntimeException("Kafka broker unavailable"));
        
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(failedEventFuture);

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.processStockUpdate(validCommand);

        // Then
        assertNotNull(result);
        assertTrue(result.isCompletedExceptionally());

        verify(repositoryPort, times(1)).save(any(StockUpdate.class));
        verify(eventPublisherPort, times(1)).publishStockUpdateEvent(any(StockUpdateEvent.class));
    }

    @Test
    @DisplayName("Should process transfer stock operation")
    void shouldProcessTransferStockOperation() {
        // Given
        TransferStockCommand transferCommand = createTransferStockCommand();
        
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(CompletableFuture.completedFuture(null));

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.transferStock(transferCommand);

        // Then
        assertNotNull(result);
        StockUpdateResult updateResult = result.join();
        
        assertTrue(updateResult.isSuccess());
        assertNotNull(updateResult.getEvent());
        assertEquals("TRANSFER", updateResult.getEvent().getOperation().getType());

        verify(repositoryPort, times(1)).save(any(StockUpdate.class));
        verify(eventPublisherPort, times(1)).publishStockUpdateEvent(any(StockUpdateEvent.class));
    }

    @Test
    @DisplayName("Should process reserve stock operation")
    void shouldProcessReserveStockOperation() {
        // Given
        ReserveStockCommand reserveCommand = createReserveStockCommand();
        
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(CompletableFuture.completedFuture(null));

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.reserveStock(reserveCommand);

        // Then
        assertNotNull(result);
        StockUpdateResult updateResult = result.join();
        
        assertTrue(updateResult.isSuccess());
        assertNotNull(updateResult.getEvent());
        assertEquals("RESERVE", updateResult.getEvent().getOperation().getType());
    }

    @Test
    @DisplayName("Should process release stock operation")
    void shouldProcessReleaseStockOperation() {
        // Given
        ReleaseStockCommand releaseCommand = createReleaseStockCommand();
        
        when(repositoryPort.save(any(StockUpdate.class)))
                .thenReturn(CompletableFuture.completedFuture(mockStockUpdate));
        when(eventPublisherPort.publishStockUpdateEvent(any(StockUpdateEvent.class)))
                .thenReturn(CompletableFuture.completedFuture(null));

        // When
        CompletableFuture<StockUpdateResult> result = applicationService.releaseStock(releaseCommand);

        // Then
        assertNotNull(result);
        StockUpdateResult updateResult = result.join();
        
        assertTrue(updateResult.isSuccess());
        assertNotNull(updateResult.getEvent());
        assertEquals("RELEASE", updateResult.getEvent().getOperation().getType());
    }

    // ==================== HELPER METHODS ====================

    private StockUpdateCommand createValidStockUpdateCommand() {
        return new StockUpdateCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-001"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(100); }
            
            @Override
            public Operation getOperation() { return Operation.of("ADD"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-123"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("PURCHASE"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("PO-12345"); }
        };
    }

    private StockUpdateCommand createInvalidStockUpdateCommand() {
        return new StockUpdateCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-001"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(-10); } // Invalid negative quantity
            
            @Override
            public Operation getOperation() { return Operation.of("ADD"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-123"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("PURCHASE"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("PO-12345"); }
        };
    }

    private AddStockCommand createAddStockCommand() {
        return new AddStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-001"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(50); }
            
            @Override
            public Operation getOperation() { return Operation.of("ADD"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-add"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("PURCHASE"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("PO-67890"); }
        };
    }

    private RemoveStockCommand createRemoveStockCommand() {
        return new RemoveStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-001"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(25); }
            
            @Override
            public Operation getOperation() { return Operation.of("REMOVE"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-remove"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("SALE"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("INV-11111"); }
        };
    }

    private TransferStockCommand createTransferStockCommand() {
        return new TransferStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-002"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(15); }
            
            @Override
            public Operation getOperation() { return Operation.of("TRANSFER"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-transfer"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("TRANSFER"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("TRANS-22222"); }
            
            @Override
            public SourceBranch getSourceBranch() { return SourceBranch.of("BRANCH-001"); }
        };
    }

    private ReserveStockCommand createReserveStockCommand() {
        return new ReserveStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-001"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(10); }
            
            @Override
            public Operation getOperation() { return Operation.of("RESERVE"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-reserve"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("ORDER_RESERVATION"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("ORD-33333"); }
        };
    }

    private ReleaseStockCommand createReleaseStockCommand() {
        return new ReleaseStockCommand() {
            @Override
            public ProductId getProductId() { return ProductId.of("PROD-001"); }
            
            @Override
            public DistributionCenter getDistributionCenter() { return DistributionCenter.of("DC-SAO-PAULO"); }
            
            @Override
            public Branch getBranch() { return Branch.of("BRANCH-001"); }
            
            @Override
            public Quantity getQuantity() { return Quantity.of(5); }
            
            @Override
            public Operation getOperation() { return Operation.of("RELEASE"); }
            
            @Override
            public CorrelationId getCorrelationId() { return CorrelationId.of("test-correlation-release"); }
            
            @Override
            public ReasonCode getReasonCode() { return ReasonCode.of("ORDER_CANCELLED"); }
            
            @Override
            public ReferenceDocument getReferenceDocument() { return ReferenceDocument.of("ORD-44444"); }
        };
    }

    private StockUpdate createMockStockUpdate() {
        return StockUpdate.create(
                ProductId.of("PROD-001"),
                DistributionCenter.of("DC-SAO-PAULO"),
                Branch.of("BRANCH-001"),
                Quantity.of(100),
                Operation.of("ADD"),
                CorrelationId.of("test-correlation-123"),
                ReasonCode.of("PURCHASE"),
                ReferenceDocument.of("PO-12345")
        );
    }
}
