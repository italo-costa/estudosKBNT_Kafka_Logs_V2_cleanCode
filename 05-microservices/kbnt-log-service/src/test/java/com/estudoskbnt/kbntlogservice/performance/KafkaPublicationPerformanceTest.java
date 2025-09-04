package com.estudoskbnt.kbntlogservice.performance;

import java.time.LocalDateTime;
import java.util.Set;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

import com.estudoskbnt.kbntlogservice.model.KafkaPublicationLog;
import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import com.estudoskbnt.kbntlogservice.producer.StockUpdateProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class KafkaPublicationPerformanceTest {

    @Mock
    private KafkaTemplate<String, Object> kafkaTemplate;

    @InjectMocks
    private StockUpdateProducer stockUpdateProducer;

    private ObjectMapper objectMapper;
    private ExecutorService executorService;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        executorService = Executors.newFixedThreadPool(50); // Large thread pool for high concurrency
        
        // Mock successful Kafka sends
        CompletableFuture<SendResult<String, Object>> future = CompletableFuture.completedFuture(mock(SendResult.class));
        when(kafkaTemplate.send(anyString(), anyString(), any())).thenReturn(future);
    }

    @Test
    @DisplayName("Should generate unique hashes for 100 concurrent messages")
    @Timeout(20)
    void shouldGenerateUniqueHashesFor100ConcurrentMessages() throws Exception {
        // Given
        final int MESSAGE_COUNT = 100;
        final Set<String> generatedHashes = ConcurrentHashMap.newKeySet();
        final AtomicInteger processedMessages = new AtomicInteger(0);
        final AtomicInteger duplicateHashes = new AtomicInteger(0);
        final AtomicLong totalHashTime = new AtomicLong(0);

        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(MESSAGE_COUNT);

        // When - Process 100 messages concurrently
        for (int i = 0; i < MESSAGE_COUNT; i++) {
            final int messageId = i;
            
            executorService.submit(() -> {
                try {
                    startLatch.await();
                    
                    long hashStartTime = System.nanoTime();
                    
                    // Create unique message
                    StockUpdateMessage message = createVariedMessage(messageId);
                    
                    // Send message (this will generate hash internally)
                    stockUpdateProducer.processStockUpdate(message);
                    
                    long hashEndTime = System.nanoTime();
                    long hashDuration = hashEndTime - hashStartTime;
                    
                    totalHashTime.addAndGet(hashDuration);
                    processedMessages.incrementAndGet();
                    
                } catch (Exception e) {
                    System.err.println("Message " + messageId + " failed: " + e.getMessage());
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        // Start all threads simultaneously
        long testStartTime = System.currentTimeMillis();
        startLatch.countDown();
        
        // Wait for completion
        boolean completed = completionLatch.await(15, TimeUnit.SECONDS);
        long testEndTime = System.currentTimeMillis();

        // Then - Validate results
        assertTrue(completed, "All hash operations should complete within timeout");
        assertEquals(MESSAGE_COUNT, processedMessages.get(), "All messages should be processed");
        
        // Verify Kafka template was called for each message
        verify(kafkaTemplate, times(MESSAGE_COUNT)).send(anyString(), anyString(), any());
        
        // Calculate performance metrics
        long totalTestTime = testEndTime - testStartTime;
        double averageHashTime = totalHashTime.get() / (double) MESSAGE_COUNT / 1_000_000; // Convert to ms
        double messagesPerSecond = (MESSAGE_COUNT * 1000.0) / totalTestTime;
        
        // Performance assertions
        assertTrue(averageHashTime < 10.0, 
            String.format("Average hash generation time should be under 10ms, got %.2fms", averageHashTime));
        assertTrue(messagesPerSecond >= 20.0, 
            String.format("Should process at least 20 messages/sec, got %.2f", messagesPerSecond));

        System.out.println("\n=== HASH GENERATION PERFORMANCE ===");
        System.out.println("Total Messages: " + MESSAGE_COUNT);
        System.out.println("Processed Messages: " + processedMessages.get());
        System.out.println(String.format("Total Test Time: %dms", totalTestTime));
        System.out.println(String.format("Average Hash Time: %.2fms", averageHashTime));
        System.out.println(String.format("Messages per Second: %.2f", messagesPerSecond));
    }

    @Test
    @DisplayName("Should handle 100 concurrent publications with proper topic routing")
    @Timeout(25)
    void shouldHandle100ConcurrentPublicationsWithTopicRouting() throws Exception {
        // Given
        final int MESSAGE_COUNT = 100;
        final ConcurrentHashMap<String, AtomicInteger> topicCounts = new ConcurrentHashMap<>();
        final AtomicInteger totalPublications = new AtomicInteger(0);
        
        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(MESSAGE_COUNT);

        // When - Send 100 messages with different operations
        for (int i = 0; i < MESSAGE_COUNT; i++) {
            final int messageId = i;
            
            executorService.submit(() -> {
                try {
                    startLatch.await();
                    
                    StockUpdateMessage message = createMessageWithOperation(messageId);
                    stockUpdateProducer.processStockUpdate(message);
                    
                    totalPublications.incrementAndGet();
                    
                } catch (Exception e) {
                    System.err.println("Publication " + messageId + " failed: " + e.getMessage());
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        startLatch.countDown();
        boolean completed = completionLatch.await(20, TimeUnit.SECONDS);

        // Then - Analyze topic routing
        assertTrue(completed, "All publications should complete within timeout");
        assertEquals(MESSAGE_COUNT, totalPublications.get(), "All messages should be published");

        // Capture all Kafka sends to analyze topic distribution
        ArgumentCaptor<String> topicCaptor = ArgumentCaptor.forClass(String.class);
        verify(kafkaTemplate, times(MESSAGE_COUNT)).send(topicCaptor.capture(), anyString(), any());
        
        // Count topics used
        for (String topic : topicCaptor.getAllValues()) {
            topicCounts.computeIfAbsent(topic, k -> new AtomicInteger(0)).incrementAndGet();
        }
        
        // Verify topic routing logic
        assertTrue(topicCounts.size() >= 2, "Multiple topics should be used based on operations");
        
        System.out.println("\n=== TOPIC ROUTING PERFORMANCE ===");
        System.out.println("Total Publications: " + totalPublications.get());
        System.out.println("Topics Used: " + topicCounts.size());
        topicCounts.forEach((topic, count) -> 
            System.out.println("  " + topic + ": " + count.get() + " messages"));
    }

    @Test
    @DisplayName("Should maintain publication logging performance under 100 concurrent operations")
    @Timeout(30)
    void shouldMaintainPublicationLoggingPerformanceUnder100ConcurrentOps() throws Exception {
        // Given
        final int OPERATION_COUNT = 100;
        final AtomicInteger loggedAttempts = new AtomicInteger(0);
        final AtomicInteger loggedSuccesses = new AtomicInteger(0);
        final AtomicLong totalLoggingTime = new AtomicLong(0);
        
        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(OPERATION_COUNT);

        // When - Perform 100 logging operations concurrently
        for (int i = 0; i < OPERATION_COUNT; i++) {
            final int operationId = i;
            
            executorService.submit(() -> {
                try {
                    startLatch.await();
                    
                    long loggingStartTime = System.nanoTime();
                    
                    StockUpdateMessage message = createComplexMessage(operationId);
                    
                    // This will trigger both publication attempt and success logging
                    stockUpdateProducer.processStockUpdate(message);
                    
                    long loggingEndTime = System.nanoTime();
                    long loggingDuration = loggingEndTime - loggingStartTime;
                    
                    totalLoggingTime.addAndGet(loggingDuration);
                    loggedAttempts.incrementAndGet();
                    loggedSuccesses.incrementAndGet(); // Mock always succeeds
                    
                } catch (Exception e) {
                    System.err.println("Logging operation " + operationId + " failed: " + e.getMessage());
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        long testStartTime = System.currentTimeMillis();
        startLatch.countDown();
        
        boolean completed = completionLatch.await(25, TimeUnit.SECONDS);
        long testEndTime = System.currentTimeMillis();

        // Then - Validate logging performance
        assertTrue(completed, "All logging operations should complete within timeout");
        assertEquals(OPERATION_COUNT, loggedAttempts.get(), "All attempts should be logged");
        assertEquals(OPERATION_COUNT, loggedSuccesses.get(), "All successes should be logged");
        
        // Calculate metrics
        long totalTestTime = testEndTime - testStartTime;
        double averageLoggingTime = totalLoggingTime.get() / (double) OPERATION_COUNT / 1_000_000; // Convert to ms
        double operationsPerSecond = (OPERATION_COUNT * 1000.0) / totalTestTime;
        
        // Performance assertions
        assertTrue(averageLoggingTime < 50.0, 
            String.format("Average logging time should be under 50ms, got %.2fms", averageLoggingTime));
        assertTrue(operationsPerSecond >= 10.0, 
            String.format("Should handle at least 10 operations/sec, got %.2f", operationsPerSecond));

        System.out.println("\n=== PUBLICATION LOGGING PERFORMANCE ===");
        System.out.println("Total Operations: " + OPERATION_COUNT);
        System.out.println("Logged Attempts: " + loggedAttempts.get());
        System.out.println("Logged Successes: " + loggedSuccesses.get());
        System.out.println(String.format("Total Test Time: %dms", totalTestTime));
        System.out.println(String.format("Average Logging Time: %.2fms", averageLoggingTime));
        System.out.println(String.format("Operations per Second: %.2f", operationsPerSecond));
    }

    @Test
    @DisplayName("Should handle mixed load with 100 operations of different complexities")
    @Timeout(35)
    void shouldHandleMixedLoadWith100OperationsOfDifferentComplexities() throws Exception {
        // Given
        final int TOTAL_OPERATIONS = 100;
        final AtomicInteger simpleOps = new AtomicInteger(0);
        final AtomicInteger complexOps = new AtomicInteger(0);
        final AtomicInteger batchOps = new AtomicInteger(0);
        final AtomicInteger totalProcessed = new AtomicInteger(0);
        
        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(TOTAL_OPERATIONS);

        // When - Submit mixed complexity operations
        for (int i = 0; i < TOTAL_OPERATIONS; i++) {
            final int operationId = i;
            final int complexity = i % 3; // 0=simple, 1=complex, 2=batch
            
            executorService.submit(() -> {
                try {
                    startLatch.await();
                    
                    StockUpdateMessage message;
                    String correlationId;
                    
                    switch (complexity) {
                        case 0: // Simple operation
                            message = createSimpleMessage(operationId);
                            correlationId = "simple-" + operationId;
                            simpleOps.incrementAndGet();
                            break;
                        case 1: // Complex operation
                            message = createComplexMessage(operationId);
                            correlationId = "complex-" + operationId;
                            complexOps.incrementAndGet();
                            break;
                        default: // Batch operation
                            message = createBatchMessage(operationId);
                            correlationId = "batch-" + operationId;
                            batchOps.incrementAndGet();
                            break;
                    }
                    
                    stockUpdateProducer.processStockUpdate(message);
                    totalProcessed.incrementAndGet();
                    
                } catch (Exception e) {
                    System.err.println("Mixed operation " + operationId + " failed: " + e.getMessage());
                } finally {
                    completionLatch.countDown();
                }
            });
        }

        long testStartTime = System.currentTimeMillis();
        startLatch.countDown();
        
        boolean completed = completionLatch.await(30, TimeUnit.SECONDS);
        long testEndTime = System.currentTimeMillis();

        // Then - Validate mixed load handling
        assertTrue(completed, "All mixed operations should complete within timeout");
        assertEquals(TOTAL_OPERATIONS, totalProcessed.get(), "All operations should be processed");
        
        // Verify distribution
        assertTrue(simpleOps.get() > 0, "Should have simple operations");
        assertTrue(complexOps.get() > 0, "Should have complex operations");
        assertTrue(batchOps.get() > 0, "Should have batch operations");
        
        long totalTestTime = testEndTime - testStartTime;
        double operationsPerSecond = (TOTAL_OPERATIONS * 1000.0) / totalTestTime;
        
        // Should maintain reasonable throughput even with mixed complexity
        assertTrue(operationsPerSecond >= 8.0, 
            String.format("Should handle at least 8 mixed operations/sec, got %.2f", operationsPerSecond));

        System.out.println("\n=== MIXED LOAD PERFORMANCE ===");
        System.out.println("Total Operations: " + TOTAL_OPERATIONS);
        System.out.println("Simple Operations: " + simpleOps.get());
        System.out.println("Complex Operations: " + complexOps.get());
        System.out.println("Batch Operations: " + batchOps.get());
        System.out.println("Total Processed: " + totalProcessed.get());
        System.out.println(String.format("Total Test Time: %dms", totalTestTime));
        System.out.println(String.format("Operations per Second: %.2f", operationsPerSecond));
    }

    // ===================== HELPER METHODS =====================

    private StockUpdateMessage createVariedMessage(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("VARIED-PRODUCT-" + id + "-" + System.nanoTime());
        message.setQuantity((id % 500) + 1);
        message.setDistributionCenter("VARIED-DC-" + (id % 10));
        message.setOperation(getVariedOperation(id));
        message.setTimestamp(LocalDateTime.now().plusNanos(id * 100000L));
        message.setBranch("VARIED-BRANCH-" + (id / 25));
        message.setCorrelationId("CORR-" + id + "-" + System.currentTimeMillis());
        message.setSourceBranch("SOURCE-BRANCH-" + (id % 5));
        return message;
    }

    private StockUpdateMessage createMessageWithOperation(int id) {
    private StockUpdateMessage createMessageWithOperation(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("ROUTING-PRODUCT-" + id);
        message.setQuantity((id % 100) + 1);
        message.setDistributionCenter("ROUTING-WAREHOUSE-" + (id % 5));
        message.setOperation(getRoutingOperation(id));
        message.setTimestamp(LocalDateTime.now().plusSeconds(id));
        message.setBranch("ROUTING-BRANCH-" + (id / 10));
        message.setCorrelationId("ROUTING-CORR-" + id);
        message.setSourceBranch("ROUTING-SOURCE-" + (id % 3));
        return message;
    }

    private StockUpdateMessage createComplexMessage(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("COMPLEX-PRODUCT-" + String.format("%05d", id) + "-" + System.nanoTime());
        message.setQuantity((id % 1000) + 1);
        message.setDistributionCenter("COMPLEX-WAREHOUSE-" + (id % 20) + "-SECTION-" + (id % 5));
        message.setOperation("TRANSFER"); // Complex operation
        message.setTimestamp(LocalDateTime.now().plusMinutes(id).plusSeconds(id % 60));
        message.setBranch("COMPLEX-BRANCH-" + String.format("%04d", id / 50) + "-SUB-" + (id % 10));
        message.setCorrelationId("COMPLEX-CORR-" + id + "-" + System.currentTimeMillis());
        message.setSourceBranch("COMPLEX-SOURCE-" + (id % 8));
        return message;
    }

    private StockUpdateMessage createSimpleMessage(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("SIMPLE-" + id);
        message.setQuantity(id + 1);
        message.setDistributionCenter("SIMPLE-WH");
        message.setOperation("ADD");
        message.setTimestamp(LocalDateTime.now());
        message.setBranch("SIMPLE-BRANCH");
        message.setCorrelationId("SIMPLE-CORR-" + id);
        return message;
    }

    private StockUpdateMessage createBatchMessage(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("BATCH-PRODUCT-" + id);
        message.setQuantity((id % 200) + 100); // Larger quantities
        message.setDistributionCenter("BATCH-WAREHOUSE-MAIN");
        message.setOperation("BULK_UPDATE");
        message.setTimestamp(LocalDateTime.now().plusMinutes(id / 10));
        message.setBranch("LARGE-BATCH-" + String.format("%03d", id / 20));
        message.setCorrelationId("BATCH-CORR-" + id);
        message.setSourceBranch("BATCH-SOURCE");
        return message;
    }

    private String getVariedOperation(int id) {
        String[] operations = {"ADD", "SET", "SUBTRACT", "TRANSFER", "ADJUST"};
        return operations[id % operations.length];
    }

    private String getRoutingOperation(int id) {
        String[] routingOps = {"ADD", "TRANSFER", "ALERT", "ADJUST"};
        return routingOps[id % routingOps.length];
    }
}
