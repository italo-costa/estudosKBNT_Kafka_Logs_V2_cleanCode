package com.estudoskbnt.kbntlogservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * KBNT Log Service - Unified Spring Boot Application
 * 
 * This service operates in multiple modes based on APP_PROCESSING_MODES environment variable:
 * - producer: Handles REST API requests and produces messages to Kafka
 * - consumer: Consumes messages from Kafka topics and processes them
 * - processor: Performs business logic processing on consumed messages
 * 
 * All modes can run simultaneously in the same JVM for optimal resource utilization.
 */
@SpringBootApplication
@EnableKafka
@EnableAsync
@EnableScheduling
public class KbntLogServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(KbntLogServiceApplication.class, args);
    }
}
