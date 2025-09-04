package com.estudoskbnt.kbntlogservice.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.SendResult;
import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.CompletableFuture;

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
     * Mock ProducerFactory bean for test environment
     */
    @Bean
    @Primary
    public ProducerFactory<String, String> mockProducerFactory() {
        return new ProducerFactory<String, String>() {
            @Override
            public org.apache.kafka.clients.producer.Producer<String, String> createProducer() {
                return null; // We won't use this in our mock KafkaTemplate
            }
        };
    }

    /**
     * Mock KafkaTemplate bean for test environment
     * This prevents the application from failing when Kafka is not available
     */
    @Bean
    @Primary
    public KafkaTemplate<String, String> mockKafkaTemplate(ProducerFactory<String, String> producerFactory) {
        log.info("🧪 Creating mock KafkaTemplate for test environment");
        
        return new KafkaTemplate<String, String>(producerFactory) {
            @Override
            public CompletableFuture<SendResult<String, String>> send(String topic, String data) {
                log.debug("Test stub: Would send to topic '{}': {}", topic, data);
                CompletableFuture<SendResult<String, String>> future = new CompletableFuture<>();
                future.complete(null);
                return future;
            }
        };
    }
}
