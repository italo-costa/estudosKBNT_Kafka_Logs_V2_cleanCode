package com.estudoskbnt.kbntlogservice.config;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.errors.TopicExistsException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaAdmin;

import jakarta.annotation.PostConstruct;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * AMQ Streams Topic Configuration for KBNT Log Service
 * Automatically creates required topics if they don't exist
 */
@Slf4j
@Configuration
public class AmqStreamsTopicConfiguration {

    private final KafkaAdmin kafkaAdmin;
    
    @Value("${app.kafka.topics.application-logs:kbnt-application-logs}")
    private String applicationLogsTopic;
    
    @Value("${app.kafka.topics.error-logs:kbnt-error-logs}")
    private String errorLogsTopic;
    
    @Value("${app.kafka.topics.audit-logs:kbnt-audit-logs}")
    private String auditLogsTopic;
    
    @Value("${app.kafka.topics.financial-logs:kbnt-financial-logs}")
    private String financialLogsTopic;
    
    @Value("${app.kafka.topics.dead-letter-queue:kbnt-dead-letter-queue}")
    private String deadLetterQueueTopic;
    
    @Value("${app.kafka.topics.replication-factor:3}")
    private short replicationFactor;
    
    @Value("${app.kafka.topics.timeout:30000}")
    private long topicOperationTimeout;

    public AmqStreamsTopicConfiguration(KafkaAdmin kafkaAdmin) {
        this.kafkaAdmin = kafkaAdmin;
    }

    @PostConstruct
    public void initializeAmqStreamsTopics() {
        log.info("🔧 Initializing AMQ Streams topics configuration...");
        
        CompletableFuture.runAsync(() -> {
            try {
                createRequiredTopicsIfNotExist();
                log.info("✅ AMQ Streams topic initialization completed successfully");
            } catch (Exception e) {
                log.error("❌ Failed to initialize AMQ Streams topics: {}", e.getMessage());
                log.warn("⚠️ Service will continue startup - topics may be created by Strimzi operator");
            }
        });
    }

    private void createRequiredTopicsIfNotExist() {
        try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
            
            List<NewTopic> topicsToCreate = Arrays.asList(
                createApplicationLogsTopic(),
                createErrorLogsTopic(),
                createAuditLogsTopic(),
                createFinancialLogsTopic(),
                createDeadLetterQueueTopic()
            );

            // Check existing topics first
            var existingTopics = adminClient.listTopics().names()
                .get(topicOperationTimeout, TimeUnit.MILLISECONDS);

            var newTopics = topicsToCreate.stream()
                .filter(topic -> !existingTopics.contains(topic.name()))
                .toList();

            if (newTopics.isEmpty()) {
                log.info("✅ All required AMQ Streams topics already exist");
                logExistingTopics(existingTopics);
                return;
            }

            log.info("📋 Creating {} missing AMQ Streams topics: {}", 
                newTopics.size(), 
                newTopics.stream().map(NewTopic::name).toList());

            CreateTopicsResult result = adminClient.createTopics(newTopics);
            
            // Wait for completion
            result.all().get(topicOperationTimeout, TimeUnit.MILLISECONDS);
            
            log.info("✅ Successfully created AMQ Streams topics: {}", 
                newTopics.stream().map(NewTopic::name).toList());

        } catch (Exception e) {
            if (e.getCause() instanceof TopicExistsException) {
                log.info("✅ AMQ Streams topics already exist, continuing...");
            } else {
                log.warn("⚠️ Could not verify/create AMQ Streams topics: {}. " +
                        "This is normal in managed environments where topics are created by operators.", 
                    e.getMessage());
            }
        }
    }

    private NewTopic createApplicationLogsTopic() {
        NewTopic topic = new NewTopic(applicationLogsTopic, 6, replicationFactor);
        topic.configs(Map.of(
            "cleanup.policy", "delete",
            "retention.ms", "604800000", // 7 days
            "retention.bytes", "2147483648", // 2GB per partition
            "compression.type", "snappy",
            "segment.ms", "3600000", // 1 hour
            "max.message.bytes", "1048576", // 1MB
            "min.insync.replicas", "2",
            "unclean.leader.election.enable", "false"
        ));
        return topic;
    }

    private NewTopic createErrorLogsTopic() {
        NewTopic topic = new NewTopic(errorLogsTopic, 4, replicationFactor);
        topic.configs(Map.of(
            "cleanup.policy", "delete",
            "retention.ms", "2592000000", // 30 days
            "retention.bytes", "5368709120", // 5GB per partition
            "compression.type", "lz4",
            "segment.ms", "1800000", // 30 minutes
            "max.message.bytes", "2097152", // 2MB
            "min.insync.replicas", "2",
            "unclean.leader.election.enable", "false"
        ));
        return topic;
    }

    private NewTopic createAuditLogsTopic() {
        NewTopic topic = new NewTopic(auditLogsTopic, 3, replicationFactor);
        topic.configs(Map.of(
            "cleanup.policy", "delete",
            "retention.ms", "7776000000", // 90 days
            "retention.bytes", "10737418240", // 10GB per partition
            "compression.type", "gzip",
            "segment.ms", "7200000", // 2 hours
            "max.message.bytes", "1048576", // 1MB
            "min.insync.replicas", "2",
            "unclean.leader.election.enable", "false"
        ));
        return topic;
    }

    private NewTopic createFinancialLogsTopic() {
        NewTopic topic = new NewTopic(financialLogsTopic, 8, replicationFactor);
        topic.configs(Map.of(
            "cleanup.policy", "delete", 
            "retention.ms", "31536000000", // 365 days
            "retention.bytes", "21474836480", // 20GB per partition
            "compression.type", "lz4",
            "segment.ms", "10800000", // 3 hours
            "max.message.bytes", "1048576", // 1MB
            "min.insync.replicas", "3", // Higher consistency for financial data
            "unclean.leader.election.enable", "false"
        ));
        return topic;
    }

    private NewTopic createDeadLetterQueueTopic() {
        NewTopic topic = new NewTopic(deadLetterQueueTopic, 2, replicationFactor);
        topic.configs(Map.of(
            "cleanup.policy", "delete",
            "retention.ms", "604800000", // 7 days
            "retention.bytes", "1073741824", // 1GB per partition
            "compression.type", "snappy",
            "segment.ms", "3600000", // 1 hour
            "max.message.bytes", "2097152", // 2MB
            "min.insync.replicas", "2",
            "unclean.leader.election.enable", "false"
        ));
        return topic;
    }

    private void logExistingTopics(java.util.Set<String> existingTopics) {
        log.info("📋 Existing topics in AMQ Streams cluster:");
        existingTopics.stream()
            .filter(topic -> topic.startsWith("kbnt-"))
            .forEach(topic -> log.info("  ✅ {}", topic));
    }
}
