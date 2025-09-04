package com.estudoskbnt.kbntlogservice.performance;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.estudoskbnt.kbntlogservice.controller.StockUpdateController;
import com.estudoskbnt.kbntlogservice.model.StockUpdateMessage;
import com.estudoskbnt.kbntlogservice.producer.StockUpdateProducer;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class StockUpdateControllerPerformanceTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private StockUpdateProducer stockUpdateProducer;

    private ObjectMapper objectMapper;
    private ExecutorService executorService;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        executorService = Executors.newFixedThreadPool(20); // Thread pool for concurrent requests
    }

    @Test
    @DisplayName("Should handle 100 concurrent stock update requests successfully")
    @Timeout(30) // Test should complete within 30 seconds
    void shouldHandle100ConcurrentRequests() throws Exception {
        // Given
        final int REQUEST_COUNT = 100;
        final AtomicInteger successCount = new AtomicInteger(0);
        final AtomicInteger failureCount = new AtomicInteger(0);
        final AtomicLong totalResponseTime = new AtomicLong(0);
        final List<String> errors = new CopyOnWriteArrayList<>();

        // Mock the producer to simulate successful publication
        doNothing().when(stockUpdateProducer).processStockUpdate(any(StockUpdateMessage.class));

        // Create a CountDownLatch to ensure all threads start simultaneously
        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(REQUEST_COUNT);

        // When - Submit 100 concurrent requests
        List<Future<TestResult>> futures = new ArrayList<>();
        
        for (int i = 0; i < REQUEST_COUNT; i++) {
            final int requestId = i;
            Future<TestResult> future = executorService.submit(() -> {
                try {
                    // Wait for all threads to be ready
                    startLatch.await();
                    
                    long startTime = System.currentTimeMillis();
                    
                    // Create unique test message
                    StockUpdateMessage message = createTestMessage(requestId);
                    String jsonContent = objectMapper.writeValueAsString(message);
                    
                    // Perform HTTP request
                    MvcResult result = mockMvc.perform(post("/stock/update")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(jsonContent)
                            .header("X-Correlation-ID", "load-test-" + requestId))
                            .andReturn();
                    
                    long endTime = System.currentTimeMillis();
                    long responseTime = endTime - startTime;
                    
                    TestResult testResult = new TestResult();
                    testResult.requestId = requestId;
                    testResult.statusCode = result.getResponse().getStatus();
                    testResult.responseTime = responseTime;
                    testResult.success = (result.getResponse().getStatus() == 200);
                    
                    if (testResult.success) {
                        successCount.incrementAndGet();
                    } else {
                        failureCount.incrementAndGet();
                        errors.add("Request " + requestId + " failed with status: " + result.getResponse().getStatus());
                    }
                    
                    totalResponseTime.addAndGet(responseTime);
                    
                    return testResult;
                    
                } catch (Exception e) {
                    failureCount.incrementAndGet();
                    errors.add("Request " + requestId + " exception: " + e.getMessage());
                    return null;
                } finally {
                    completionLatch.countDown();
                }
            });
            
            futures.add(future);
        }
        
        // Start all threads simultaneously
        long testStartTime = System.currentTimeMillis();
        startLatch.countDown();
        
        // Wait for all requests to complete
        boolean completedInTime = completionLatch.await(25, TimeUnit.SECONDS);
        long testEndTime = System.currentTimeMillis();
        
        // Then - Validate results
        assertTrue(completedInTime, "All requests should complete within timeout");
        
        // Collect all results
        List<TestResult> results = new ArrayList<>();
        for (Future<TestResult> future : futures) {
            try {
                TestResult result = future.get(1, TimeUnit.SECONDS);
                if (result != null) {
                    results.add(result);
                }
            } catch (Exception e) {
                errors.add("Failed to get result: " + e.getMessage());
            }
        }
        
        // Calculate performance metrics
        long totalTestTime = testEndTime - testStartTime;
        double averageResponseTime = results.isEmpty() ? 0 : totalResponseTime.get() / (double) results.size();
        double requestsPerSecond = (results.size() * 1000.0) / totalTestTime;
        
        // Performance assertions
        assertEquals(REQUEST_COUNT, successCount.get() + failureCount.get(), 
            "Total processed requests should equal submitted requests");
        
        // At least 95% success rate
        double successRate = (successCount.get() * 100.0) / REQUEST_COUNT;
        assertTrue(successRate >= 95.0, 
            String.format("Success rate should be at least 95%%, got %.2f%%", successRate));
        
        // Average response time should be reasonable (under 1 second per request)
        assertTrue(averageResponseTime < 1000, 
            String.format("Average response time should be under 1000ms, got %.2fms", averageResponseTime));
        
        // Should handle at least 5 requests per second
        assertTrue(requestsPerSecond >= 5.0, 
            String.format("Should handle at least 5 requests/sec, got %.2f", requestsPerSecond));
        
        // Verify producer was called for successful requests
        verify(stockUpdateProducer, times(successCount.get()))
            .processStockUpdate(any(StockUpdateMessage.class));
        
        // Print performance summary
        System.out.println("\n=== PERFORMANCE TEST RESULTS ===");
        System.out.println("Total Requests: " + REQUEST_COUNT);
        System.out.println("Successful Requests: " + successCount.get());
        System.out.println("Failed Requests: " + failureCount.get());
        System.out.println(String.format("Success Rate: %.2f%%", successRate));
        System.out.println(String.format("Total Test Time: %dms", totalTestTime));
        System.out.println(String.format("Average Response Time: %.2fms", averageResponseTime));
        System.out.println(String.format("Requests per Second: %.2f", requestsPerSecond));
        
        if (!errors.isEmpty()) {
            System.out.println("\nErrors encountered:");
            errors.forEach(System.out::println);
        }
        
        // Fail test if too many errors
        if (failureCount.get() > 5) {
            fail("Too many failures: " + failureCount.get() + " out of " + REQUEST_COUNT);
        }
    }

    @Test
    @DisplayName("Should handle 100 concurrent requests with different product types")
    @Timeout(35)
    void shouldHandle100ConcurrentRequestsWithVariousProducts() throws Exception {
        // Given
        final int REQUEST_COUNT = 100;
        final AtomicInteger processedRequests = new AtomicInteger(0);
        final ConcurrentHashMap<String, AtomicInteger> productCounts = new ConcurrentHashMap<>();
        
        // Product types for variety
        String[] productTypes = {
            "SMARTPHONE", "LAPTOP", "TABLET", "HEADPHONES", "MONITOR", 
            "KEYBOARD", "MOUSE", "SPEAKER", "CAMERA", "PRINTER"
        };
        
        doNothing().when(stockUpdateProducer).processStockUpdate(any(StockUpdateMessage.class));
        
        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(REQUEST_COUNT);
        
        // When - Submit 100 requests with different products
        for (int i = 0; i < REQUEST_COUNT; i++) {
            final int requestId = i;
            final String productType = productTypes[i % productTypes.length];
            
            executorService.submit(() -> {
                try {
                    startLatch.await();
                    
                    StockUpdateMessage message = new StockUpdateMessage();
                    message.setProductId(productType + "-" + String.format("%03d", requestId));
                    message.setQuantity((requestId % 50) + 1); // 1-50 quantity
                    message.setDistributionCenter("WAREHOUSE-" + (requestId % 5 + 1));
                    message.setOperation((requestId % 2 == 0) ? "ADD" : "SET");
                    message.setTimestamp(LocalDateTime.now().plusSeconds(requestId));
                    message.setBranch("BRANCH-LOAD-TEST-" + (requestId / 10));
                    message.setCorrelationId("variety-test-" + requestId);
                    message.setSourceBranch("SOURCE-BRANCH-" + (requestId % 3));
                    
                    String jsonContent = objectMapper.writeValueAsString(message);
                    
                    MvcResult result = mockMvc.perform(post("/stock/update")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(jsonContent)
                            .header("X-Correlation-ID", "variety-test-" + requestId))
                            .andExpect(status().isOk())
                            .andReturn();
                    
                    processedRequests.incrementAndGet();
                    productCounts.computeIfAbsent(productType, k -> new AtomicInteger(0)).incrementAndGet();
                    
                } catch (Exception e) {
                    System.err.println("Request " + requestId + " failed: " + e.getMessage());
                } finally {
                    completionLatch.countDown();
                }
            });
        }
        
        // Start all threads and wait for completion
        startLatch.countDown();
        boolean completed = completionLatch.await(30, TimeUnit.SECONDS);
        
        // Then - Validate results
        assertTrue(completed, "All requests should complete within timeout");
        assertTrue(processedRequests.get() >= 95, 
            "At least 95 out of 100 requests should be processed successfully");
        
        // Verify all product types were processed
        assertTrue(productCounts.size() >= productTypes.length, 
            "All product types should be represented");
        
        // Verify producer was called for all processed requests
        verify(stockUpdateProducer, times(processedRequests.get()))
            .processStockUpdate(any(StockUpdateMessage.class));
        
        // Print variety test results
        System.out.println("\n=== VARIETY TEST RESULTS ===");
        System.out.println("Total Processed: " + processedRequests.get());
        System.out.println("Product Types Processed: " + productCounts.size());
        productCounts.forEach((product, count) -> 
            System.out.println(product + ": " + count.get() + " requests"));
    }

    @Test
    @DisplayName("Should maintain hash uniqueness across 100 concurrent requests")
    @Timeout(30)
    void shouldMaintainHashUniquenessAcross100Requests() throws Exception {
        // Given
        final int REQUEST_COUNT = 100;
        final ConcurrentHashMap<String, Integer> correlationIds = new ConcurrentHashMap<>();
        final AtomicInteger duplicateCount = new AtomicInteger(0);
        
        doNothing().when(stockUpdateProducer).processStockUpdate(any(StockUpdateMessage.class));
        
        final CountDownLatch startLatch = new CountDownLatch(1);
        final CountDownLatch completionLatch = new CountDownLatch(REQUEST_COUNT);
        
        // When - Submit 100 requests and track correlation IDs
        for (int i = 0; i < REQUEST_COUNT; i++) {
            final int requestId = i;
            
            executorService.submit(() -> {
                try {
                    startLatch.await();
                    
                    StockUpdateMessage message = createUniqueTestMessage(requestId);
                    String jsonContent = objectMapper.writeValueAsString(message);
                    String correlationId = "uniqueness-test-" + requestId + "-" + System.nanoTime();
                    
                    MvcResult result = mockMvc.perform(post("/stock/update")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(jsonContent)
                            .header("X-Correlation-ID", correlationId))
                            .andExpect(status().isOk())
                            .andReturn();
                    
                    // Check if correlation ID is unique
                    Integer previous = correlationIds.put(correlationId, requestId);
                    if (previous != null) {
                        duplicateCount.incrementAndGet();
                        System.err.println("Duplicate correlation ID detected: " + correlationId);
                    }
                    
                } catch (Exception e) {
                    System.err.println("Request " + requestId + " failed: " + e.getMessage());
                } finally {
                    completionLatch.countDown();
                }
            });
        }
        
        // Start and wait for completion
        startLatch.countDown();
        boolean completed = completionLatch.await(25, TimeUnit.SECONDS);
        
        // Then - Validate uniqueness
        assertTrue(completed, "All requests should complete within timeout");
        assertEquals(0, duplicateCount.get(), "No duplicate correlation IDs should be detected");
        assertTrue(correlationIds.size() >= 95, "At least 95 unique correlation IDs should be generated");
        
        System.out.println("\n=== UNIQUENESS TEST RESULTS ===");
        System.out.println("Unique Correlation IDs: " + correlationIds.size());
        System.out.println("Duplicate IDs Detected: " + duplicateCount.get());
    }

    // ===================== HELPER METHODS =====================

    private StockUpdateMessage createTestMessage(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("LOAD-TEST-PRODUCT-" + String.format("%03d", id));
        message.setQuantity((id % 100) + 1); // 1-100 quantity
        message.setDistributionCenter("WAREHOUSE-" + (id % 3 + 1)); // WAREHOUSE-1,2,3
        message.setOperation((id % 3 == 0) ? "ADD" : (id % 3 == 1) ? "SET" : "SUBTRACT");
        message.setTimestamp(LocalDateTime.now().plusMinutes(id));
        message.setBranch("LOAD-TEST-BRANCH-" + (id / 20)); // Group into batches of 20
        message.setCorrelationId("load-test-" + id);
        message.setSourceBranch("SOURCE-BRANCH-" + (id % 5));
        return message;
    }

    private StockUpdateMessage createUniqueTestMessage(int id) {
        StockUpdateMessage message = new StockUpdateMessage();
        message.setProductId("UNIQUE-" + id + "-" + System.nanoTime());
        message.setQuantity(id + 1);
        message.setDistributionCenter("UNIQUE-WAREHOUSE-" + id);
        message.setOperation("ADD");
        message.setTimestamp(LocalDateTime.now().plusNanos(id * 1000000L)); // Unique timestamps
        message.setBranch("UNIQUE-BRANCH-" + id);
        message.setCorrelationId("unique-test-" + id + "-" + System.nanoTime());
        message.setSourceBranch("UNIQUE-SOURCE-" + (id % 10));
        return message;
    }

    // Inner class to hold test results
    private static class TestResult {
        int requestId;
        int statusCode;
        long responseTime;
        boolean success;
    }
}
