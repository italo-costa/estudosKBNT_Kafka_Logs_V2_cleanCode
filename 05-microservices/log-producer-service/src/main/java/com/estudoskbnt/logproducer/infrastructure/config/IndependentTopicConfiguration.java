package com.estudoskbnt.logproducer.infrastructure.config;

import java.time.Duration;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.ListTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;

public class IndependentTopicConfiguration implements ApplicationRunner {

    private final KafkaAdmin kafkaAdmin;
    
    @Value("${app.kafka.topics.application-logs:application-logs}")
    private String applicationLogsTopic;
    
    @Value("${app.kafka.topics.error-logs:error-logs}")
    private String errorLogsTopic;
    
    @Value("${app.kafka.topics.audit-logs:audit-logs}")
    private String auditLogsTopic;
    
    @Value("${app.kafka.topics.financial-logs:financial-logs}")
    private String financialLogsTopic;
    
    @Value("${app.independence.startup-check-timeout:30000}")
    private long startupCheckTimeout;

    public IndependentTopicConfiguration(KafkaAdmin kafkaAdmin) {
        this.kafkaAdmin = kafkaAdmin;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        log.info("Starting independent topic configuration...");
        
        try {
            createTopicsIfNotExist();
            log.info("Independent topic configuration completed successfully");
        } catch (Exception e) {
            log.error("Failed to configure topics independently", e);
            throw e;
        }
    }

    private void createTopicsIfNotExist() {
        try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
            
            // Check existing topics
            ListTopicsResult listTopics = adminClient.listTopics();
            Set<String> existingTopics = listTopics.names()
                .get(startupCheckTimeout, TimeUnit.MILLISECONDS);
            
            log.info("Existing topics: {}", existingTopics);

            // Define topics to create
            List<NewTopic> topicsToCreate = Arrays.asList(
                createNewTopic(applicationLogsTopic, 3, (short) 1, existingTopics),
                createNewTopic(errorLogsTopic, 3, (short) 1, existingTopics),
                createNewTopic(auditLogsTopic, 2, (short) 1, existingTopics),
                createNewTopic(financialLogsTopic, 3, (short) 1, existingTopics)
            ).stream()
            .filter(topic -> topic != null)
            .toList();

            if (!topicsToCreate.isEmpty()) {
                log.info("Creating topics: {}", 
                    topicsToCreate.stream().map(NewTopic::name).toList());
                
                CreateTopicsResult result = adminClient.createTopics(topicsToCreate);
                
                // Wait for all topics to be created
                CompletableFuture.allOf(
                    result.values().values().toArray(new CompletableFuture[0])
                ).get(startupCheckTimeout, TimeUnit.MILLISECONDS);
                
                log.info("Successfully created {} topics", topicsToCreate.size());
            } else {
                log.info("All required topics already exist");
            }
            
        } catch (Exception e) {
            log.error("Failed to create topics", e);
            throw new RuntimeException("Topic creation failed", e);
        }
    }

    private NewTopic createNewTopic(String topicName, int partitions, short replicationFactor, Set<String> existingTopics) {
        if (existingTopics.contains(topicName)) {
            log.debug("Topic {} already exists, skipping creation", topicName);
            return null;
        }
        
        log.info("Preparing to create topic: {} with {} partitions", topicName, partitions);
        return new NewTopic(topicName, partitions, replicationFactor);
    }
}
