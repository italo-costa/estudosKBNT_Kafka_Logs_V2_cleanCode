package com.estudoskbnt.logconsumer.config;

import com.estudoskbnt.logconsumer.infrastructure.kafka.IndependentTopicConfiguration;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaAdmin;

import jakarta.annotation.PostConstruct;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Independent Consumer Topic Configuration
 * Ensures required topics exist before starting consumer services
 */
@Slf4j
@Configuration
public class ConsumerTopicConfiguration {

    private final KafkaAdmin kafkaAdmin;
    
    @Value("${app.kafka.topics.application-logs:application-logs}")
    private String applicationLogsTopic;
    
    @Value("${app.kafka.topics.error-logs:error-logs}")
    private String errorLogsTopic;
    
    @Value("${app.kafka.topics.audit-logs:audit-logs}")
    private String auditLogsTopic;
    
    @Value("${app.kafka.topics.financial-logs:financial-logs}")
    private String financialLogsTopic;
    
    @Value("${app.kafka.topics.partitions:3}")
    private int defaultPartitions;
    
    @Value("${app.kafka.topics.replication-factor:1}")
    private short defaultReplicationFactor;
    
    @Value("${app.independence.topic-creation-timeout:30000}")
    private long topicCreationTimeout;

    public ConsumerTopicConfiguration(KafkaAdmin kafkaAdmin) {
        this.kafkaAdmin = kafkaAdmin;
    }

    @PostConstruct
    public void initializeTopics() {
        log.info("Initializing consumer topics configuration...");
        
        CompletableFuture.runAsync(() -> {
            try {
                createRequiredTopicsIfNotExist();
                log.info("Consumer topic initialization completed successfully");
            } catch (Exception e) {
                log.error("Failed to initialize consumer topics", e);
                // Continue startup - consumer will handle missing topics gracefully
            }
        });
    }

    private void createRequiredTopicsIfNotExist() {
        try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
            
            List<NewTopic> topicsToCreate = Arrays.asList(
                createTopicDefinition(applicationLogsTopic),
                createTopicDefinition(errorLogsTopic),
                createTopicDefinition(auditLogsTopic),
                createTopicDefinition(financialLogsTopic)
            );

            // Check existing topics first
            var existingTopics = adminClient.listTopics().names()
                .get(topicCreationTimeout, TimeUnit.MILLISECONDS);

            var newTopics = topicsToCreate.stream()
                .filter(topic -> !existingTopics.contains(topic.name()))
                .toList();

            if (newTopics.isEmpty()) {
                log.info("All required consumer topics already exist");
                return;
            }

            log.info("Creating {} missing consumer topics: {}", 
                newTopics.size(), 
                newTopics.stream().map(NewTopic::name).toList());

            CreateTopicsResult result = adminClient.createTopics(newTopics);
            
            // Wait for completion
            result.all().get(topicCreationTimeout, TimeUnit.MILLISECONDS);
            
            log.info("Successfully created consumer topics: {}", 
                newTopics.stream().map(NewTopic::name).toList());

        } catch (Exception e) {
            if (e.getCause() instanceof TopicExistsException) {
                log.info("Some consumer topics already exist, continuing...");
            } else {
                log.warn("Could not verify/create consumer topics: {}. Consumer will attempt to handle gracefully.", 
                    e.getMessage());
            }
        }
    }

    private NewTopic createTopicDefinition(String topicName) {
        NewTopic topic = new NewTopic(topicName, defaultPartitions, defaultReplicationFactor);
        
        // Consumer-specific topic configurations
        topic.configs(Map.of(
            "cleanup.policy", "delete",
            "retention.ms", "604800000", // 7 days
            "retention.bytes", "1073741824", // 1GB
            "compression.type", "snappy",
            "max.message.bytes", "1048576", // 1MB
            "min.insync.replicas", "1"
        ));
        
        return topic;
    }

    @Bean
    public IndependentTopicConfiguration consumerTopicConfig() {
        return new IndependentTopicConfiguration(kafkaAdmin);
    }
}
