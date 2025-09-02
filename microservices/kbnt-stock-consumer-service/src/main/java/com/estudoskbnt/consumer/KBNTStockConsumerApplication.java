package com.estudoskbnt.consumer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * ACL Virtual Stock Service - Microservice B
 * 
 * Anti-Corruption Layer (ACL) for Virtual Stock integration.
 * This microservice consumes stock update events from Red Hat AMQ Streams (Kafka)
 * published by Virtual Stock Service and integrates with external stock management systems.
 * 
 * Purpose:
 * - Acts as an Anti-Corruption Layer between Virtual Stock domain and external systems
 * - Translates Virtual Stock events to external system formats
 * - Provides data consistency and audit logging for stock operations
 * - Protects external systems from Virtual Stock domain model changes
 * 
 * Features:
 * - Kafka message consumption with @KafkaListener
 * - External API integration for stock processing
 * - Consumption audit logging with database persistence
 * - Anti-corruption pattern implementation
 * - Async processing support
 * - Transaction management
 * - Health checks and monitoring
 * - Enhanced logging with component identification
 * 
 * @author KBNT Development Team
 * @version 2.0.0
 * @since 2025-08-30
 */
@SpringBootApplication
@EnableKafka
@EnableAsync
@EnableTransactionManagement
public class KBNTStockConsumerApplication {
	public static void main(String[] args) {
		SpringApplication.run(KBNTStockConsumerApplication.class, args);
	}
}
