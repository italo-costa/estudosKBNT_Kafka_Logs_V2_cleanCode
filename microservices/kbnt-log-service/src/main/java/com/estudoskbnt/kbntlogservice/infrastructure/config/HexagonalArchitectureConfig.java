package com.estudoskbnt.kbntlogservice.infrastructure.config;

import com.estudoskbnt.kbntlogservice.application.service.StockUpdateApplicationService;
import com.estudoskbnt.kbntlogservice.domain.port.input.StockUpdateUseCase;
import com.estudoskbnt.kbntlogservice.domain.port.output.EventPublisherPort;
import com.estudoskbnt.kbntlogservice.domain.port.output.StockUpdateRepositoryPort;
import com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.kafka.KafkaEventPublisherAdapter;
import com.estudoskbnt.kbntlogservice.infrastructure.adapter.output.persistence.InMemoryStockUpdateRepositoryAdapter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Hexagonal Architecture Configuration
 * 
 * Spring configuration that wires together the hexagonal architecture components:
 * - Domain Layer (business logic)
 * - Application Layer (use cases)
 * - Infrastructure Layer (adapters)
 * 
 * This configuration follows the Dependency Inversion Principle where:
 * - High-level modules (domain) don't depend on low-level modules (infrastructure)
 * - Both depend on abstractions (ports)
 */
@Slf4j
@Configuration
public class HexagonalArchitectureConfig {

    /**
     * Creates the main use case implementation (Application Layer)
     * 
     * This bean implements the StockUpdateUseCase port and coordinates
     * between the domain logic and infrastructure adapters.
     */
    @Bean
    public StockUpdateUseCase stockUpdateUseCase(
            StockUpdateRepositoryPort repositoryPort,
            EventPublisherPort eventPublisherPort) {
        
        log.info("🔧 Configuring Stock Update Use Case with hexagonal architecture");
        
        return new StockUpdateApplicationService(repositoryPort, eventPublisherPort);
    }

    /**
     * Creates the repository adapter (Infrastructure Layer)
     * 
     * This bean implements the StockUpdateRepositoryPort and provides
     * persistence capabilities for stock updates.
     */
    @Bean
    public StockUpdateRepositoryPort stockUpdateRepositoryPort() {
        log.info("🔧 Configuring Stock Update Repository (In-Memory Implementation)");
        return new InMemoryStockUpdateRepositoryAdapter();
    }

    /**
     * Creates the event publisher adapter (Infrastructure Layer)
     * 
     * This bean implements the EventPublisherPort and provides
     * event publishing capabilities via Kafka.
     */
    @Bean
    public EventPublisherPort eventPublisherPort(KafkaEventPublisherAdapter kafkaAdapter) {
        log.info("🔧 Configuring Event Publisher (Kafka Implementation)");
        return kafkaAdapter;
    }
}
