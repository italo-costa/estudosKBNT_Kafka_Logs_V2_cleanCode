package com.kbnt.apigateway;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@DisplayName("API Gateway Application Context Tests")
class ApiGatewayApplicationTest {

    @Autowired
    private ApplicationContext applicationContext;

    @Test
    @DisplayName("Should load application context successfully")
    void shouldLoadApplicationContextSuccessfully() {
        // Then
        assertNotNull(applicationContext);
    }

    @Test
    @DisplayName("Should have required Spring Cloud Gateway beans")
    void shouldHaveRequiredSpringCloudGatewayBeans() {
        // Then
        assertTrue(applicationContext.containsBean("routeDefinitionRouteLocator"));
        assertTrue(applicationContext.containsBean("cachedCompositeRouteLocator"));
    }
}
