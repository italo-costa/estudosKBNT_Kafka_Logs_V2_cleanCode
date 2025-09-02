package com.estudoskbnt.consumer.service;

import com.estudoskbnt.consumer.entity.ConsumptionLog;
import com.estudoskbnt.consumer.model.StockUpdateMessage;
import com.estudoskbnt.consumer.repository.ConsumptionLogRepository;
import com.estudoskbnt.consumer.service.ExternalApiService.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for KafkaConsumerService
 * 
 * Tests the core message processing logic, error handling,
 * and integration with external services.
 * 
 * @author KBNT Development Team
 * @version 1.0.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("Kafka Consumer Service Tests")
class KafkaConsumerServiceTest {
    
    @Mock
    private ExternalApiService externalApiService;
    
    @Mock
    private ConsumptionLogRepository consumptionLogRepository;
    
    @Mock
    private ObjectMapper objectMapper;
    
    @Mock
    private MessageHashService messageHashService;
    
    @InjectMocks
    private KafkaConsumerService kafkaConsumerService;
    
    private StockUpdateMessage validStockMessage;
    private ConsumptionLog validConsumptionLog;
    
    @BeforeEach
    void setUp() {
        // Setup valid stock message
        validStockMessage = StockUpdateMessage.builder()
                .correlationId("test-correlation-123")
                .productId("PROD-001")
                .quantity(100)
                .price(new BigDecimal("25.99"))
                .operation("ADD")
                .category("Electronics")
                .supplier("TechSupplier")
                .location("WH-001")
                .publishedAt(LocalDateTime.now().minusMinutes(1))
                .hash("a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456")
                .priority("NORMAL")
                .deadline(LocalDateTime.now().plusHours(1))
                .build();
        
        // Setup valid consumption log
        validConsumptionLog = ConsumptionLog.builder()
                .id(1L)
                .correlationId("test-correlation-123")
                .topic("stock-updates")
                .partitionId(0)
                .offset(100L)
                .productId("PROD-001")
                .quantity(100)
                .price(new BigDecimal("25.99"))
                .operation("ADD")
                .messageHash("a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456")
                .consumedAt(LocalDateTime.now())
                .status(ConsumptionLog.ProcessingStatus.RECEIVED)
                .retryCount(0)
                .priority("NORMAL")
                .build();
    }
    
    @Test
    @DisplayName("Should process valid stock update message successfully")
    void shouldProcessValidStockUpdateMessageSuccessfully() {
        // Arrange
        ApiResponse successResponse = ApiResponse.builder()
                .status("SUCCESS")
                .message("Stock updated successfully")
                .success(true)
                .httpStatus(200)
                .timestamp(LocalDateTime.now())
                .build();
        
        when(messageHashService.calculateMessageHash(any())).thenReturn(validStockMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        when(externalApiService.validateProduct(anyString())).thenReturn(Mono.just(
                ExternalApiService.ValidationResponse.builder()
                        .valid(true)
                        .productExists(true)
                        .build()));
        when(externalApiService.processStockUpdate(any())).thenReturn(Mono.just(successResponse));
        when(externalApiService.sendNotification(anyString(), anyString(), anyBoolean(), anyString()))
                .thenReturn(Mono.empty());
        
        // Act
        assertDoesNotThrow(() -> kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        // Assert
        verify(consumptionLogRepository, times(3)).save(any(ConsumptionLog.class));
        verify(externalApiService).validateProduct("PROD-001");
        verify(externalApiService).processStockUpdate(validStockMessage);
        verify(externalApiService).sendNotification(eq("test-correlation-123"), eq("PROD-001"), 
                eq(true), anyString());
    }
    
    @Test
    @DisplayName("Should handle invalid message hash")
    void shouldHandleInvalidMessageHash() {
        // Arrange
        when(messageHashService.calculateMessageHash(any())).thenReturn("invalid-hash");
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        
        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
                kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        assertTrue(exception.getMessage().contains("Message hash validation failed"));
        verify(consumptionLogRepository, atLeastOnce()).save(any(ConsumptionLog.class));
    }
    
    @Test
    @DisplayName("Should handle duplicate message")
    void shouldHandleDuplicateMessage() {
        // Arrange
        when(messageHashService.calculateMessageHash(any())).thenReturn(validStockMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(true);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        
        // Act
        assertDoesNotThrow(() -> kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        // Assert
        verify(consumptionLogRepository, atLeastOnce()).save(argThat(log -> 
                log.getStatus() == ConsumptionLog.ProcessingStatus.DISCARDED));
        verify(externalApiService, never()).processStockUpdate(any());
    }
    
    @Test
    @DisplayName("Should handle expired message")
    void shouldHandleExpiredMessage() {
        // Arrange
        StockUpdateMessage expiredMessage = StockUpdateMessage.builder()
                .correlationId("expired-123")
                .productId("PROD-002")
                .quantity(50)
                .price(new BigDecimal("10.00"))
                .operation("REMOVE")
                .hash("expired-hash-123456789012345678901234567890123456789012345678")
                .deadline(LocalDateTime.now().minusHours(1)) // Expired
                .build();
        
        when(messageHashService.calculateMessageHash(any())).thenReturn(expiredMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        
        // Act
        assertDoesNotThrow(() -> kafkaConsumerService.processMessage(expiredMessage, validConsumptionLog));
        
        // Assert
        verify(consumptionLogRepository, atLeastOnce()).save(argThat(log -> 
                log.getStatus() == ConsumptionLog.ProcessingStatus.DISCARDED &&
                log.getErrorMessage().contains("expired")));
        verify(externalApiService, never()).processStockUpdate(any());
    }
    
    @Test
    @DisplayName("Should handle product validation failure")
    void shouldHandleProductValidationFailure() {
        // Arrange
        when(messageHashService.calculateMessageHash(any())).thenReturn(validStockMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        when(externalApiService.validateProduct(anyString())).thenReturn(Mono.just(
                ExternalApiService.ValidationResponse.builder()
                        .valid(false)
                        .productExists(false)
                        .message("Product not found")
                        .build()));
        
        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
                kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        assertTrue(exception.getMessage().contains("Product validation failed"));
        verify(externalApiService).validateProduct("PROD-001");
        verify(externalApiService, never()).processStockUpdate(any());
    }
    
    @Test
    @DisplayName("Should handle external API failure")
    void shouldHandleExternalApiFailure() {
        // Arrange
        ApiResponse failureResponse = ApiResponse.builder()
                .status("ERROR")
                .message("External service unavailable")
                .success(false)
                .httpStatus(503)
                .timestamp(LocalDateTime.now())
                .build();
        
        when(messageHashService.calculateMessageHash(any())).thenReturn(validStockMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        when(externalApiService.validateProduct(anyString())).thenReturn(Mono.just(
                ExternalApiService.ValidationResponse.builder()
                        .valid(true)
                        .productExists(true)
                        .build()));
        when(externalApiService.processStockUpdate(any())).thenReturn(Mono.just(failureResponse));
        when(externalApiService.sendNotification(anyString(), anyString(), anyBoolean(), anyString()))
                .thenReturn(Mono.empty());
        
        // Act
        assertDoesNotThrow(() -> kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        // Assert
        verify(consumptionLogRepository, atLeastOnce()).save(argThat(log -> 
                log.getStatus() == ConsumptionLog.ProcessingStatus.FAILED));
        verify(externalApiService).sendNotification(eq("test-correlation-123"), eq("PROD-001"), 
                eq(false), anyString());
    }
    
    @Test
    @DisplayName("Should handle null API response")
    void shouldHandleNullApiResponse() {
        // Arrange
        when(messageHashService.calculateMessageHash(any())).thenReturn(validStockMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        when(externalApiService.validateProduct(anyString())).thenReturn(Mono.just(
                ExternalApiService.ValidationResponse.builder()
                        .valid(true)
                        .productExists(true)
                        .build()));
        when(externalApiService.processStockUpdate(any())).thenReturn(Mono.just((ApiResponse) null));
        
        // Act & Assert
        RuntimeException exception = assertThrows(RuntimeException.class, () -> 
                kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        assertTrue(exception.getMessage().contains("No response from external API"));
        verify(consumptionLogRepository, atLeastOnce()).save(argThat(log -> 
                log.getStatus() == ConsumptionLog.ProcessingStatus.FAILED));
    }
    
    @Test
    @DisplayName("Should update consumption log with processing times")
    void shouldUpdateConsumptionLogWithProcessingTimes() {
        // Arrange
        ApiResponse successResponse = ApiResponse.builder()
                .status("SUCCESS")
                .message("Processed successfully")
                .success(true)
                .httpStatus(200)
                .build();
        
        when(messageHashService.calculateMessageHash(any())).thenReturn(validStockMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        when(externalApiService.validateProduct(anyString())).thenReturn(Mono.just(
                ExternalApiService.ValidationResponse.builder().valid(true).build()));
        when(externalApiService.processStockUpdate(any())).thenReturn(Mono.just(successResponse));
        when(externalApiService.sendNotification(anyString(), anyString(), anyBoolean(), anyString()))
                .thenReturn(Mono.empty());
        
        // Act
        assertDoesNotThrow(() -> kafkaConsumerService.processMessage(validStockMessage, validConsumptionLog));
        
        // Assert
        verify(consumptionLogRepository, atLeastOnce()).save(argThat(log -> {
            return log.getProcessingStartedAt() != null && 
                   log.getProcessingCompletedAt() != null &&
                   log.getTotalProcessingTimeMs() != null &&
                   log.getTotalProcessingTimeMs() >= 0;
        }));
    }
    
    @Test
    @DisplayName("Should handle processing with high priority message")
    void shouldHandleProcessingWithHighPriorityMessage() {
        // Arrange
        StockUpdateMessage highPriorityMessage = StockUpdateMessage.builder()
                .correlationId("high-priority-123")
                .productId("URGENT-001")
                .quantity(200)
                .price(new BigDecimal("99.99"))
                .operation("SET")
                .hash("high-priority-hash123456789012345678901234567890123456789012")
                .priority("HIGH")
                .deadline(LocalDateTime.now().plusMinutes(30))
                .build();
        
        ApiResponse successResponse = ApiResponse.builder()
                .status("SUCCESS")
                .success(true)
                .httpStatus(200)
                .build();
        
        when(messageHashService.calculateMessageHash(any())).thenReturn(highPriorityMessage.getHash());
        when(consumptionLogRepository.isMessageAlreadyProcessed(anyString(), anyString())).thenReturn(false);
        when(consumptionLogRepository.save(any(ConsumptionLog.class))).thenReturn(validConsumptionLog);
        when(externalApiService.validateProduct(anyString())).thenReturn(Mono.just(
                ExternalApiService.ValidationResponse.builder().valid(true).build()));
        when(externalApiService.processStockUpdate(any())).thenReturn(Mono.just(successResponse));
        when(externalApiService.sendNotification(anyString(), anyString(), anyBoolean(), anyString()))
                .thenReturn(Mono.empty());
        
        // Act
        assertDoesNotThrow(() -> kafkaConsumerService.processMessage(highPriorityMessage, validConsumptionLog));
        
        // Assert
        verify(consumptionLogRepository, atLeastOnce()).save(argThat(log -> 
                "HIGH".equals(log.getPriority())));
        verify(externalApiService).processStockUpdate(argThat(msg -> 
                "HIGH".equals(msg.getPriority())));
    }
}
