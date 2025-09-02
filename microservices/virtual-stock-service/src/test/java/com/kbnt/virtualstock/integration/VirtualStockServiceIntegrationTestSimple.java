package com.kbnt.virtualstock.integration;

import com.kbnt.virtualstock.VirtualStockApplication;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

/**
 * Simple integration test for Virtual Stock Service.
 */
@SpringBootTest(classes = VirtualStockApplication.class)
@ActiveProfiles("test")
class VirtualStockServiceIntegrationTestSimple {

    @Test
    void contextLoads() {
        // This test ensures that the Spring context loads successfully
        // and all beans are properly configured
        assertDoesNotThrow(() -> {
            // Context loaded successfully if no exception is thrown
        });
    }

    @Test
    void applicationStartsSuccessfully() {
        // This test verifies that the application can start without errors
        // All @Component, @Service, @Repository beans should be properly instantiated
        assertDoesNotThrow(() -> {
            // Application started successfully
        });
    }
}
