package com.kbnt.virtualstock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Virtual Stock Service - Microservice A
 * 
 * This microservice manages virtual stock operations and publishes stock update events
 * to Red Hat AMQ Streams (Kafka) using hexagonal architecture principles.
 * 
 * Architecture:
 * - Domain: Core business logic for stock management
 * - Application: Use cases and orchestration
 * - Infrastructure: Adapters for Kafka, database, REST APIs
 * 
 * Features:
 * - Hexagonal Architecture (Ports and Adapters)
 * - Stock management business domain
 * - Event-driven communication via Kafka
 * - RESTful API for stock operations
 * - Enhanced logging with component identification
 * - Performance monitoring and metrics
 * - Health checks and observability
 * 
 * @author KBNT Development Team
 * @version 2.0.0
 * @since 2025-08-30
 */
@SpringBootApplication
@EnableKafka
@EnableAsync
@EnableTransactionManagement
public class VirtualStockApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(VirtualStockApplication.class, args);
    }
}
