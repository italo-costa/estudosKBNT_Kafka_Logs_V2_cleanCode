package com.estudoskbnt.consumer.config;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.ContainerProperties;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.util.backoff.FixedBackOff;

import com.estudoskbnt.consumer.model.StockUpdateMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;

public class KafkaConsumerConfig {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(KafkaConsumerConfig.class);
    
    @Value("${app.kafka.bootstrap-servers}")
    private String bootstrapServers;
    
    @Value("${app.kafka.consumer.group-id}")
    private String groupId;
    
    @Value("${app.kafka.consumer.auto-offset-reset:earliest}")
    private String autoOffsetReset;
    
    @Value("${app.kafka.consumer.enable-auto-commit:false}")
    private Boolean enableAutoCommit;
    
    @Value("${app.kafka.consumer.max-poll-records:500}")
    private Integer maxPollRecords;
    
    @Value("${app.kafka.consumer.session-timeout-ms:30000}")
    private Integer sessionTimeoutMs;
    
    @Value("${app.kafka.consumer.heartbeat-interval-ms:3000}")
    private Integer heartbeatIntervalMs;
    
    @Value("${app.kafka.consumer.max-poll-interval-ms:300000}")
    private Integer maxPollIntervalMs;
    
    @Value("${app.kafka.consumer.concurrency:3}")
    private Integer concurrency;
    
    // Security configuration
    @Value("${app.kafka.security.protocol:PLAINTEXT}")
    private String securityProtocol;
    
    @Value("${app.kafka.ssl.trust-store-location:}")
    private String trustStoreLocation;
    
    @Value("${app.kafka.ssl.trust-store-password:}")
    private String trustStorePassword;
    
    @Value("${app.kafka.sasl.mechanism:}")
    private String saslMechanism;
    
    @Value("${app.kafka.sasl.jaas-config:}")
    private String saslJaasConfig;
    
    /**
     * Kafka Consumer Factory Configuration
     */
    @Bean
    public ConsumerFactory<String, String> consumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // Basic configuration
        configProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        configProps.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        configProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, autoOffsetReset);
        configProps.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, enableAutoCommit);
        
        // Performance and reliability settings
        configProps.put(ConsumerConfig.MAX_POLL_RECORDS_CONFIG, maxPollRecords);
        configProps.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, sessionTimeoutMs);
        configProps.put(ConsumerConfig.HEARTBEAT_INTERVAL_MS_CONFIG, heartbeatIntervalMs);
        configProps.put(ConsumerConfig.MAX_POLL_INTERVAL_MS_CONFIG, maxPollIntervalMs);
        
        // Serialization
        configProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        configProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        
        // Consumer behavior
        configProps.put(ConsumerConfig.FETCH_MIN_BYTES_CONFIG, 1);
        configProps.put(ConsumerConfig.FETCH_MAX_WAIT_MS_CONFIG, 500);
        configProps.put(ConsumerConfig.REQUEST_TIMEOUT_MS_CONFIG, 60000);
        configProps.put(ConsumerConfig.RETRY_BACKOFF_MS_CONFIG, 1000);
        
        // Client identification
        configProps.put(ConsumerConfig.CLIENT_ID_CONFIG, "kbnt-stock-consumer-" + groupId);
        
        // Security configuration
        if (!"PLAINTEXT".equals(securityProtocol)) {
            configProps.put("security.protocol", securityProtocol);
            
            if (trustStoreLocation != null && !trustStoreLocation.isEmpty()) {
                configProps.put("ssl.truststore.location", trustStoreLocation);
                configProps.put("ssl.truststore.password", trustStorePassword);
            }
            
            if (saslMechanism != null && !saslMechanism.isEmpty()) {
                configProps.put("sasl.mechanism", saslMechanism);
                configProps.put("sasl.jaas.config", saslJaasConfig);
            }
        }
        
        log.info("Kafka Consumer configured with bootstrap servers: {}, group: {}", 
                bootstrapServers, groupId);
        
        return new DefaultKafkaConsumerFactory<>(configProps);
    }
    
    /**
     * Kafka Listener Container Factory
     */
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, String> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = 
                new ConcurrentKafkaListenerContainerFactory<>();
        
        factory.setConsumerFactory(consumerFactory());
        factory.setConcurrency(concurrency);
        
        // Manual acknowledgment mode for better control
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL);
        
        // Error handling
        factory.setCommonErrorHandler(new org.springframework.kafka.listener.DefaultErrorHandler(
        (record, exception) -> {
            log.error("Error processing record: {} - Exception: {}", 
                record, exception.getMessage());
        },
        new org.springframework.util.backoff.FixedBackOff(1000L, 3) // max attempts
    ));
        
        // Consumer rebalance listener
        factory.getContainerProperties().setConsumerRebalanceListener(
                new org.apache.kafka.clients.consumer.ConsumerRebalanceListener() {
                    @Override
                    public void onPartitionsRevoked(java.util.Collection<org.apache.kafka.common.TopicPartition> partitions) {
                        log.info("Partitions revoked: {}", partitions);
                    }
                    
                    @Override
                    public void onPartitionsAssigned(java.util.Collection<org.apache.kafka.common.TopicPartition> partitions) {
                        log.info("Partitions assigned: {}", partitions);
                    }
                }
        );
        
        // Metrics and monitoring
        factory.getContainerProperties().setMonitorInterval(30000); // 30 seconds
        
        log.info("Kafka Listener Container Factory configured with concurrency: {}", concurrency);
        
        return factory;
    }
    
    /**
     * Kafka Consumer Factory for StockUpdateMessage objects
     */
    @Bean
    public ConsumerFactory<String, StockUpdateMessage> stockUpdateConsumerFactory() {
        Map<String, Object> configProps = new HashMap<>();
        
        // Copy base configuration
        configProps.putAll(consumerFactory().getConfigurationProperties());
        
        // JSON deserialization configuration
        configProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, JsonDeserializer.class);
        configProps.put(JsonDeserializer.VALUE_DEFAULT_TYPE, StockUpdateMessage.class.getName());
        configProps.put(JsonDeserializer.TRUSTED_PACKAGES, "com.estudoskbnt.consumer.model");
        configProps.put(JsonDeserializer.USE_TYPE_INFO_HEADERS, false);
        
        return new DefaultKafkaConsumerFactory<>(configProps, 
                new StringDeserializer(), 
                new JsonDeserializer<>(StockUpdateMessage.class));
    }
    
    /**
     * Kafka Listener Container Factory for StockUpdateMessage
     */
    @Bean("stockUpdateKafkaListenerContainerFactory")
    public ConcurrentKafkaListenerContainerFactory<String, StockUpdateMessage> 
            stockUpdateKafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, StockUpdateMessage> factory = 
                new ConcurrentKafkaListenerContainerFactory<>();
        
        factory.setConsumerFactory(stockUpdateConsumerFactory());
        factory.setConcurrency(concurrency);
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL);
        
        return factory;
    }
    
    /**
     * Object Mapper for JSON processing
     */
    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());
        mapper.configure(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
        mapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        return mapper;
    }
}
