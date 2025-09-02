package com.estudoskbnt.kbntlogservice.config;

import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;
import org.springframework.kafka.support.serializer.JsonSerializer;

import java.util.HashMap;
import java.util.Map;

/**
 * Enhanced Kafka Producer Configuration with detailed logging support
 */
@Configuration
public class EnhancedKafkaProducerConfig {

    @Value("${spring.kafka.bootstrap-servers:localhost:9092}")
    private String bootstrapServers;

    @Bean
    public ProducerFactory<String, Object> producerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // Basic Kafka configuration
        configProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        configProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, JsonSerializer.class);
        
        // Enhanced logging and reliability configuration
        configProps.put(ProducerConfig.ACKS_CONFIG, "all"); // Wait for all replicas
        configProps.put(ProducerConfig.RETRIES_CONFIG, 3); // Retry on failure
        configProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true); // Prevent duplicates
        
        // Performance and monitoring
        configProps.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384); // 16KB batches
        configProps.put(ProducerConfig.LINGER_MS_CONFIG, 5); // Wait 5ms for batching
        configProps.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432); // 32MB buffer
        configProps.put(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, 1048576); // 1MB max message
        
        // Timeout configuration for detailed logging
        configProps.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 30000); // 30 seconds
        configProps.put(ProducerConfig.DELIVERY_TIMEOUT_MS_CONFIG, 120000); // 2 minutes total
        configProps.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, 10000); // 10 seconds max block
        
        // Add client ID for producer identification in logs
        configProps.put(ProducerConfig.CLIENT_ID_CONFIG, "kbnt-stock-producer");
        
        // Enable detailed metrics for monitoring
        configProps.put(ProducerConfig.METRIC_REPORTER_CLASSES_CONFIG, "");
        configProps.put(ProducerConfig.METRICS_SAMPLE_WINDOW_MS_CONFIG, 30000);
        configProps.put(ProducerConfig.METRICS_NUM_SAMPLES_CONFIG, 2);
        
        return new DefaultKafkaProducerFactory<>(configProps);
    }

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {
        // Criar um producer factory específico para String, String
        Map<String, Object> configProps = new HashMap<>();
        configProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        configProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        configProps.put(ProducerConfig.ACKS_CONFIG, "all");
        configProps.put(ProducerConfig.RETRIES_CONFIG, 3);
        configProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        
        ProducerFactory<String, String> stringProducerFactory = new DefaultKafkaProducerFactory<>(configProps);
        KafkaTemplate<String, String> template = new KafkaTemplate<>(stringProducerFactory);
        template.setObservationEnabled(true);
        return template;
    }
    
    @Bean
    public KafkaTemplate<String, Object> kafkaObjectTemplate() {
        KafkaTemplate<String, Object> template = new KafkaTemplate<>(producerFactory());
        template.setObservationEnabled(true);
        return template;
    }
}
