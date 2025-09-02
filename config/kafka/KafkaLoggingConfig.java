package com.redhat.amqstreams.config;

import org.slf4j.MDC;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.encoder.PatternLayoutEncoder;
import ch.qos.logback.core.rolling.RollingFileAppender;
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy;
import org.slf4j.LoggerFactory;

import javax.annotation.PostConstruct;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Enhanced Logging Configuration for Red Hat AMQ Streams (Kafka)
 * 
 * Provides structured logging for Kafka operations with component identification,
 * topic tracking, and performance metrics using MDC (Mapped Diagnostic Context).
 */
@Configuration
public class KafkaLoggingConfig {

    private static final String SERVICE_COMPONENT = "RED_HAT_AMQ_STREAMS";
    private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS");

    @PostConstruct
    public void configureKafkaLogging() {
        LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();
        
        // Create Kafka-specific pattern with topic and partition information
        String kafkaPattern = "%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level [%X{kafkaComponent}] [%X{topic}] [%X{partition}] [%X{offset}] %logger{36} - %msg%n";
        
        // Configure rolling file appender for Kafka-specific logging
        RollingFileAppender<ch.qos.logback.classic.spi.ILoggingEvent> kafkaAppender = 
            new RollingFileAppender<>();
        kafkaAppender.setContext(loggerContext);
        kafkaAppender.setName("KAFKA-AMQ-STREAMS-FILE");
        kafkaAppender.setFile("logs/amq-streams-kafka.log");
        
        // Configure time-based rolling policy
        TimeBasedRollingPolicy<ch.qos.logback.classic.spi.ILoggingEvent> kafkaRollingPolicy = 
            new TimeBasedRollingPolicy<>();
        kafkaRollingPolicy.setContext(loggerContext);
        kafkaRollingPolicy.setParent(kafkaAppender);
        kafkaRollingPolicy.setFileNamePattern("logs/amq-streams-kafka.%d{yyyy-MM-dd}.%i.log");
        kafkaRollingPolicy.setMaxHistory(30);
        
        // Configure pattern encoder
        PatternLayoutEncoder kafkaEncoder = new PatternLayoutEncoder();
        kafkaEncoder.setContext(loggerContext);
        kafkaEncoder.setPattern(kafkaPattern);
        kafkaEncoder.start();
        
        kafkaAppender.setEncoder(kafkaEncoder);
        kafkaAppender.setRollingPolicy(kafkaRollingPolicy);
        kafkaRollingPolicy.start();
        kafkaAppender.start();
        
        // Configure specific loggers for Kafka components
        configureKafkaComponentLoggers(loggerContext, kafkaAppender);
        
        LoggerFactory.getLogger(getClass()).info("Kafka enhanced logging configured for {}", SERVICE_COMPONENT);
    }
    
    private void configureKafkaComponentLoggers(LoggerContext loggerContext, 
                                               RollingFileAppender<ch.qos.logback.classic.spi.ILoggingEvent> appender) {
        
        // Configure logger for Kafka brokers
        Logger brokerLogger = loggerContext.getLogger("kafka.server");
        brokerLogger.addAppender(appender);
        
        // Configure logger for Kafka producers
        Logger producerLogger = loggerContext.getLogger("org.apache.kafka.clients.producer");
        producerLogger.addAppender(appender);
        
        // Configure logger for Kafka consumers
        Logger consumerLogger = loggerContext.getLogger("org.apache.kafka.clients.consumer");
        consumerLogger.addAppender(appender);
        
        // Configure logger for Kafka topics
        Logger topicLogger = loggerContext.getLogger("kafka.log");
        topicLogger.addAppender(appender);
        
        // Configure logger for Kafka coordination
        Logger coordinatorLogger = loggerContext.getLogger("kafka.coordinator");
        coordinatorLogger.addAppender(appender);
    }

    /**
     * Kafka-specific logging utility methods with MDC context management
     */
    @Component
    public static class KafkaLoggingUtils {
        
        /**
         * Set Kafka broker context information in MDC
         * 
         * @param brokerComponent Kafka broker component (BROKER, CONTROLLER, etc.)
         * @param brokerId Broker ID
         */
        public static void setBrokerContext(String brokerComponent, String brokerId) {
            MDC.put("kafkaComponent", "KAFKA_BROKER_" + brokerComponent);
            MDC.put("brokerId", brokerId);
            MDC.put("owner", SERVICE_COMPONENT);
            MDC.put("timestamp", LocalDateTime.now().format(TIMESTAMP_FORMAT));
        }
        
        /**
         * Set Kafka topic context information in MDC
         * 
         * @param topicName Topic name
         * @param partition Partition number
         * @param offset Message offset
         */
        public static void setTopicContext(String topicName, Integer partition, Long offset) {
            MDC.put("kafkaComponent", "KAFKA_TOPIC");
            MDC.put("topic", topicName);
            MDC.put("owner", SERVICE_COMPONENT);
            
            if (partition != null) {
                MDC.put("partition", String.valueOf(partition));
            }
            if (offset != null) {
                MDC.put("offset", String.valueOf(offset));
            }
            
            MDC.put("timestamp", LocalDateTime.now().format(TIMESTAMP_FORMAT));
        }
        
        /**
         * Set Kafka producer context information in MDC
         * 
         * @param producerId Producer client ID
         * @param topicName Topic name
         */
        public static void setProducerContext(String producerId, String topicName) {
            MDC.put("kafkaComponent", "KAFKA_PRODUCER");
            MDC.put("producerId", producerId);
            MDC.put("topic", topicName);
            MDC.put("owner", SERVICE_COMPONENT);
            MDC.put("timestamp", LocalDateTime.now().format(TIMESTAMP_FORMAT));
        }
        
        /**
         * Set Kafka consumer context information in MDC
         * 
         * @param consumerId Consumer client ID
         * @param groupId Consumer group ID
         * @param topicName Topic name
         */
        public static void setConsumerContext(String consumerId, String groupId, String topicName) {
            MDC.put("kafkaComponent", "KAFKA_CONSUMER");
            MDC.put("consumerId", consumerId);
            MDC.put("consumerGroup", groupId);
            MDC.put("topic", topicName);
            MDC.put("owner", SERVICE_COMPONENT);
            MDC.put("timestamp", LocalDateTime.now().format(TIMESTAMP_FORMAT));
        }
        
        /**
         * Log Kafka topic operations
         * 
         * @param operation Operation type (CREATE, DELETE, PRODUCE, CONSUME, etc.)
         * @param topicName Topic name
         * @param partition Partition (if applicable)
         * @param details Operation details
         */
        public static void logTopicOperation(String operation, String topicName, Integer partition, String details) {
            setTopicContext(topicName, partition, null);
            
            LoggerFactory.getLogger("KafkaTopicLogger").info(
                "[TOPIC_{}] {} {} - {}", operation, topicName, 
                partition != null ? "Partition: " + partition : "", details);
        }
        
        /**
         * Log Kafka broker operations
         * 
         * @param operation Broker operation (STARTUP, SHUTDOWN, LEADER_CHANGE, etc.)
         * @param brokerId Broker ID
         * @param details Operation details
         */
        public static void logBrokerOperation(String operation, String brokerId, String details) {
            setBrokerContext(operation, brokerId);
            
            LoggerFactory.getLogger("KafkaBrokerLogger").info(
                "[BROKER_{}] Broker {} - {}", operation, brokerId, details);
        }
        
        /**
         * Log Kafka message flow operations
         * 
         * @param flowType Flow type (PRODUCE, CONSUME, REPLICATION, etc.)
         * @param topicName Topic name
         * @param partition Partition number
         * @param offset Message offset
         * @param messageCount Number of messages
         * @param durationMs Operation duration
         */
        public static void logMessageFlow(String flowType, String topicName, Integer partition, 
                                         Long offset, Integer messageCount, Long durationMs) {
            setTopicContext(topicName, partition, offset);
            MDC.put("messageCount", String.valueOf(messageCount));
            MDC.put("duration", String.valueOf(durationMs));
            
            String throughput = messageCount != null && durationMs != null && durationMs > 0 
                ? String.format("%.2f msg/s", (messageCount * 1000.0) / durationMs) : "N/A";
            
            LoggerFactory.getLogger("KafkaFlowLogger").info(
                "[FLOW_{}] {} Partition:{} Offset:{} - {} messages in {}ms ({} throughput)", 
                flowType, topicName, partition, offset, messageCount, durationMs, throughput);
        }
        
        /**
         * Log Kafka replication operations
         * 
         * @param replicationOp Replication operation (SYNC, FETCH, LAG_CHECK, etc.)
         * @param topicName Topic name
         * @param partition Partition number
         * @param leaderBroker Leader broker ID
         * @param replicaBrokers Replica broker IDs
         * @param details Replication details
         */
        public static void logReplicationOperation(String replicationOp, String topicName, 
                                                  Integer partition, String leaderBroker, 
                                                  String replicaBrokers, String details) {
            setTopicContext(topicName, partition, null);
            MDC.put("leader", leaderBroker);
            MDC.put("replicas", replicaBrokers);
            
            LoggerFactory.getLogger("KafkaReplicationLogger").info(
                "[REPLICATION_{}] {} Partition:{} Leader:{} Replicas:[{}] - {}", 
                replicationOp, topicName, partition, leaderBroker, replicaBrokers, details);
        }
        
        /**
         * Log Kafka performance metrics
         * 
         * @param metricType Metric type (THROUGHPUT, LATENCY, DISK_IO, etc.)
         * @param topicName Topic name (if applicable)
         * @param value Metric value
         * @param unit Metric unit
         * @param details Additional metric details
         */
        public static void logPerformanceMetrics(String metricType, String topicName, 
                                               Double value, String unit, String details) {
            MDC.put("kafkaComponent", "KAFKA_METRICS");
            MDC.put("metricType", metricType);
            if (topicName != null) {
                MDC.put("topic", topicName);
            }
            MDC.put("metricValue", String.valueOf(value));
            MDC.put("metricUnit", unit);
            
            LoggerFactory.getLogger("KafkaMetricsLogger").info(
                "[METRICS_{}] {} {} {} - {}", 
                metricType, topicName != null ? topicName + ":" : "CLUSTER", 
                value, unit, details);
        }
        
        /**
         * Log Kafka cluster operations
         * 
         * @param clusterOp Cluster operation (LEADER_ELECTION, PARTITION_REASSIGNMENT, etc.)
         * @param affectedTopics Affected topics
         * @param details Operation details
         */
        public static void logClusterOperation(String clusterOp, String affectedTopics, String details) {
            MDC.put("kafkaComponent", "KAFKA_CLUSTER");
            MDC.put("clusterOperation", clusterOp);
            MDC.put("affectedTopics", affectedTopics);
            MDC.put("owner", SERVICE_COMPONENT);
            
            LoggerFactory.getLogger("KafkaClusterLogger").info(
                "[CLUSTER_{}] Topics:[{}] - {}", clusterOp, affectedTopics, details);
        }
        
        /**
         * Log Kafka errors with context
         * 
         * @param errorType Type of Kafka error
         * @param topicName Topic name (if applicable)
         * @param partition Partition (if applicable)
         * @param errorMessage Error message
         * @param exception Exception (if any)
         */
        public static void logKafkaError(String errorType, String topicName, Integer partition, 
                                        String errorMessage, Throwable exception) {
            MDC.put("kafkaComponent", "KAFKA_ERROR");
            MDC.put("errorType", errorType);
            
            if (topicName != null) {
                MDC.put("topic", topicName);
            }
            if (partition != null) {
                MDC.put("partition", String.valueOf(partition));
            }
            
            if (exception != null) {
                LoggerFactory.getLogger("KafkaErrorLogger").error(
                    "[KAFKA_ERROR:{}] {} {} - {}", errorType, 
                    topicName != null ? topicName : "UNKNOWN_TOPIC",
                    partition != null ? "Partition: " + partition : "", 
                    errorMessage, exception);
            } else {
                LoggerFactory.getLogger("KafkaErrorLogger").error(
                    "[KAFKA_ERROR:{}] {} {} - {}", errorType, 
                    topicName != null ? topicName : "UNKNOWN_TOPIC",
                    partition != null ? "Partition: " + partition : "", 
                    errorMessage);
            }
        }
        
        /**
         * Clear all Kafka MDC context
         */
        public static void clearContext() {
            MDC.clear();
        }
        
        /**
         * Clear specific Kafka MDC key
         * 
         * @param key Key to remove from MDC
         */
        public static void clearContext(String key) {
            MDC.remove(key);
        }
    }
}
