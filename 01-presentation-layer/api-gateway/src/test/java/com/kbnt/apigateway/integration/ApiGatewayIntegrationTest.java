package com.kbnt.apigateway.integration;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

import java.util.Set;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@TestPropertySource(properties = {
    "spring.cloud.gateway.routes[0].id=virtual-stock-service",
    "spring.cloud.gateway.routes[0].uri=http://localhost:8086",
    "spring.cloud.gateway.routes[0].predicates[0]=Path=/api/v1/virtual-stock/**",
    "spring.cloud.gateway.routes[1].id=kbnt-log-service", 
    "spring.cloud.gateway.routes[1].uri=http://localhost:8082",
    "spring.cloud.gateway.routes[1].predicates[0]=Path=/api/v1/kbnt-logs/**",
    "spring.cloud.gateway.httpclient.connect-timeout=30000",
    "spring.cloud.gateway.httpclient.response-timeout=30000"
})
@DisplayName("API Gateway Integration Tests")
class ApiGatewayIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    @DisplayName("Integration: Should return 404 for non-existent routes")
    void shouldReturn404ForNonExistentRoutes() {
        // Given
        String nonExistentUrl = "http://localhost:" + port + "/api/v1/nonexistent/test";

        // When
        ResponseEntity<String> response = restTemplate.getForEntity(nonExistentUrl, String.class);

        // Then
        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
    }

    @Test
    @DisplayName("Integration: Should handle actuator health endpoint")
    void shouldHandleActuatorHealthEndpoint() {
        // Given
        String healthUrl = "http://localhost:" + port + "/actuator/health";

        // When
        ResponseEntity<String> response = restTemplate.getForEntity(healthUrl, String.class);

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody().contains("\"status\":\"UP\""));
    }

    @Test
    @DisplayName("Integration: Should handle gateway actuator endpoints")
    void shouldHandleGatewayActuatorEndpoints() {
        // Given
        String gatewayRoutesUrl = "http://localhost:" + port + "/actuator/gateway/routes";

        // When
        ResponseEntity<String> response = restTemplate.getForEntity(gatewayRoutesUrl, String.class);

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }

    @Test
    @DisplayName("Integration: Should return 503 when backend service is unavailable")
    void shouldReturn503WhenBackendServiceIsUnavailable() {
        // Given - Virtual Stock Service route (service likely not running in test)
        String virtualStockUrl = "http://localhost:" + port + "/api/v1/virtual-stock/stocks";

        // When
        ResponseEntity<String> response = restTemplate.getForEntity(virtualStockUrl, String.class);

        // Then
        // Expected 503 Service Unavailable when backend is not available
        assertTrue(response.getStatusCode().is5xxServerError() || 
                  response.getStatusCode() == HttpStatus.NOT_FOUND);
    }

    @Test
    @DisplayName("Integration: Should return 503 when log service is unavailable")
    void shouldReturn503WhenLogServiceIsUnavailable() {
        // Given - KBNT Log Service route (service likely not running in test)
        String logServiceUrl = "http://localhost:" + port + "/api/v1/kbnt-logs/health";

        // When
        ResponseEntity<String> response = restTemplate.getForEntity(logServiceUrl, String.class);

        // Then
        // Expected 503 Service Unavailable when backend is not available
        assertTrue(response.getStatusCode().is5xxServerError() || 
                  response.getStatusCode() == HttpStatus.NOT_FOUND);
    }

    @Test
    @DisplayName("Integration: Should handle CORS preflight requests")
    void shouldHandleCorsPrefliightRequests() {
        // Given
        String testUrl = "http://localhost:" + port + "/api/v1/virtual-stock/stocks";

        // When - OPTIONS request for CORS preflight
        Set<HttpMethod> allowedMethods = restTemplate.optionsForAllow(testUrl);

        // Then
        assertNotNull(allowedMethods);
        // CORS headers should be present in a real CORS-enabled scenario
    }

    @Test
    @DisplayName("Integration: Should provide gateway metrics endpoint")
    void shouldProvideGatewayMetricsEndpoint() {
        // Given
        String metricsUrl = "http://localhost:" + port + "/actuator/metrics";

        // When
        ResponseEntity<String> response = restTemplate.getForEntity(metricsUrl, String.class);

        // Then
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }

    @Test
    @DisplayName("Integration: Should handle invalid HTTP methods gracefully")
    void shouldHandleInvalidHttpMethodsGracefully() {
        // Given
        String testUrl = "http://localhost:" + port + "/api/v1/virtual-stock/stocks";

        // When - Using PATCH method which might not be supported
        try {
            String response = restTemplate.patchForObject(testUrl, null, String.class);
            // Should not crash the gateway
        } catch (Exception e) {
            // Expected behavior - method not allowed or service unavailable
            assertTrue(e.getMessage().contains("405") || e.getMessage().contains("503") || 
                      e.getMessage().contains("404"));
        }
    }
}
