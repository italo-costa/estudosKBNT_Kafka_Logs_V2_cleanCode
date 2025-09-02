package com.estudoskbnt.logconsumer.infrastructure.kafka;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Independent Topic Configuration for Consumer Service
 * Handles automatic topic creation with graceful fallbacks
 */
@Slf4j
@Component
public class IndependentTopicConfiguration {

    private final KafkaAdmin kafkaAdmin;
    
    @Value("${app.kafka.topics.partitions:3}")
    private int defaultPartitions;
    
    @Value("${app.kafka.topics.replication-factor:1}")
    private short defaultReplicationFactor;
    
    @Value("${app.independence.topic-creation-timeout:30000}")
    private long topicCreationTimeout;

    public IndependentTopicConfiguration(KafkaAdmin kafkaAdmin) {
        this.kafkaAdmin = kafkaAdmin;
    }

    /**
     * Creates topics if they don't exist
     * Returns CompletableFuture for async handling
     */
    public CompletableFuture<Boolean> ensureTopicsExist(String... topicNames) {
        return CompletableFuture.supplyAsync(() -> {
            try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
                
                List<String> topicList = Arrays.asList(topicNames);
                
                // Check existing topics
                var existingTopics = adminClient.listTopics().names()
                    .get(topicCreationTimeout, TimeUnit.MILLISECONDS);

                var topicsToCreate = topicList.stream()
                    .filter(topicName -> !existingTopics.contains(topicName))
                    .map(this::createTopicDefinition)
                    .toList();

                if (topicsToCreate.isEmpty()) {
                    log.debug("All requested topics already exist: {}", topicList);
                    return true;
                }

                log.info("Creating {} missing topics: {}", 
                    topicsToCreate.size(), 
                    topicsToCreate.stream().map(NewTopic::name).toList());

                CreateTopicsResult result = adminClient.createTopics(topicsToCreate);
                result.all().get(topicCreationTimeout, TimeUnit.MILLISECONDS);
                
                log.info("Successfully created topics: {}", 
                    topicsToCreate.stream().map(NewTopic::name).toList());
                
                return true;
                
            } catch (Exception e) {
                if (e.getCause() instanceof TopicExistsException) {
                    log.debug("Topics already exist, continuing...");
                    return true;
                } else {
                    log.warn("Could not create topics {}: {}. Service will attempt to continue.", 
                        Arrays.toString(topicNames), e.getMessage());
                    return false;
                }
            }
        });
    }

    /**
     * Checks if topics exist without creating them
     */
    public CompletableFuture<Boolean> checkTopicsExist(String... topicNames) {
        return CompletableFuture.supplyAsync(() -> {
            try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
                
                var existingTopics = adminClient.listTopics().names()
                    .get(topicCreationTimeout, TimeUnit.MILLISECONDS);
                
                List<String> topicList = Arrays.asList(topicNames);
                boolean allExist = topicList.stream()
                    .allMatch(existingTopics::contains);
                
                log.debug("Topic existence check for {}: {}", topicList, allExist);
                return allExist;
                
            } catch (Exception e) {
                log.warn("Could not check topic existence for {}: {}", 
                    Arrays.toString(topicNames), e.getMessage());
                return false;
            }
        });
    }

    private NewTopic createTopicDefinition(String topicName) {
        NewTopic topic = new NewTopic(topicName, defaultPartitions, defaultReplicationFactor);
        
        // Consumer-optimized configurations
        topic.configs(Map.of(
            "cleanup.policy", "delete",
            "retention.ms", "604800000", // 7 days
            "retention.bytes", "1073741824", // 1GB
            "compression.type", "snappy",
            "max.message.bytes", "1048576", // 1MB
            "min.insync.replicas", "1",
            "unclean.leader.election.enable", "false"
        ));
        
        return topic;
    }
}
