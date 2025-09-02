package com.estudoskbnt.kbntlogservice.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.kafka.core.KafkaTemplate;
import lombok.extern.slf4j.Slf4j;

/**
 * Test Configuration for KBNT Log Service
 * 
 * This configuration provides mock implementations for external dependencies
 * when running in test mode, allowing the service to start without requiring
 * actual Kafka or Elasticsearch infrastructure.
 */
@Slf4j
@Configuration
@Profile("test")
public class TestConfiguration {

    /**
     * Mock KafkaTemplate bean for test environment
     * This prevents the application from failing when Kafka is not available
     */
    @Bean
    @Primary
    @SuppressWarnings("unchecked")
    public KafkaTemplate<String, String> mockKafkaTemplate() {
        log.info("🧪 Creating stub KafkaTemplate for test environment");
        // Create a stub implementation that does nothing
        return new KafkaTemplate<String, String>(null) {
            @Override
            public void send(String topic, String data) {
                log.debug("Test stub: Would send to topic '{}': {}", topic, data);
            }
        };
    }
}
