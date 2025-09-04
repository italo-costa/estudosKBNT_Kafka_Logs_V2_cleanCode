package com.estudoskbnt.kbntlogservice.config;

import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import jakarta.annotation.PostConstruct;
import java.util.Arrays;
import java.util.List;

/**
 * Processing Mode Configuration
 * Controls which components are active based on APP_PROCESSING_MODES environment variable
 */
@Configuration
public class ProcessingModeConfiguration {

  private static final Logger log = LoggerFactory.getLogger(ProcessingModeConfiguration.class);

  private final Environment environment;    @Value("${app.processing.modes:producer,consumer,processor}")
    private String processingModes;

    public ProcessingModeConfiguration(Environment environment) {
        this.environment = environment;
    }

    @PostConstruct
    public void logActiveProfiles() {
        List<String> modes = Arrays.asList(processingModes.split(","));
        
        log.info("=".repeat(60));
        log.info("KBNT LOG SERVICE - PROCESSING MODES CONFIGURATION");
        log.info("=".repeat(60));
        log.info("🚀 Service Name: {}", environment.getProperty("spring.application.name"));
        log.info("📋 Active Spring Profiles: {}", Arrays.toString(environment.getActiveProfiles()));
        log.info("🔧 Processing Modes: {}", modes);
        log.info("📡 Kafka Bootstrap Servers: {}", environment.getProperty("spring.kafka.bootstrap-servers"));
        log.info("🏷️  Kafka Consumer Group: {}", environment.getProperty("spring.kafka.consumer.group-id"));
        
        // Log mode-specific configurations
        if (modes.contains("producer")) {
            log.info("✅ PRODUCER MODE: REST API endpoints enabled");
            log.info("   📤 Will produce messages to Kafka topics");
        }
        
        if (modes.contains("consumer")) {
            log.info("✅ CONSUMER MODE: Kafka message consumption enabled");
            log.info("   📥 Will consume from configured topics");
        }
        
        if (modes.contains("processor")) {
            log.info("✅ PROCESSOR MODE: Business logic processing enabled");
            log.info("   ⚙️  Will process consumed messages");
        }
        
        log.info("=".repeat(60));
    }

    public boolean isProducerModeEnabled() {
        return Arrays.asList(processingModes.split(",")).contains("producer");
    }

    public boolean isConsumerModeEnabled() {
        return Arrays.asList(processingModes.split(",")).contains("consumer");
    }

    public boolean isProcessorModeEnabled() {
        return Arrays.asList(processingModes.split(",")).contains("processor");
    }
}

/**
 * Producer Mode Configuration
 * Only active when 'producer' is in APP_PROCESSING_MODES
 */
@Configuration
@ConditionalOnProperty(
    value = "app.processing.modes", 
    havingValue = "producer", 
    matchIfMissing = false
)
@Slf4j
class ProducerModeConfiguration {
    
    @PostConstruct
    public void init() {
        log.info("🔧 Producer mode configuration loaded");
    }
}

/**
 * Consumer Mode Configuration  
 * Only active when 'consumer' is in APP_PROCESSING_MODES
 */
@Configuration
@ConditionalOnProperty(
    value = "app.processing.modes",
    havingValue = "consumer", 
    matchIfMissing = false
)
@Slf4j
class ConsumerModeConfiguration {
    
    @PostConstruct
    public void init() {
        log.info("🔧 Consumer mode configuration loaded");
    }
}

/**
 * Processor Mode Configuration
 * Only active when 'processor' is in APP_PROCESSING_MODES
 */
@Configuration
@ConditionalOnProperty(
    value = "app.processing.modes",
    havingValue = "processor",
    matchIfMissing = false
)
@Slf4j 
class ProcessorModeConfiguration {
    
    @PostConstruct
    public void init() {
        log.info("🔧 Processor mode configuration loaded");
    }
}
