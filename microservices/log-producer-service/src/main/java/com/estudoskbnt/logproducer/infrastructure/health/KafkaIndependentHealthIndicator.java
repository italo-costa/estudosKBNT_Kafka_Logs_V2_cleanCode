package com.estudoskbnt.logproducer.infrastructure.health;

import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.DescribeTopicsResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import java.util.Set;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Independent Kafka Health Indicator
 * Checks Kafka connectivity and topic availability with graceful degradation
 */
@Slf4j
@Component("kafkaIndependentHealthIndicator")
public class KafkaIndependentHealthIndicator implements HealthIndicator {

    private final KafkaAdmin kafkaAdmin;
    
    @Value("${app.kafka.topics.application-logs:application-logs}")
    private String applicationLogsTopic;
    
    @Value("${app.kafka.topics.error-logs:error-logs}")
    private String errorLogsTopic;
    
    @Value("${app.kafka.topics.audit-logs:audit-logs}")
    private String auditLogsTopic;
    
    @Value("${app.kafka.topics.financial-logs:financial-logs}")
    private String financialLogsTopic;
    
    @Value("${app.independence.require-all-topics:false}")
    private boolean requireAllTopics;
    
    @Value("${app.independence.degraded-mode-enabled:true}")
    private boolean degradedModeEnabled;
    
    private static final Duration HEALTH_CHECK_TIMEOUT = Duration.ofSeconds(5);

    public KafkaIndependentHealthIndicator(KafkaAdmin kafkaAdmin) {
        this.kafkaAdmin = kafkaAdmin;
    }

    @Override
    public Health health() {
        try {
            return checkKafkaHealth();
        } catch (Exception e) {
            log.warn("Kafka health check failed", e);
            
            return Health.down()
                .withDetail("status", degradedModeEnabled ? "degraded" : "down")
                .withDetail("reason", degradedModeEnabled ? "Kafka connectivity issues" : "Kafka unavailable")
                .withDetail("error", e.getMessage())
                .withDetail("degraded-mode", degradedModeEnabled ? "enabled" : "disabled")
                .build();
        }
    }

    private Health checkKafkaHealth() {
        try (AdminClient adminClient = AdminClient.create(kafkaAdmin.getConfigurationProperties())) {
            
            // Check basic connectivity
            var clusterInfo = adminClient.describeCluster();
            var nodeCount = clusterInfo.nodes().get(5, TimeUnit.SECONDS).size();
            
            // Check topic availability
            List<String> requiredTopics = Arrays.asList(
                applicationLogsTopic, errorLogsTopic, auditLogsTopic, financialLogsTopic
            );
            
            DescribeTopicsResult topicsResult = adminClient.describeTopics(requiredTopics);
            Map<String, org.apache.kafka.clients.admin.TopicDescription> topicDescriptions = 
                topicsResult.allTopicNames().get(5, TimeUnit.SECONDS);
            
            int availableTopics = topicDescriptions.size();
            int totalTopics = requiredTopics.size();
            
            // Determine health status
            if (availableTopics == totalTopics) {
                return Health.up()
                    .withDetail("status", "healthy")
                    .withDetail("kafka-nodes", nodeCount)
                    .withDetail("topics-available", availableTopics)
                    .withDetail("topics-total", totalTopics)
                    .withDetail("topics", topicDescriptions.keySet())
                    .build();
            } else if (availableTopics > 0 && degradedModeEnabled) {
                return Health.down()
                    .withDetail("status", "degraded")
                    .withDetail("kafka-nodes", nodeCount)
                    .withDetail("topics-available", availableTopics)
                    .withDetail("topics-total", totalTopics)
                    .withDetail("available-topics", topicDescriptions.keySet())
                    .withDetail("missing-topics", getMissingTopics(requiredTopics, topicDescriptions.keySet()))
                    .withDetail("degraded-mode", "partial topic availability")
                    .build();
            } else if (requireAllTopics) {
                return Health.down()
                    .withDetail("status", "down")
                    .withDetail("reason", "Required topics missing")
                    .withDetail("topics-available", availableTopics)
                    .withDetail("topics-required", totalTopics)
                    .withDetail("missing-topics", getMissingTopics(requiredTopics, topicDescriptions.keySet()))
                    .build();
            } else {
                return Health.up()
                    .withDetail("status", "healthy")
                    .withDetail("kafka-nodes", nodeCount)
                    .withDetail("topics-available", availableTopics)
                    .withDetail("topics-total", totalTopics)
                    .withDetail("note", "Running with partial topic availability")
                    .build();
            }
            
        } catch (Exception e) {
            throw new RuntimeException("Kafka health check failed", e);
        }
    }
    
    private List<String> getMissingTopics(List<String> required, Set<String> available) {
        return required.stream()
            .filter(topic -> !available.contains(topic))
            .toList();
    }
}
